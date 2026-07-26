# Publicación

Cómo se firma y se distribuye la app. Complementa `PERFORMANCE.md`, que cubre
los presupuestos y el tamaño de los artefactos.

---

## 1. La firma de Android

### Qué pasaba antes

`android/app/build.gradle.kts` traía la línea de la plantilla de Flutter:

```kotlin
release {
    signingConfig = signingConfigs.getByName("debug")
}
```

**Todo APK de release salía firmado con la clave de depuración.** Esa clave no
es un secreto: la genera Flutter igual en cada instalación, con el mismo
`CN=Android Debug, OU=Android, O=Android, C=US`, y está en el disco de
cualquiera que tenga el SDK. Android decide si acepta una actualización
comparando la firma del APK nuevo con la del instalado: si la app está firmada
con la clave de depuración, **cualquiera puede construir una actualización que
el dispositivo instalará encima como legítima**, y en una app clínica eso da
acceso a datos de pacientes.

No era un descuido visible: el build funcionaba, el APK se instalaba y nada
avisaba. Por eso el arreglo no es solo poner una clave propia, sino hacer que
el estado incorrecto **falle en vez de pasar en silencio**.

### Cómo funciona ahora

La firma sale de `android/key.properties`, que **no se versiona**
(`android/.gitignore` ya excluía `key.properties`, `*.jks` y `*.keystore`).

- Si el fichero existe → se firma con esa clave.
- Si no existe → el build de release **falla** con un mensaje que explica qué
  falta. Ya no se hereda la clave de depuración.

Los builds de debug, `flutter test` y `flutter analyze` no se ven afectados:
la comprobación cuelga solo de las tareas `assembleRelease` y `bundleRelease`.

### Crear la clave de publicación

```bash
tool/android/generar_keystore.sh
```

Pide la contraseña por teclado —no se pasa por argumento, para que no quede en
el historial del shell ni en ningún log—, crea el keystore en
`~/.claves-salud-dental/release.jks` con 10 000 días de validez y escribe
`android/key.properties` con permisos `600`.

> **Este fichero es irremplazable.** Si se pierde, no se puede volver a
> publicar una actualización de esta app **nunca**: Android rechazará cualquier
> APK firmado con otra clave, y la única salida es publicar una app distinta y
> pedir a cada clínica que desinstale y reinstale. Respaldarlo fuera de la
> máquina, y dejar por escrito quién lo custodia.

### Clave desechable para medir o probar

```bash
tool/android/generar_keystore.sh --efimero
```

Contraseña conocida y fija. Sirve para medir el tamaño del APK —que no depende
de con qué se firme— o probar un release en un dispositivo. Es lo que usa el
workflow `presupuestos-semanales.yml`. **Nada firmado con ella se distribuye**;
el verificador de abajo lo rechaza expresamente.

### Comprobar el artefacto, no la configuración

```bash
tool/android/verificar_firma.sh
tool/android/verificar_firma.sh ruta/a/otro.apk
```

Lee el certificado del APK ya construido y falla si es el de depuración o el
desechable. Se mira el artefacto y no el `build.gradle.kts` a propósito: lo que
se reparte es el fichero, y es ahí donde hay que comprobarlo.

Al publicar, anotar el **SHA-256** que imprime. Es la huella que debe repetirse
en cada versión: si cambia, los dispositivos rechazarán la actualización.

### Firmar desde CI

La clave de publicación **no vive en CI**. Si en algún momento se automatiza la
publicación, el keystore va como secreto (`base64` del `.jks` más las
contraseñas), se materializa en el runner, se firma y se borra. Requiere
permiso de admin sobre el repositorio para dar de alta esos secretos.

---

## 2. Qué se distribuye

| Plataforma | Artefacto | Comando |
|---|---|---|
| Android (reparto directo) | APK de **una** arquitectura, ~23 MB | `flutter build apk --release --split-per-abi` |
| Android (Play Store) | App Bundle | `flutter build appbundle --release` |
| Web | `build/web` en Azure Static Web Apps | ver `PERFORMANCE.md §3.bis` |
| Escritorio | binario de Windows | `flutter build windows --release` |

**No repartir el APK universal.** Pesa 67 MB porque lleva las librerías nativas
de tres arquitecturas y cada teléfono usa una; el de `arm64-v8a` son 23 MB. El
detalle y los números están en `PERFORMANCE.md §3.bis`.

Añadir `--obfuscate --split-debug-info=<dir>` a los builds de release y
**archivar los símbolos junto a la versión publicada**: sin ellos, un fallo en
producción llega como direcciones sin nombre y no hay forma de leerlo.

Todos los comandos de release requieren además los tres `--dart-define`
documentados en `DEPLOYMENT.md`. El workflow de Azure genera exclusivamente
`build/web`: no publica APK, app bundle ni binarios de escritorio.

---

## 3. Pendiente

- **`applicationId` sigue siendo `com.example.salud_dental_clinic_management`**
  (`android/app/build.gradle.kts`). Google Play rechaza cualquier paquete bajo
  `com.example`. Cambiarlo requiere elegir un dominio real y tener en cuenta
  que **una app ya instalada con el identificador viejo no se actualiza**: se
  instalaría al lado como una app distinta. Conviene hacerlo antes de la
  primera distribución seria.
- Automatizar la publicación en GitHub Releases a partir de una etiqueta.
