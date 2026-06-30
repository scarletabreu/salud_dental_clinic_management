-- ============================================================================
--  Condiciones médicas por paciente · tabla puente record ↔ condicion
--  Ejecuta este archivo en el SQL Editor de Supabase (una sola vez).
--
--  Objetivo:
--    Registrar QUÉ condiciones del catálogo (`condiciones`) padece cada paciente,
--    para que la verificación de contraindicaciones (SD-85) en consulta tenga
--    datos estructurados contra los cuales cruzar, en vez del texto libre.
--
--  Esquema REAL (verificado contra la BD vía PostgREST, no contra el dump):
--    · La tabla puente real es `record_condicion` (singular), con columnas
--      (record_id, condicion_id, fecha_deteccion) y FKs a `records` y
--      `condiciones`. OJO: el `schema.sql` del repo está desfasado y muestra una
--      tabla `record_aflicciones` con FKs que NO existe así en la BD real.
--    · Cada paciente tiene a lo sumo un `records` (records.paciente_id UNIQUE).
--    · `records` NO tiene columna `condiciones` en la BD real (el dump miente);
--      por eso el expediente mínimo solo setea paciente_id + tipo_sangre.
--
--  Notas:
--    · En la instancia actual `record_condicion` ya existe con sus FKs y datos,
--      así que los CREATE/ALTER de abajo son no-ops; lo único nuevo y necesario
--      fue agregar 'desconocido' al enum tipo_sangre. El script es idempotente y
--      deja una instancia nueva en el mismo estado.
-- ============================================================================

-- 1) tipo_sangre: agregar 'desconocido' (records.tipo_sangre es NOT NULL y un
--    expediente creado solo para registrar condiciones aún no lo conoce).
do $$
begin
  if not exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    where t.typname = 'tipo_sangre'
      and e.enumlabel = 'desconocido'
  ) then
    alter type "public"."tipo_sangre" add value 'desconocido';
  end if;
end $$;

-- 2) Tabla puente record ↔ condición (con PK y FKs inline, de modo que una
--    instancia nueva la cree correctamente; en la actual es no-op).
create table if not exists "public"."record_condicion" (
  "record_id"       uuid not null
    references "public"."records"("id") on delete cascade,
  "condicion_id"    uuid not null
    references "public"."condiciones"("id") on delete cascade,
  "fecha_deteccion" timestamp with time zone default now(),
  primary key ("record_id", "condicion_id")
);

-- 3) Índice para listar las condiciones de un expediente.
create index if not exists "idx_record_condicion_record"
  on "public"."record_condicion" using btree ("record_id");

-- 4) Grants (mismo esquema que el resto de tablas del proyecto).
grant all on table "public"."record_condicion" to "anon";
grant all on table "public"."record_condicion" to "authenticated";
grant all on table "public"."record_condicion" to "service_role";
