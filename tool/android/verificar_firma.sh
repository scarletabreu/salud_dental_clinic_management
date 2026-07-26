#!/usr/bin/env bash
# Comprueba con qué certificado está firmado un APK y avisa si es el de
# depuración.
#
# La clave de depuración (`CN=Android Debug, OU=Android, O=Android, C=US`) la
# genera Flutter igual en todas las máquinas: es pública. Un APK firmado con
# ella acepta actualizaciones de cualquiera que la use, que es todo el mundo.
# Este script existe para que eso no se vuelva a colar sin que nadie lo note:
# se mira el artefacto, no la configuración.
#
# Uso:
#   tool/android/verificar_firma.sh                       # el APK de release
#   tool/android/verificar_firma.sh ruta/a/otro.apk

set -euo pipefail

cd "$(dirname "$0")/../.."

APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"

if [ ! -f "$APK" ]; then
  echo "No existe $APK. Construye antes: flutter build apk --release" >&2
  exit 2
fi

# apksigner es un script que invoca `java`; en muchas máquinas el JDK está solo
# dentro de Android Studio y no en el PATH.
if ! command -v java >/dev/null 2>&1; then
  for jdk in /opt/android-studio/jbr /usr/lib/jvm/*; do
    if [ -x "$jdk/bin/java" ]; then
      export JAVA_HOME="$jdk"
      export PATH="$JAVA_HOME/bin:$PATH"
      break
    fi
  done
fi
if ! command -v java >/dev/null 2>&1; then
  echo "No se encontró java. Instala un JDK 17 o exporta JAVA_HOME." >&2
  exit 1
fi

# `|| true`: find devuelve error si alguna de las rutas no existe, y con
# `set -e` + `pipefail` eso abortaría el script en mitad de una asignación.
APKSIGNER=$(find "${ANDROID_HOME:-$HOME/Android/Sdk}" /opt/android-sdk /usr/lib/android-sdk \
  -name apksigner -type f 2>/dev/null | sort -r | head -1 || true)
if [ -z "$APKSIGNER" ]; then
  echo "No se encontró apksigner (viene en build-tools del SDK de Android)." >&2
  exit 1
fi

echo "APK: $APK"
salida=$("$APKSIGNER" verify --print-certs "$APK" 2>&1)

dn=$(printf '%s' "$salida" | grep -m1 'certificate DN' | sed 's/.*certificate DN: //')
sha=$(printf '%s' "$salida" | grep -m1 'SHA-256 digest' | sed 's/.*digest: //')

if [ -z "$dn" ]; then
  echo "✗ El APK no parece estar firmado."
  printf '%s\n' "$salida" | head -5
  exit 1
fi

echo "  Certificado: $dn"
echo "  SHA-256:     $sha"
echo

case "$dn" in
  *"CN=Android Debug"*)
    echo "✗ Firmado con la CLAVE DE DEPURACIÓN. No distribuir."
    echo "  Esa clave es pública: cualquiera podría publicar una actualización"
    echo "  que el dispositivo aceptaría como legítima. Ver RELEASE.md."
    exit 1
    ;;
  *"CN=Build efimero"*)
    echo "✗ Firmado con la clave DESECHABLE de medición. No distribuir."
    echo "  Sirve para medir tamaño o probar en un dispositivo, no para repartir."
    exit 1
    ;;
  *)
    echo "✓ Firmado con una clave propia."
    echo "  Anota el SHA-256: es la huella que debe repetirse en cada versión"
    echo "  publicada. Si cambia, los dispositivos rechazarán la actualización."
    ;;
esac
