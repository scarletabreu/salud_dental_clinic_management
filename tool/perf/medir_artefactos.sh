#!/usr/bin/env bash
# Mide el tamaño de los artefactos de release y lo compara con el presupuesto.
#
# SD-132. Este script es la parte reproducible de la medición: se ejecuta igual
# en cualquier máquina y en CI, y falla si un artefacto se pasa de su techo.
# Los presupuestos y su justificación están en PERFORMANCE.md.
#
# Uso:
#   tool/perf/medir_artefactos.sh                # web + apk, compara presupuesto
#   tool/perf/medir_artefactos.sh web            # solo web
#   tool/perf/medir_artefactos.sh apk-abi        # APK por arquitectura
#   tool/perf/medir_artefactos.sh --json         # salida para CI
#
# El tamaño no es el único síntoma de lentitud, pero sí el único que se puede
# medir sin un dispositivo conectado. Los presupuestos de frames y arranque se
# verifican con `tool/perf/medir_arranque.sh`, que sí necesita un dispositivo.

set -euo pipefail

cd "$(dirname "$0")/../.."

# ── Presupuestos (KiB). Ver PERFORMANCE.md para el porqué de cada número. ────
#
# Son *trinquetes*, no metas: cada techo es lo que mide hoy el artefacto más un
# margen pequeño. Sirven para que nadie empeore lo que hay, no para declarar
# que el tamaño actual esté bien. Las metas a las que queremos llegar están en
# PERFORMANCE.md §1; bajar hasta ellas exige carga diferida por módulo y es
# trabajo propio, no de este script.
#
# Al reducir un artefacto de verdad, **baja también su techo aquí**: un
# trinquete que no se aprieta deja de proteger.
PRESUPUESTO_WEB_INICIAL=5800   # main.dart.js: medido en CI 4 ago 2026 = 5724 KiB
PRESUPUESTO_WEB_TOTAL=46500    # build/web: línea base HFX-CLIN-000 = 45912 KiB
PRESUPUESTO_APK=68000          # APK universal de release (no se distribuye)
PRESUPUESTO_APK_ABI=25500      # APK de una sola arquitectura (lo que se descarga)

JSON=false
OBJETIVOS=()
for arg in "$@"; do
  case "$arg" in
    --json) JSON=true ;;
    web|apk|apk-abi) OBJETIVOS+=("$arg") ;;
    *) echo "argumento no reconocido: $arg" >&2; exit 2 ;;
  esac
done
[ ${#OBJETIVOS[@]} -eq 0 ] && OBJETIVOS=(web apk)

kib() { du -sk "$1" 2>/dev/null | cut -f1; }

fallos=0
declare -A medido

reportar() {
  local nombre="$1" valor="$2" techo="$3"
  medido["$nombre"]="$valor"
  if [ "$valor" -gt "$techo" ]; then
    printf '  ✗ %-22s %8s KiB  (presupuesto %s KiB)\n' "$nombre" "$valor" "$techo"
    fallos=$((fallos + 1))
  else
    printf '  ✓ %-22s %8s KiB  (presupuesto %s KiB)\n' "$nombre" "$valor" "$techo"
  fi
}

for objetivo in "${OBJETIVOS[@]}"; do
  case "$objetivo" in
    web)
      echo "→ flutter build web --release"
      flutter build web --release >/dev/null
      echo "Web:"
      reportar "web/main.dart.js" "$(kib build/web/main.dart.js)" "$PRESUPUESTO_WEB_INICIAL"
      reportar "web/total" "$(kib build/web)" "$PRESUPUESTO_WEB_TOTAL"
      ;;
    apk)
      echo "→ flutter build apk --release"
      flutter build apk --release >/dev/null
      echo "APK:"
      reportar "apk/universal" \
        "$(kib build/app/outputs/flutter-apk/app-release.apk)" "$PRESUPUESTO_APK"
      ;;
    apk-abi)
      # Lo que de verdad se descarga un teléfono. El APK universal lleva las
      # librerías nativas de las tres arquitecturas; el usuario solo usa una.
      echo "→ flutter build apk --release --split-per-abi"
      flutter build apk --release --split-per-abi >/dev/null
      echo "APK por arquitectura:"
      for abi in arm64-v8a armeabi-v7a x86_64; do
        archivo="build/app/outputs/flutter-apk/app-$abi-release.apk"
        [ -f "$archivo" ] && reportar "apk/$abi" "$(kib "$archivo")" "$PRESUPUESTO_APK_ABI"
      done
      ;;
  esac
done

if $JSON; then
  printf '{'
  primero=true
  for k in "${!medido[@]}"; do
    $primero || printf ','
    printf '"%s":%s' "$k" "${medido[$k]}"
    primero=false
  done
  printf '}\n'
fi

if [ "$fallos" -gt 0 ]; then
  echo
  echo "$fallos artefacto(s) por encima del presupuesto. Ver PERFORMANCE.md."
  exit 1
fi

echo
echo "Todos los artefactos dentro de presupuesto."
