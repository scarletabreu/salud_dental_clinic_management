#!/usr/bin/env bash
# Mide el arranque de la app en un dispositivo real y lo compara con el
# presupuesto documentado en PERFORMANCE.md.
#
# SD-132, completado en SD-154. A diferencia de `medir_artefactos.sh`, esto
# necesita un dispositivo conectado: el arranque depende del hardware, y
# medirlo en el portátil del desarrollador no dice nada sobre el teléfono de la
# recepción.
#
# Uso:
#   tool/perf/medir_arranque.sh                    # primer dispositivo
#   tool/perf/medir_arranque.sh <id-dispositivo>   # ver `flutter devices`
#
#   REPETICIONES_ARRANQUE=7 tool/perf/medir_arranque.sh <id>
#   PRESUPUESTO_ARRANQUE_MS=3200 tool/perf/medir_arranque.sh <id>
#
# Qué hace:
#   `--trace-startup` deja en build/start_up_info.json las marcas que pone el
#   motor. La que importa es `timeToFirstFrameRasterizedMicros`: el instante en
#   que el usuario ve algo dibujado, no cuando el proceso arrancó.
#
# Importante: se mide en `--profile`, nunca en debug. Un build de debug corre
# el código Dart interpretado y es entre 3 y 10 veces más lento; medir ahí solo
# produce números alarmantes y falsos.
#
# Se mide varias veces y se reporta la **mediana**, y se descarta la primera
# ejecución tras instalar. No es ceremonia: en SD-154, sobre la misma máquina y
# sin cambiar nada, la primera medida dio 409 ms y las siguientes 119-125 ms.
# Quedarse con una sola ejecución es quedarse con el ruido.

set -euo pipefail

cd "$(dirname "$0")/../.."

# Presupuesto de arranque en milisegundos (ver PERFORMANCE.md).
PRESUPUESTO_MS=${PRESUPUESTO_ARRANQUE_MS:-2500}

# Repeticiones que cuentan. Se ejecuta una más: la primera se descarta porque
# incluye trabajo de instalación y de calentamiento que el usuario no repite.
REPETICIONES=${REPETICIONES_ARRANQUE:-5}

DISPOSITIVO="${1:-}"
SALIDA=build/start_up_info.json

# La app no arranca sin su configuración, y esto es la diferencia entre medir y
# creer que se mide: sin `--dart-define-from-file` el bootstrap aborta con
# «Falta APP_ENVIRONMENT» y aun así el motor pinta la pantalla de error y
# reporta un primer frame rapidísimo. Se mediría el arranque de un cartel de
# error, no el de la app, y el script diría «✓ dentro del presupuesto».
DEFINES=dart_define.json
if [ ! -f "$DEFINES" ]; then
  echo "Falta $DEFINES (ver README). Sin él la app no arranca y la medida no vale." >&2
  exit 2
fi

ARGS=(--profile --trace-startup "--dart-define-from-file=$DEFINES")
[ -n "$DISPOSITIVO" ] && ARGS+=(-d "$DISPOSITIVO")

