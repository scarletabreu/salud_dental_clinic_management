# Salud Dental Clinic Management

Aplicación Flutter para la gestión clínica y administrativa de Salud Dental.
El cliente web usa Supabase como backend y se publica en Azure Static Web
Apps. Android y escritorio se generan como artefactos instalables separados:
no se despliegan en Azure.

## Desarrollo local

La aplicación no trae URLs ni claves de Supabase compiladas: hay que inyectar la
configuración pública al iniciar o construir. Un `flutter run` sin ella no
arranca y muestra una pantalla de error explicando qué falta.

Copia la plantilla una sola vez y rellena los valores de tu proyecto:

```bash
cp dart_define.example.json dart_define.json
```

`dart_define.json` está en `.gitignore`; nunca se versiona. A partir de ahí:

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=dart_define.json
```

En VS Code la configuración **Salud Dental (dart_define.json)** de
`.vscode/launch.json` ya pasa ese argumento.

Las variables también pueden darse sueltas con `--dart-define=CLAVE=valor`, que
es como las inyecta el pipeline. Para usar un proyecto remoto, `SUPABASE_URL`
debe ser HTTPS —solo se admite HTTP contra localhost—. En el cliente únicamente
se acepta una publishable/anon key; una `service_role` o secret key nunca debe
pasarse por `--dart-define`.

## Verificación

```bash
flutter analyze
flutter test
```

El repositorio conserva temporalmente un trinquete para fallos heredados de la
suite completa. La misma puerta que usa CI puede reproducirse con:

```bash
dart run tool/ci/verificar_pruebas.dart
```

## Operación y releases

- [DEPLOYMENT.md](DEPLOYMENT.md): Azure, ambientes, variables, Supabase PKCE,
  dominio, validación y rollback.
- [RELEASE.md](RELEASE.md): APK, app bundle, firma Android y escritorio.
- [PERFORMANCE.md](PERFORMANCE.md): presupuestos y medición de artefactos.
- [supabase/README.md](supabase/README.md): base de datos y migraciones.
