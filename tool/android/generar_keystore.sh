#!/usr/bin/env bash
# Genera la clave con la que se firman los APK de release y escribe
# android/key.properties para que Gradle la encuentre.
#
# Dos modos, y la diferencia importa mucho:
#
#   (sin argumentos)  Clave de PUBLICACIÓN. Te pide las contraseñas y crea un
#                     keystore con 10.000 días de validez. Este fichero es
#                     irremplazable: si se pierde, no se puede volver a
#                     publicar una actualización de la app nunca más, porque
#                     Android exige que la firma coincida. Hay que respaldarlo
#                     fuera de la máquina y fuera del repositorio.
#
#   --efimero         Clave DESECHABLE, con contraseña conocida y fija. Sirve
#                     para medir el tamaño del APK en CI o probar un release en
#                     un dispositivo. El tamaño del artefacto no depende de la
#                     clave, así que para eso vale cualquiera. NO distribuir
#                     nada firmado con ella.
#
# Ni el keystore ni key.properties se versionan: android/.gitignore ya los
# excluye. Compruébalo antes de commitear si tocas ese fichero.

set -euo pipefail

cd "$(dirname "$0")/../.."

EFIMERO=false
[ "${1:-}" = "--efimero" ] && EFIMERO=true

DESTINO_PROPS="android/key.properties"

# keytool viene con el JDK; en muchas máquinas no está en el PATH.
buscar_keytool() {
  if command -v keytool >/dev/null 2>&1; then command -v keytool; return; fi
  local encontrado
  # `|| true` por lo mismo que en verificar_firma.sh: rutas que no existen
  # hacen que find salga con error y `set -e` mataría el script.
  encontrado=$(find /usr/lib/jvm /opt /Library/Java 2>/dev/null \
    -maxdepth 4 -name keytool -type f | head -1 || true)
  if [ -z "$encontrado" ]; then
    echo "No se encontró keytool. Instala un JDK 17 o exporta JAVA_HOME." >&2
    exit 1
  fi
  printf '%s' "$encontrado"
}
KEYTOOL=$(buscar_keytool)

if [ -f "$DESTINO_PROPS" ] && [ "$EFIMERO" = false ]; then
  echo "Ya existe $DESTINO_PROPS." >&2
  echo "Bórralo a mano si de verdad quieres generar otra clave: cambiarla" >&2
  echo "significa que la app deja de poder actualizar a las ya instaladas." >&2
  exit 1
fi

if $EFIMERO; then
  RUTA_KEYSTORE="$PWD/android/efimero.jks"
  ALIAS="efimero"
  CLAVE="efimero123"
  echo "→ Clave DESECHABLE para medir o probar. No distribuir lo que firme."
  rm -f "$RUTA_KEYSTORE"
  "$KEYTOOL" -genkeypair -v \
    -keystore "$RUTA_KEYSTORE" \
    -alias "$ALIAS" \
    -keyalg RSA -keysize 2048 -validity 365 \
    -storepass "$CLAVE" -keypass "$CLAVE" \
    -dname "CN=Build efimero, OU=CI, O=Salud Dental, L=Santo Domingo, C=DO" \
    >/dev/null 2>&1
  chmod 600 "$RUTA_KEYSTORE"
  ALMACEN_PASS="$CLAVE"
  CLAVE_PASS="$CLAVE"
else
  RUTA_KEYSTORE="${HOME}/.claves-salud-dental/release.jks"
  ALIAS="salud-dental"
  echo "→ Clave de PUBLICACIÓN."
  echo "  Se guardará en $RUTA_KEYSTORE (fuera del repositorio)."
  echo "  RESPÁLDALA: sin ella no se pueden publicar actualizaciones nunca más."
  echo

  mkdir -p "$(dirname "$RUTA_KEYSTORE")"
  chmod 700 "$(dirname "$RUTA_KEYSTORE")"

  if [ -f "$RUTA_KEYSTORE" ]; then
    echo "Ya hay un keystore en $RUTA_KEYSTORE. No se toca." >&2
    exit 1
  fi

  # Interactivo a propósito: la contraseña la teclea quien custodia la clave y
  # no debe quedar en el historial del shell, en un fichero ni en un log.
  read -r -s -p "  Contraseña del almacén: " ALMACEN_PASS; echo
  read -r -s -p "  Repite la contraseña:   " CONFIRMA; echo
  if [ "$ALMACEN_PASS" != "$CONFIRMA" ]; then
    echo "No coinciden." >&2
    exit 1
  fi
  if [ ${#ALMACEN_PASS} -lt 8 ]; then
    echo "Usa al menos 8 caracteres." >&2
    exit 1
  fi
  CLAVE_PASS="$ALMACEN_PASS"

  "$KEYTOOL" -genkeypair -v \
    -keystore "$RUTA_KEYSTORE" \
    -alias "$ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$ALMACEN_PASS" -keypass "$CLAVE_PASS"

  chmod 600 "$RUTA_KEYSTORE"
fi

umask 077
cat > "$DESTINO_PROPS" <<EOF
# Generado por tool/android/generar_keystore.sh
# NO versionar: android/.gitignore lo excluye.
storeFile=$RUTA_KEYSTORE
storePassword=$ALMACEN_PASS
keyAlias=$ALIAS
keyPassword=$CLAVE_PASS
EOF
chmod 600 "$DESTINO_PROPS"

echo
echo "✓ $DESTINO_PROPS escrito."
if $EFIMERO; then
  echo "  Clave desechable. Los APK que firme no se reparten."
else
  echo "  Respalda $RUTA_KEYSTORE en un sitio seguro y fuera de esta máquina."
  echo "  Comprueba la firma tras construir:"
  echo "    apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk"
fi
