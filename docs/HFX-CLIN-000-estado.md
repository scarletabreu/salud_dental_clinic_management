# HFX-CLIN-000 · Estado de la implementación

> Rama: `hotfix-admin-clinical-identity` (base: `dev` en `c4f2e1c`).
> Última actualización: 30 jul 2026. **Ticket en curso, no terminado.**

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

## Lo que falta para cerrar el ticket

1. **Correr la suite completa (`flutter test`) y dejarla verde.** Es lo que
   estaba en marcha al pausar; nunca llegó a terminar en esta rama. La línea
   base de `dev` ya venía roja (ver memoria `dev-suite-roja-baseline`), así que
   hay que separar los fallos preexistentes de los que introduzca el ticket.
   Sospechosos directos del cambio: `responsive_listados_test.dart` (fallaba ya
   antes), y todo lo que construya perfiles o toque el shell.
2. **Pruebas Dart que aún pide el plan §6** y no están escritas:
   aprovisionamiento por rol y login por rol contra el mapper
   (`PerfilActualMapper.desdeFila`), y admin incluido en el catálogo de doctores
   desde `DoctorRemoteDatasourceImpl`.
3. **Smoke test web** de login + agenda con los tres roles (criterio explícito
   del plan). No ejecutado.
4. **Actualizar `supabase/README.md`**: sigue diciendo que `db reset` no sirve
   para bootstrapear y que hay que cargar `schema.sql` a mano. Ya no es cierto.
   Añadir también la tabla del nuevo test SQL.
5. **Revisar el diff completo** y hacer el commit atómico definitivo.

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
flutter analyze                         # debe dar 0 errores
flutter test                            # <- punto 1 de "lo que falta"

PGURL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
for t in supabase/tests/*.sql; do psql "$PGURL" -v ON_ERROR_STOP=1 -f "$t"; done
```
