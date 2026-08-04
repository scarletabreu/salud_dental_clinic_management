-- Audit 2026-08-02 · Frente 5 (F5-01 … F5-05). Todos verificados también en
-- producción con `supabase db dump --linked`.

begin;

-- ---------------------------------------------------------------------------
-- F5-01 · `auditoria_log` e `items_receta`: RLS activo y CERO políticas
--
-- De todas las tablas de `public`, sólo estas dos tienen `relrowsecurity = true`
-- sin una sola política. En Postgres eso es *denegar todo* para `authenticated`.
-- Falla cerrado, que es lo correcto, pero deja la auditoría genérica sin lector:
-- el rastro que escriben los triggers `fn_auditoria_log` sobre `citas`,
-- `cuentas`, `pagos`… no se puede consultar desde la aplicación **por nadie**,
-- ni siquiera por el admin. Hoy sólo se mira con psql.
--
-- `auditoria_clinica`, la de HFX-CLIN-005, sí tiene políticas y es la que usa la
-- aplicación; ésta es la otra.
-- ---------------------------------------------------------------------------
drop policy if exists auditoria_log_select on public.auditoria_log;
create policy auditoria_log_select on public.auditoria_log
  for select to authenticated
  using (public.es_admin());

grant select on public.auditoria_log to authenticated;

comment on table public.auditoria_log is
  'Rastro genérico que escriben los triggers `fn_auditoria_log`. Sólo lectura, '
  'y sólo para el admin: nadie la escribe desde la aplicación.';

-- `items_receta` está vacía por diseño accidental: ninguna función de la base
-- inserta en ella y ningún código Dart la escribe —`items_receta` en Dart es
-- siempre la clave JSONB dentro de `recetas`—. No hay pérdida para la
-- aplicación, pero la tabla normalizada sigue en el esquema invitando a que un
-- reporte o una integración la lea y concluya que no hay medicamentos
-- recetados. Se le da lectura coherente con su receta y se marca como legado
-- para que quien la encuentre sepa qué es.
drop policy if exists items_receta_select on public.items_receta;
create policy items_receta_select on public.items_receta
  for select to authenticated
  using (
    exists (
      select 1 from public.recetas r
       where r.id = items_receta.receta_id
         and public.puede_ver_consulta(r.consulta_id)
    )
  );

grant select on public.items_receta to authenticated;

comment on table public.items_receta is
  'LEGADO Y VACÍA. La fuente real de los medicamentos de una receta es la '
  'columna jsonb `recetas.items_receta`; nada escribe en esta tabla desde el '
  'formato SD-153. No la uses como origen de un reporte: dirá que no hay '
  'medicamentos recetados.';

-- ---------------------------------------------------------------------------
-- F5-02 · `hfx_base_crear_consulta_completa` es SECURITY DEFINER sin
--         `search_path` fijado
--
-- De las funciones `hfx_base_*` es la única sin `proconfig`: al ser SECURITY
-- DEFINER hereda el `search_path` de quien la llama. Hoy no es explotable —sólo
-- `service_role` tiene EXECUTE y quien la invoca fija `search_path=public`—,
-- pero es exactamente el patrón que la migración de endurecimiento cerró en las
-- otras siete.
-- ---------------------------------------------------------------------------
alter function public.hfx_base_crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb
) set search_path to 'public';

