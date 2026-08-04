#!/usr/bin/env bash
# Gate de deriva: ¿describe el repositorio el mismo esquema que producción?
#
# Por qué existe. `supabase db diff --linked` **no sirve como gate**: en la
# jornada del 1 ago 2026 devolvió «No schema changes found» mientras producción
# tenía tres tablas (`doctor_paciente`, `auditoria_log`, `items_receta`), cuatro
# vistas, diez triggers y catorce policies que la base local no tenía. El motor
# `pg-delta` cachea catálogos por hash de migraciones y, cuando el hash coincide
# a ambos lados, da la comparación por buena sin mirar la estructura. Un falso
# negativo en un gate de seguridad es peor que no tener gate.
#
# Qué hace en su lugar. Vuelca el esquema de las dos bases con la misma
# herramienta (`supabase db dump`), parte cada volcado en sentencias, las
# normaliza (espacios, comillas de identificador, comentarios de línea) y
# compara los dos conjuntos. Lo que aparece sólo en un lado es deriva real.
#
#   tool/produccion/deriva_esquema.sh            # informe legible
#   tool/produccion/deriva_esquema.sh --breve    # sólo el recuento
#
# Sale con 0 si no hay deriva y con 1 si la hay.

set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

BREVE=0
[[ "${1:-}" == '--breve' ]] && BREVE=1

SALIDA="$(mktemp -d)"
trap 'rm -rf "$SALIDA"' EXIT

paso() { printf '\n\033[1m▶ %s\033[0m\n' "$1"; }

paso 'Volcando el esquema local'
supabase db dump --local -f "$SALIDA/local.sql" >/dev/null 2>&1 || {
  echo "✗ No se pudo volcar la base local. ¿Está levantado el stack (supabase start)?"
  exit 2
}

paso 'Volcando el esquema de producción'
supabase db dump --linked -f "$SALIDA/remoto.sql" >/dev/null 2>&1 || {
  echo "✗ No se pudo volcar la instancia remota. ¿Está enlazado el proyecto (supabase link)?"
  exit 2
}

paso 'Comparando'
BREVE="$BREVE" python3 - "$SALIDA/local.sql" "$SALIDA/remoto.sql" <<'PY'
import os, re, sys

# Objetos que gestiona la plataforma, no el repositorio: aparecen o no según
# cómo se haya inicializado cada instancia y no describen el esquema de la
# aplicación.
IGNORAR = re.compile(
    r'^CREATE EXTENSION IF NOT EXISTS (pg_graphql|pg_net|pg_stat_statements|pgcrypto|supabase_vault|uuid-ossp)\b'
)


def partir(texto):
    """Parte en sentencias respetando el entrecomillado por dólar.

    Un cuerpo `plpgsql` está lleno de `;` y de saltos de línea: partir por
    `;\\n` a secas trocea las funciones y convierte cada `ELSIF` en una
    «sentencia» fantasma que aparece como deriva.
    """
    fuera = []
    actual = []
    etiqueta = None
    i = 0
    while i < len(texto):
        if etiqueta is None:
            m = re.match(r'\$[A-Za-z_0-9]*\$', texto[i:])
            if m:
                etiqueta = m.group(0)
                actual.append(etiqueta)
                i += len(etiqueta)
                continue
            if texto[i] == ';':
                fuera.append(''.join(actual))
                actual = []
                i += 1
                continue
        else:
            if texto.startswith(etiqueta, i):
                actual.append(etiqueta)
                i += len(etiqueta)
                etiqueta = None
                continue
        actual.append(texto[i])
        i += 1
    fuera.append(''.join(actual))
    return fuera


def sentencias(ruta):
    texto = open(ruta, encoding='utf-8').read()
    resultado = {}
    for bruto in partir(texto):
        # Los comentarios `--` se quitan por sentencia, no de golpe: dentro de
        # un cuerpo `$$` también son ruido de redacción, no estructura.
        s = re.sub(r'--[^\n]*', '', bruto).strip()
        if not s:
            continue
        # Ajustes de sesión y de propietario: ruido, no estructura.
        if re.match(r'^(SET|SELECT pg_catalog\.set_config|ALTER \w+ .* OWNER TO)', s):
            continue
        clave = re.sub(r'"', '', s)
        clave = re.sub(r'\s+', ' ', clave).strip()
        if IGNORAR.match(clave):
            continue
        clave = normalizar_tabla(clave)
        resultado.setdefault(clave, s)
    return resultado


def normalizar_tabla(clave):
    """Ordena las columnas de un CREATE TABLE antes de comparar.

    El orden físico de las columnas depende de en qué momento se añadió cada
    una y no tiene efecto semántico: ni PostgREST ni el cliente Dart las
    direccionan por posición. Producción y el repositorio añadieron las mismas
    columnas en distinto momento, así que compararlas como texto ordenado
    marcaría deriva donde no la hay.
    """
    m = re.match(r'^(CREATE TABLE IF NOT EXISTS \S+) \((.*)\)$', clave)
    if not m:
        return clave
    partes = sorted(p.strip() for p in m.group(2).split(','))
    return f'{m.group(1)} ({", ".join(partes)})'

local = sentencias(sys.argv[1])
remoto = sentencias(sys.argv[2])

solo_remoto = sorted(set(remoto) - set(local))
solo_local = sorted(set(local) - set(remoto))

def resumen(s):
    return (s[:160] + '…') if len(s) > 160 else s

breve = os.environ.get('BREVE') == '1'
if not breve:
    if solo_remoto:
        print('\n\033[33mSólo en PRODUCCIÓN (el repositorio no lo describe):\033[0m')
        for s in solo_remoto:
            print('  +', resumen(s))
    if solo_local:
        print('\n\033[33mSólo en LOCAL (producción no lo tiene):\033[0m')
        for s in solo_local:
            print('  -', resumen(s))

total = len(solo_remoto) + len(solo_local)
if total == 0:
    print('\n\033[32m✓ Sin deriva: local y producción describen el mismo esquema.\033[0m')
    sys.exit(0)

print(f'\n\033[31m✗ Deriva: {len(solo_remoto)} sentencia(s) sólo en producción, '
      f'{len(solo_local)} sólo en local.\033[0m')
sys.exit(1)
PY
