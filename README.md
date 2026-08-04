# Clínica Salud Dental Integral

Sistema integral de gestión clínica y administrativa para optimizar el flujo de
trabajo de consultorios odontológicos. La plataforma centraliza la atención al
paciente, la agenda de citas, expedientes clínicos con odontograma y el
control financiero en una solución moderna y accesible.

---

## Objetivo

Ofrecer una herramienta intuitiva y segura que digitalice los procesos
operativos de la clínica, con control de acceso basado en roles para
administradores, doctores y asistentes — optimizando el tiempo en consulta y
mejorando el seguimiento clínico de los pacientes.

---

## Stack técnico

* **Frontend:** Flutter (Web, Android y escritorio) con BLoC y arquitectura
  limpia (clean architecture)
* **Backend & Base de datos:** Supabase (PostgreSQL, autenticación, Row Level
  Security)
* **Despliegue web:** Vercel (pipeline de CI/CD)

> Android y escritorio se generan como artefactos instalables separados: no
> se despliegan en Vercel. Ver [RELEASE.md](RELEASE.md).

---

## Características principales

### Gestión de pacientes y expedientes
* **Historial clínico:** registro detallado del expediente de cada paciente y
  seguimiento de consultas.
* **Odontograma interactivo:** visualización y marcado del estado dental de
  los pacientes.
* **Búsqueda eficiente:** filtros por nombre, apellido y cédula para
  localización rápida de récords.

### Agenda y citas
* **Mis citas del día:** vista diaria personalizable con filtros por doctor
  asignado.
* **Agendamiento:** programación de citas estándar y de emergencia.

### Control de acceso por roles (RBAC)
* **Administradores:** control total sobre el sistema, catálogo de
  tratamientos, gestión de equipos y reportes.
* **Doctores:** acceso enfocado en la atención al paciente, registro de
  diagnósticos, procedimientos y fórmulas/medicinas.
* **Asistentes:** gestión logística de agenda, recepción y citas de los
  doctores asignados.

### Módulo administrativo y financiero
* Control de cuentas por cobrar y facturación.
* Gestión de catálogo de tratamientos y procedimientos.
* Inventario y control de equipos de la clínica.

---

## Desarrollo local

La aplicación no trae URLs ni claves de Supabase compiladas: hay que inyectar
la configuración pública al iniciar o construir. Un `flutter run` sin ella no
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

En VS Code, la configuración **Salud Dental (dart_define.json)** de
`.vscode/launch.json` ya pasa ese argumento.

Las variables también pueden darse sueltas con `--dart-define=CLAVE=valor`,
que es como las inyecta el pipeline. Para usar un proyecto remoto,
`SUPABASE_URL` debe ser HTTPS (solo se admite HTTP contra localhost). En el
cliente únicamente se acepta una publishable/anon key; una `service_role` o
secret key **nunca** debe pasarse por `--dart-define`.

---

## Verificación

```bash
flutter analyze
flutter test
```

El repositorio conserva temporalmente un trinquete para fallos heredados de
la suite completa. La misma puerta que usa CI puede reproducirse con:

```bash
dart run tool/ci/verificar_pruebas.dart
```

---

## Operación y releases

| Documento | Contenido |
|---|---|
| [DEPLOYMENT.md](DEPLOYMENT.md) | Vercel, ambientes, variables, Supabase PKCE, dominio, validación y rollback |
| [RELEASE.md](RELEASE.md) | APK, app bundle, firma Android y escritorio |
| [PERFORMANCE.md](PERFORMANCE.md) | Presupuestos y medición de artefactos |
| [supabase/README.md](supabase/README.md) | Base de datos y migraciones |

---

## Demo en vivo

**[clinica-salud-dental-integral.vercel.app](https://clinica-salud-dental-integral.vercel.app)**