-- ---------------------------------------------------------------------------
-- F5-03 · Dos sobrecargas vivas de `crear_consulta_completa`
--
-- La firma sin `p_tipo_atencion` seguía siendo invocable por `authenticated` y
-- creaba la consulta con el tipo por defecto: una evaluación registrada por ahí
-- perdía su tipo y falseaba el expediente.
--
-- No era legado inerte: la firma nueva **delegaba** en ella —hacía la llamada y
-- después corregía `tipo_atencion` con un UPDATE—, así que las guardias vivían
-- en la vieja. Se absorben aquí: la firma de nueve argumentos pasa a ser
-- autosuficiente y fija el tipo en la creación, no después.
-- ---------------------------------------------------------------------------
create or replace function public.crear_consulta_completa(
  p_paciente_id uuid,
  p_doctor_id uuid,
  p_cita_id uuid,
  p_fecha timestamptz,
  p_motivo_consulta text,
  p_temp_condiciones jsonb,
  p_dientes jsonb,
  p_documentos jsonb,
  p_tipo_atencion tipo_atencion_clinica
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_cita        public.citas%rowtype;
  v_consulta_id uuid;
begin
  -- Guardias heredadas de la firma retirada: son las que impiden que un
  -- usuario sin sesión clínica cree una consulta, que un doctor firme por otro
  -- y que la consulta cuelgue de una cita que no es de ese doctor y paciente.
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_doctor()) then
    raise exception 'Sesión clínica activa requerida.' using errcode = '42501';
  end if;
  if not public.es_contexto_interno()
     and p_doctor_id is distinct from auth.uid() then
    raise exception 'No puede firmar una consulta como otro doctor.'
      using errcode = '42501';
  end if;

  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita no existe o fue eliminada.' using errcode = 'P0002';
  end if;
  if v_cita.doctor_id is distinct from p_doctor_id
     or v_cita.persona_id is distinct from p_paciente_id then
    raise exception 'La cita no pertenece al doctor y paciente indicados.'
      using errcode = '42501';
  end if;
  if v_cita.estado::text in ('cancelada', 'completada') then
    raise exception 'El estado de la cita no permite iniciar una consulta.'
      using errcode = '55000';
  end if;

  v_consulta_id := public.hfx_base_crear_consulta_completa(
    p_paciente_id, p_doctor_id, p_cita_id, p_fecha, p_motivo_consulta,
    p_temp_condiciones, p_dientes, p_documentos
  );

  update public.consultas
     set tipo_atencion = p_tipo_atencion,
         updated_at = now()
   where id = v_consulta_id;

  return v_consulta_id;
end;
$$;

drop function if exists public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb
);

revoke all on function public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb, tipo_atencion_clinica
) from public, anon;
grant execute on function public.crear_consulta_completa(
  uuid, uuid, uuid, timestamptz, text, jsonb, jsonb, jsonb, tipo_atencion_clinica
) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- F5-04 · Un paciente borrado bloqueaba para siempre su cédula
--
-- `personas` tenía DOS índices sobre la cédula:
--   · `personas_cedula_normalizada_uk UNIQUE (hfx_clin_004_normalizar_cedula(cedula))
--      WHERE deleted_at IS NULL` — correcto, excluye los borrados;
--   · `personas_cedula_key UNIQUE (cedula)` — **no** los excluye.
--
-- Verificado en vivo (sonda S8): al volver a registrar a un paciente cuya ficha
-- se había eliminado por error, la base responde `duplicate key ...
-- personas_cedula_key` y no hay forma de resolverlo desde la aplicación.
--
-- Se retira el índice redundante; el normalizado sigue impidiendo el duplicado
-- real, que es el que importa.
-- ---------------------------------------------------------------------------
alter table public.personas drop constraint if exists personas_cedula_key;

-- ---------------------------------------------------------------------------
-- F5-05 · La cadena de cascadas podía borrar el expediente clínico y financiero
--         completo de un paciente
--
-- `pacientes → personas`, `consultas → pacientes`, `cuentas → consultas` y
-- `pagos → cuentas` estaban en `ON DELETE CASCADE`. Un solo
-- `delete from personas where id = ...` borraba el expediente, los pagos y **la
-- propia auditoría que probaría que existieron**.
--
-- La aplicación siempre hace borrado lógico, pero la política `persona_delete`
-- existe y la vía seguía abierta para quien tenga el rol. Se corta la cadena en
-- sus cuatro eslabones estructurales: el resto de las cascadas cuelgan de
-- `consultas`, que ya no puede borrarse mientras exista su paciente.
-- ---------------------------------------------------------------------------
alter table public.pacientes
  drop constraint pacientes_id_fkey,
  add constraint pacientes_id_fkey
    foreign key (id) references public.personas(id) on delete restrict;

alter table public.consultas
  drop constraint consultas_paciente_id_fkey,
  add constraint consultas_paciente_id_fkey
    foreign key (paciente_id) references public.pacientes(id) on delete restrict;

alter table public.cuentas
  drop constraint cuentas_consulta_id_fkey,
  add constraint cuentas_consulta_id_fkey
    foreign key (consulta_id) references public.consultas(id) on delete restrict;

alter table public.pagos
  drop constraint pagos_cuenta_id_fkey,
  add constraint pagos_cuenta_id_fkey
    foreign key (cuenta_id) references public.cuentas(id) on delete restrict;

comment on constraint pacientes_id_fkey on public.pacientes is
  'RESTRICT, no CASCADE: borrar una persona no puede llevarse por delante el '
  'expediente clínico, los cobros y la auditoría que los prueba. La baja de un '
  'paciente es lógica (`deleted_at`).';

commit;
