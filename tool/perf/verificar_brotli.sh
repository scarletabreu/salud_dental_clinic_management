#!/usr/bin/env bash
# Comprueba que el sitio desplegado sirve el JS comprimido con brotli.
#
# SD-132. `main.dart.js` pesa 5115 KiB en crudo y 1095 KiB con brotli: casi
# todo el tiempo de arranque en web depende de que esto esté bien. Y es
# exactamente el tipo de ajuste que se da por hecho y nadie comprueba —hasta
# que alguien migra el hosting y la primera carga se cuadruplica en silencio.
#
# Uso:
#   tool/perf/verificar_brotli.sh https://mi-app.azurestaticapps.net

set -euo pipefail

BASE="${1:-}"
if [ -z "$BASE" ]; then
  echo "Uso: $0 <url-base-del-sitio>" >&2
  exit 2
fi
BASE="${BASE%/}"

fallos=0

comprobar() {
  local ruta="$1"
  local url="$BASE$ruta"

  # Se piden ambas codificaciones, como haría un navegador real, y se mira
  # cuál elige el servidor.
  local cabeceras
  cabeceras=$(curl -sSL -D - -o /dev/null \
    -H 'Accept-Encoding: br, gzip' \
    --max-time 30 "$url" 2>/dev/null) || {
    printf '  ✗ %-20s no se pudo descargar\n' "$ruta"
    fallos=$((fallos + 1))
    return
  }

  local codificacion tamano
  codificacion=$(printf '%s' "$cabeceras" | grep -i '^content-encoding:' | tail -1 | tr -d '\r' | awk '{print $2}')
  tamano=$(printf '%s' "$cabeceras" | grep -i '^content-length:' | tail -1 | tr -d '\r' | awk '{print $2}')
  [ -n "${tamano:-}" ] && tamano="$((tamano / 1024)) KiB" || tamano="?"

  case "${codificacion:-ninguna}" in
    br)
      printf '  ✓ %-20s brotli, %s\n' "$ruta" "$tamano"
      ;;
    gzip)
      printf '  ~ %-20s gzip, %s — funciona, pero brotli bajaría ~27%% más\n' "$ruta" "$tamano"
      ;;
    *)
      printf '  ✗ %-20s SIN COMPRIMIR, %s\n' "$ruta" "$tamano"
      fallos=$((fallos + 1))
      ;;
  esac
}

echo "Comprobando compresión en $BASE"
comprobar /main.dart.js
comprobar /flutter_bootstrap.js
comprobar /index.html

echo
if [ "$fallos" -gt 0 ]; then
  echo "✗ $fallos recurso(s) sin comprimir. Ver PERFORMANCE.md §4."
  exit 1
fi
echo "✓ Los recursos críticos llegan comprimidos."
