# Salud Dental Clinic Management

Aplicación Flutter para la gestión clínica y administrativa de Salud Dental.
El cliente web usa Supabase como backend y se publica en Azure Static Web
Apps. Android y escritorio se generan como artefactos instalables separados:
no se despliegan en Azure.

## Desarrollo local

La aplicación no trae URLs ni claves de Supabase compiladas. Hay que inyectar
la configuración pública al iniciar o construir:

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=APP_ENVIRONMENT=development \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=CLAVE_PUBLICA_LOCAL
```

Para usar un proyecto remoto, `SUPABASE_URL` debe ser HTTPS. Solo se admite una
publishable/anon key en el cliente; una `service_role` o secret key nunca debe
pasarse mediante `--dart-define`.

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