# ── Identidad del hardware ──────────────────────────────────────────────────
# Un arranque sin el hardware anotado al lado no significa nada: 2500 ms es
# excelente en un gama baja y malo en un buque insignia. Se deja en la salida
# para poder copiarlo tal cual a PERFORMANCE.md.
echo "→ Dispositivo"
if [ -n "$DISPOSITIVO" ] && command -v adb >/dev/null 2>&1 \
   && adb devices | awk 'NR>1 && $1 != ""' | grep -q "^$DISPOSITIVO[[:space:]]"; then
  modelo=$(adb -s "$DISPOSITIVO" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
  marca=$(adb -s "$DISPOSITIVO" shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
  android=$(adb -s "$DISPOSITIVO" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
  abi=$(adb -s "$DISPOSITIVO" shell getprop ro.product.cpu.abi 2>/dev/null | tr -d '\r')
  kb=$(adb -s "$DISPOSITIVO" shell cat /proc/meminfo 2>/dev/null | awk '/MemTotal/{print $2}')
  ram="desconocida"
  [ -n "${kb:-}" ] && ram="$(( kb / 1024 )) MiB"
  echo "  $marca $modelo · Android $android · $abi · RAM $ram"
else
  # No es un Android por adb (escritorio, web, o adb no disponible): no hay de
  # dónde sacar el modelo automáticamente.
  echo "  ${DISPOSITIVO:-primer dispositivo disponible}"
  echo "  ⚠️  anota a mano modelo, RAM y versión de sistema junto al número"
fi
echo

# Lee una marca de build/start_up_info.json en microsegundos.
#
# Con `awk` y no con `python3` a propósito: en Windows esto se corre desde Git
# Bash, que trae awk, sort y mktemp pero **no** trae Python. Con python3 el
# script moría al terminar de medir, después de gastar las seis compilaciones.
# El archivo es JSON plano, una clave por línea, así que no hace falta más.
# Ninguna de las claves contiene dígitos, de ahí que valga con borrar todo lo
# que no sea número.
marca() {
  awk -v clave="$1" '
    index($0, "\"" clave "\"") {
      gsub(/[^0-9]/, "", $0)
      if ($0 != "") { print $0; encontrada = 1 }
      exit
    }
    END { if (!encontrada) exit 1 }
  ' "$SALIDA"
}

total=$(( REPETICIONES + 1 ))
echo "→ flutter run ${ARGS[*]}"
echo "  $total ejecuciones; se descarta la primera y se reporta la mediana de $REPETICIONES"
echo

medidas=()
for i in $(seq 1 "$total"); do
  # Borrar antes de *cada* ejecución: si una falla, un archivo viejo haría
  # pasar por nueva la medida anterior.
  rm -f "$SALIDA"
  registro=$(mktemp)

  if ! flutter run "${ARGS[@]}" >"$registro" 2>&1; then
    echo "La ejecución $i falló:" >&2
    tail -20 "$registro" >&2
    rm -f "$registro"
    exit 1
  fi

  # El motor pinta la pantalla de error igual de rápido que la app. Si el
  # bootstrap falló, el número existe pero no mide nada.
  if grep -q "Fallo de arranque\|BootstrapErrorKind" "$registro"; then
    echo "La app no completó su arranque; la medida no sería del arranque real:" >&2
    grep -m1 "Fallo de arranque\|BootstrapErrorKind" "$registro" >&2
    rm -f "$registro"
    exit 1
  fi
  rm -f "$registro"

  if [ ! -f "$SALIDA" ]; then
    echo "No se generó $SALIDA en la ejecución $i. ¿Había un dispositivo conectado?" >&2
    exit 1
  fi

  micros=$(marca timeToFirstFrameRasterizedMicros || marca timeToFirstFrameMicros || true)
  if [ -z "$micros" ]; then
    echo "Sin marca de primer frame en $SALIDA (ejecución $i)." >&2
    exit 1
  fi
  ms=$(( (micros + 500) / 1000 ))

  if [ "$i" -eq 1 ]; then
    echo "  calentamiento: $ms ms (descartada)"
  else
    medidas+=("$ms")
    echo "  intento $(( i - 1 )): $ms ms"
  fi
done

echo

# Mediana y no promedio: una sola ejecución lenta por ruido de la máquina no
# debe mover el número de referencia.
resumen=$(printf '%s\n' "${medidas[@]}" | sort -n | awk -v techo="$PRESUPUESTO_MS" '
  { v[NR] = $1 }
  END {
    mediana = v[int(NR / 2) + 1]
    printf "Primer frame en pantalla (mediana de %d): %d ms\n", NR, mediana
    printf "  mejor %d ms · peor %d ms\n\n", v[1], v[NR]
    printf "Para PERFORMANCE.md §1: medida %d ms · trinquete sugerido %d ms (+15 %%)\n\n",
           mediana, int(mediana * 1.15 / 10 + 0.5) * 10
    if (mediana > techo) {
      printf "✗ %d ms supera el presupuesto de %d ms. Ver PERFORMANCE.md.\n", mediana, techo
      exit 1
    }
    printf "✓ %d ms dentro del presupuesto de %d ms.\n", mediana, techo
  }
') && estado=0 || estado=$?
echo "$resumen"
exit "$estado"
