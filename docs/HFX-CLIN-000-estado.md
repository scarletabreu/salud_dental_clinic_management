# HFX-CLIN-000 · Estado de la implementación

> Rama: `hotfix-admin-clinical-identity` (base: `dev` en `c4f2e1c`).
> Última actualización: 30 jul 2026. **Alcance del ticket completo**; queda
> abierta la decisión sobre la instancia remota (ver «Riesgos abiertos»).

Plan de referencia:
`~/Documents/Salud Dental Clinic/CORE-CLINICO-HOTFIX-PLAN.md`, primer ticket.

---

## Nombre de la rama

El plan pide `hotfix/admin-clinical-identity`, pero el repositorio ya tiene una
rama local llamada exactamente `hotfix`, y git no permite crear `hotfix/...`
mientras exista. Se usó `hotfix-admin-clinical-identity`, que además es la
convención del otro hotfix del repo (`hotfix-recetas-sd153-...`). La rama
`hotfix` **no se tocó**.

---

## Lo que ya está hecho y verificado

### Base de datos — `supabase db reset` vuelve a arrancar el proyecto

Era el bloqueo de fondo: las migraciones no reconstruían nada (la primera
asumía tablas que ninguna creaba) y cuatro abortaban con `already exists`.

- Las 25 migraciones anteriores se movieron a `supabase/migrations_historicas/`.
  **No se borraron**: quedan como registro.
- `supabase/migrations/20260725000000_linea_base.sql` — dump del esquema
  `public` resultante de aplicarlas todas en orden sobre la instancia validada.
- `supabase/migrations/20260725000100_linea_base_objetos_no_public.sql` — lo que
  un dump de esquema no trae y sólo existía en la instancia: buckets de Storage
  (`documentos-clinicos`, `fotos-pacientes`), sus políticas, y la publicación de
  realtime de `movimientos_caja`.
- `supabase/schema.sql` regenerado desde la base migrada.

`supabase db reset` corre limpio de principio a fin, con el seed incluido.

### Identidad admin-doctor

`supabase/migrations/20260731090000_hfx_clin_000_identidad_admin_doctor.sql`:

- backfill de admins sin fila en `doctores` (especialidad por defecto
  `'General'`, sin sobrescribir una fila clínica existente);
- comprobación post-backfill que aborta con mensaje accionable;
- FK `admins.id -> doctores.id`;
- `handle_new_user` reescrito: admin crea `usuarios` + `doctores` + `admins`;
  valida nombre, apellido, fecha de nacimiento, cédula, username y turno antes
  de escribir;
- **`personas.id` pasa a ser el UUID de Auth.** Antes se generaba uno aleatorio,
  así que `usuarios.id != auth.uid()` y toda la RLS (`id = auth.uid()`) fallaba
  para cualquier usuario creado por esta vía;
- el trigger `on_auth_user_created` sobre `auth.users`, que **no estaba
  versionado en ningún archivo**: una base reconstruida autenticaba usuarios que
  nunca llegaban a tener perfil.

### Perfil y catálogo

`supabase/migrations/20260731090100_hfx_clin_000_perfil_y_catalogo_doctores.sql`:

- `perfil_actual()`: contrato único del perfil de la sesión, resuelto con
  `auth.uid()`, sin ninguna columna de contraseña. Sólo `authenticated`.
- `get_active_doctors()` versionada por primera vez, ya sin `password_hash`
  (antes acababa impreso en la consola del navegador) y con `es_admin`.

### Recetas

`supabase/migrations/20260731090200_hfx_clin_000_recetas_formato_sd153.sql`
lleva `recetas` al formato que el cliente ya usa (`items_receta` jsonb,
`doctor_id`, `fecha_emision`, `estado`, `receta_reemplazada_id`) sin destruir
las filas antiguas.

### Dart

- **`lib/features/auth/domain/capacidades_usuario.dart`** — enum `Capacidad` y
  la tabla de capacidades por rol acordada con la clínica.
- **`lib/features/auth/presentation/cubit/capacidades_sesion.dart`** — las que
  necesitan saber quién está conectado: `puedeAtenderCitaDe(doctorId)` y
  `doctorIdParaFiltrarAgenda`. Ver toda la agenda ≠ firmar por todos.
