#!/usr/bin/env bash
# Mide el arranque de la app en un dispositivo real y lo compara con el
# presupuesto documentado en PERFORMANCE.md.
#
# SD-132. A diferencia de `medir_artefactos.sh`, esto necesita un dispositivo
# conectado: el arranque depende del hardware, y medirlo en el portátil del
# desarrollador no dice nada sobre el teléfono de la recepción.
#
# Uso:
#   tool/perf/medir_arranque.sh                    # primer dispositivo
#   tool/perf/medir_arranque.sh <id-dispositivo>   # ver `flutter devices`
#
# Qué hace:
#   `--trace-startup` deja en build/start_up_info.json las marcas que pone el
#   motor. La que importa es `timeToFirstFrameRasterizedMicros`: el instante en
#   que el usuario ve algo dibujado, no cuando el proceso arrancó.
#
# Importante: se mide en `--profile`, nunca en debug. Un build de debug corre
# el código Dart interpretado y es entre 3 y 10 veces más lento; medir ahí solo
# produce números alarmantes y falsos.

set -euo pipefail

cd "$(dirname "$0")/../.."

# Presupuesto de arranque en milisegundos (ver PERFORMANCE.md).
PRESUPUESTO_MS=${PRESUPUESTO_ARRANQUE_MS:-2500}

DISPOSITIVO="${1:-}"
ARGS=(--profile --trace-startup)
[ -n "$DISPOSITIVO" ] && ARGS+=(-d "$DISPOSITIVO")

SALIDA=build/start_up_info.json
rm -f "$SALIDA"

echo "→ flutter run ${ARGS[*]}"
echo "  (la app se cierra sola al terminar la traza)"
flutter run "${ARGS[@]}"

if [ ! -f "$SALIDA" ]; then
  echo "No se generó $SALIDA. ¿Había un dispositivo conectado?" >&2
  exit 1
fi

python3 - "$SALIDA" "$PRESUPUESTO_MS" <<'PY'
import json, sys

datos = json.load(open(sys.argv[1]))
techo = int(sys.argv[2])

# Los nombres varían entre versiones del motor; se toma el primero disponible.
claves = [
    ('timeToFirstFrameRasterizedMicros', 'primer frame en pantalla'),
    ('timeToFirstFrameMicros', 'primer frame construido'),
    ('timeToFrameworkInitMicros', 'framework inicializado'),
    ('engineEnterTimestampMicros', 'entrada al motor'),
]

print()
print('Arranque:')
medida = None
for clave, etiqueta in claves:
    if clave in datos:
        ms = datos[clave] / 1000
        print(f'  {etiqueta:28} {ms:8.0f} ms')
        if medida is None and clave.startswith('timeToFirstFrame'):
            medida = ms

if medida is None:
    print('  no se encontró ninguna marca de primer frame', file=sys.stderr)
    sys.exit(1)

print()
if medida > techo:
    print(f'✗ {medida:.0f} ms supera el presupuesto de {techo} ms. Ver PERFORMANCE.md.')
    sys.exit(1)
print(f'✓ {medida:.0f} ms dentro del presupuesto de {techo} ms.')
PY