- Sustituidas las comparaciones `rol == RolUsuario.x` en agenda, pacientes,
  detalle de paciente, dashboard, shell, navegación, pre-factura y alta de
  usuarios. Con esto el **admin ya puede iniciar la consulta de su propia cita**,
  que antes era literalmente inalcanzable.
- **`perfil_actual_mapper.dart`** + `UsuarioRepositoryImpl.getPerfilPorUuid`
  ahora van por la RPC. Ojo: `crearUsuario` usa `_perfilDeOtroUsuario`, porque
  `getPerfilPorUuid` resuelve siempre la sesión actual.
- Borrado el stack `Admin*RemoteDatasource/Repository` (muerto y escribiendo
  contra columnas `user_id`/`estatus` inexistentes) y las escrituras muertas del
  stack de doctor (incluida la tabla `doctors`, que no existe). Fuera el
  `print('RAW SUPABASE RESPONSE: ...')` que volcaba PII.

### Edge Function `admin-crear-usuario`

Valida campos y rol antes de tocar Auth; **acepta el teléfono dentro de
`contactos`**, que es como lo manda Flutter y por lo que hasta ahora nunca se
creaba el contacto; comprueba admin *activo*; no devuelve el error interno
completo; y borra el usuario de Auth si quedara sin perfil.

### Pruebas

- `supabase/tests/hfx_clin_000_identidad_admin_doctor_test.sql` — 8 casos,
  **verde**. Alta de los tres roles, alta inválida revertida entera, FK, el
  contrato de `perfil_actual()` por rol, el admin agendable que firma su
  consulta, y los grants (anon no ejecuta nada).
- Las cuatro suites SQL previas siguen **verdes**.
- `test/features/auth/capacidades_usuario_test.dart` — 12 casos, **verde**.
- Reparados los 7 archivos de test que no compilaban (45 errores). Se conservó
  la intención de cada caso; el único assert que perdió representación es
  `notas` del formato antiguo de receta, que la entidad SD-153 no modela (queda
  anotado en el propio archivo).
- `flutter analyze`: **0 errores** (línea base real: 45), 10 warnings (línea
  base: 11), todos preexistentes.

---

### Suite Flutter recuperada

`flutter test` completo: **663 pruebas, 1 fallo**. Antes de esta tanda había 22.

Ninguno de los 21 corregidos era una regresión del ticket: se comprobó
ejecutando las mismas suites sobre `c4f2e1c` en un worktree aparte. Tres suites
ni siquiera compilaban en la base, así que sus fallos reales estaban tapados.

| Suite | Qué pasaba | Qué se hizo |
|---|---|---|
| `consulta_detalle_responsive_test` (6) | la página resuelve también `sl<PacienteCubit>()` y el harness no lo registraba | doble de `PacienteCubit` |
| `responsive_listados_test` (6) | `_ConsultaCard` lee `AuthCubit` para decidir si ofrece continuar; el test no lo proveía | `AuthCubit` doble con la sesión del doctor |
| `responsive_shell_test` (5) | describía la navegación móvil anterior (claves `mobile-navigation-*`, texto «Más») y una política de roles más estrecha de la que `dev` ya tenía | reescritas contra el diseño vigente (FAB «Más módulos», `onNavigateTo`) y contra la política real |
| `paciente_responsive_test` (2) | «Nuevo Paciente» desbordaba la cabecera 21 px a 320 px | el botón baja a su propia fila en layout compacto |
| `pre_factura_responsive_test` (1) | insignia de estado y etiquetas de KPI desbordaban con texto ×2 | `Wrap` en la cabecera, `Flexible`/`Expanded` en las etiquetas |
| `odontodiagrama_impresion_test` (1) | el botón pasó a llamarse «Imprimir Odontodiagrama» | expectativa actualizada |

**El fallo que queda es de otro ticket**: `guardado_clinico_test` ·
«un diagnóstico conserva pieza, cara, fecha y origen» falla porque el payload
manda `superficiecle` en vez de `superficie`. Falla igual en `c4f2e1c`, y el
plan lo asigna explícitamente a HFX-CLIN-002 §1, con su prueba de contra­to
contra PostgREST real. No se tocó aquí para no diluir el límite entre tickets.

### Pruebas Dart nuevas del §6

- `test/features/auth/perfil_actual_mapper_test.dart` — 7 casos: el admin nace
  `Admin` **y** `Doctor`, el doctor sin datos administrativos, el asistente sin
  identidad clínica, una fila sin rol no produce sesión, ningún rol trae
  contraseña, el contacto no se fabrica si falta y el estatus se conserva.
- `test/features/personal/doctor_catalogo_test.dart` — 3 casos sobre
  `DoctorRemoteDatasourceImpl`: el admin aparece en el catálogo agendable y
  marcado como tal, no llegan contraseñas, y una baja llega como inactiva.
  Para poder probarlo sin red, el datasource recibe una costura opcional
  `getActiveDoctorsRpc`, igual que `ConsultaRemoteDatasourceImpl`.

### Smoke de login y agenda por rol

`supabase/tests/hfx_clin_000_smoke_login_agenda.sh`, **verde**. Recorre contra
el stack local el mismo camino del navegador: alta por Auth (que dispara
`handle_new_user`), login de los tres roles, `perfil_actual()`,
`get_active_doctors()` y lectura de `citas`; comprueba que el admin sale
agendable, que ninguna respuesta trae `password_hash` y que `anon` no ejecuta
nada. Crea sus usuarios con sufijo aleatorio y los borra al salir.

> **Limitación.** No es un recorrido por la UI real. `dart_define.json` apunta a
> la instancia **remota**, así que levantar Flutter Web tal cual habría hablado
> con producción, y el repo no tiene `integration_test` ni driver para guiar el
> navegador (el plan sitúa el E2E web en HFX-CLIN-006). Lo que se verificó es
> toda la capa que la UI consume; el clic sigue siendo manual.

### Base de datos, revalidada de cero

`supabase db reset` limpio, y sobre esa base reconstruida las **cinco** suites
SQL en verde (`hfx_clin_000` 9 OK, `sd_111` 6 OK, `sd_135`, `sd_146` 8 OK,
`sd_169`). Cero admins sin fila en `doctores`.

`flutter analyze`: **0 errores**, 10 warnings preexistentes.

`supabase/README.md` actualizado: `db reset` es ahora el bootstrap, se explica
el squash y `migrations_historicas/`, y se documentan el test SQL y el smoke.

## Riesgos abiertos, a decidir con el dueño

- **Sincronía con la instancia remota.** Al squashear las migraciones, el
  historial local ya no coincide con `supabase_migrations.schema_migrations` de
  la instancia. Antes del próximo `db push` habrá que hacer un
  `supabase migration repair` marcando la línea base como aplicada. **No se
  tocó nada remoto**, y no debe tocarse sin decisión explícita.
- **`handle_new_user` de la instancia real puede diferir** del que había en
  `schema.sql`. Si en producción los usuarios sí tienen `personas.id ==
  auth.uid()`, es que la instancia lleva una versión distinta (drift). Conviene
  comprobarlo antes de aplicar allí, y revisar si hay filas históricas con el
  UUID desalineado: esas quedan con RLS rota y esta migración no las repara.
- **`Perfiles` en el shell** sigue accesible para el doctor, aunque la tabla de
  capacidades dice que «administrar personal» es sólo del admin. Estrechar ese
  acceso cambia comportamiento y se decidió dejarlo para HFX-CLIN-001, que es
  quien trae las pruebas de autorización. Está comentado en
  `lib/shell/shell_destination.dart`.
- **`passwordHash` sigue en las entidades** `Usuario`/`Doctor`/`Admin`. Su
  retirada es explícitamente HFX-CLIN-001. Lo que sí se hizo aquí es dejar de
  traerlo del servidor: la RPC de perfil y la de catálogo ya no lo devuelven, y
  el mapper rellena `''`.

## Cómo retomar

```bash
git checkout hotfix-admin-clinical-identity
supabase start
supabase db reset                       # reconstruye entera, ya sin parches
flutter analyze                         # 0 errores
flutter test                            # 663 pruebas, 1 fallo (HFX-CLIN-002)

PGURL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
for t in supabase/tests/*.sql; do psql "$PGURL" -v ON_ERROR_STOP=1 -f "$t"; done
./supabase/tests/hfx_clin_000_smoke_login_agenda.sh
```
