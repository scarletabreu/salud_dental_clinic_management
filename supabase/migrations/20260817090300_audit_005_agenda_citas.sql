-- Audit 2026-08-02 · Frente 3 y §1.4/§1.5: agenda, estados de cita y las
-- superficies de escritura que la esquivan.
--
-- Todas las sondas de esta migración se ejercieron con un token real:
--   S3b · una doctora movió `fecha_hora` un mes y puso la cita en 600 minutos
--         con un `PATCH` directo. Pasó.
--   S4b · con `es_emergencia: true` en la misma petición, dos citas de la misma
--         doctora a la misma hora. Pasó.
--   S5b · reprogramar una cita **con consulta abierta** movió `consultas.fecha`
--         del 2 ago al 20 sep. Pasó.
--   S6b · cancelar esa misma cita: `P0001`, bloqueado. La asimetría entre
--         cancelar y reprogramar era real.

begin;

-- ---------------------------------------------------------------------------
-- §1.4 y F3-02 · El enum `estado_cita` tenía etiquetas casi duplicadas
--
-- `no_asistida` convive con `no_asistio`, y `pendiente` con `programada`.
-- Existe `hfx_clin_004_estado_cita_canonico()` para mapearlas, pero cada
-- consumidor nuevo que olvide llamarla cuenta mal —estadísticas de
-- inasistencia, recordatorios— y el cliente leía `no_asistida` como
-- «Programada»: una cita marcada como inasistencia reaparecía en la agenda y se
-- podía confirmar, registrar llegada e iniciar consulta sobre ella.
--
-- Postgres no permite borrar etiquetas de un enum. Se normalizan los datos y un
-- CHECK impide volver a escribir las legadas: quedan como historia imposible de
-- producir.
-- ---------------------------------------------------------------------------
update public.citas
   set estado = 'no_asistio'::estado_cita, updated_at = now()
 where estado = 'no_asistida'::estado_cita;

update public.citas
   set estado = 'programada'::estado_cita, updated_at = now()
 where estado = 'pendiente'::estado_cita;

update public.citas
   set estado = 'completada'::estado_cita, updated_at = now()
 where estado::text = 'atendida';

alter table public.citas drop constraint if exists citas_estado_canonico;
alter table public.citas
  add constraint citas_estado_canonico
  check (estado = any (array[
    'programada'::estado_cita,
    'confirmada'::estado_cita,
    'en_espera'::estado_cita,
    'en_consulta'::estado_cita,
    'completada'::estado_cita,
    'cancelada'::estado_cita,
    'no_asistio'::estado_cita
  ]));

comment on constraint citas_estado_canonico on public.citas is
  'Las etiquetas `no_asistida`, `pendiente` y `atendida` del enum son legado; '
  '`hfx_clin_004_estado_cita_canonico` sigue traduciéndolas para lo histórico, '
  'pero este CHECK impide reintroducirlas.';

-- ---------------------------------------------------------------------------
-- S3b · Nada acotaba la duración de una cita fuera de la UI
--
-- El CHECK admitía hasta 1440 minutos (un día entero). Una cita de 600 minutos
-- entró por `PATCH` directo sin que nada la mirase. Media jornada es un techo
-- generoso para una cita odontológica y sigue permitiendo cirugías largas.
-- ---------------------------------------------------------------------------
update public.citas
   set duracion_minutos = 480, updated_at = now()
 where duracion_minutos > 480;

alter table public.citas drop constraint if exists citas_duracion_posible;
alter table public.citas
  add constraint citas_duracion_posible
  check (duracion_minutos >= 5 and duracion_minutos <= 480);

-- ---------------------------------------------------------------------------
-- F3-01 · Reprogramar una cita con consulta abierta reescribía la fecha clínica
--
-- El trigger `tr_realinear_consulta_al_reprogramar_cita` mueve `consultas.fecha`
-- cuando cambia `citas.fecha_hora`. Su trigger hermano
-- `tr_bloquear_cancelacion_con_consulta_abierta` sí protege la cancelación
-- cuando hay una consulta en curso; la reprogramación no tenía esa protección.
--
-- Escenario: el doctor está atendiendo. En recepción reprograman esa misma cita
-- para la semana que viene. La consulta que se está escribiendo **ahora** queda
-- fechada la semana que viene: sale del historial de hoy, se ordena mal en el
-- expediente —todo el historial ordena por `consultas.fecha`— y el PDF la fecha
-- en el futuro. Es la reaparición, por otra puerta, del defecto raíz que SD-160
-- vino a cerrar.
--
-- Se cierra la puerta: con la consulta abierta, primero se termina o se cancela.
-- La realineación se mantiene para la reprogramación legítima —la de una cita
-- que aún no se ha atendido—, que es para lo que se escribió.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_audit_bloquear_reprogramacion_en_consulta()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
  v_consulta uuid;
begin
  if new.fecha_hora is not distinct from old.fecha_hora then
    return new;
  end if;

  select id into v_consulta
    from consultas
   where cita_id = new.id
     and deleted_at is null
     and finalizada is not true
   limit 1;

  if v_consulta is not null then
    raise exception
      'Esta cita tiene una consulta en curso: mover su fecha cambiaría la fecha '
      'clínica del expediente que se está escribiendo. Termínala o cancélala '
      'antes de reprogramar.'
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

drop trigger if exists tr_bloquear_reprogramacion_en_consulta on public.citas;
create trigger tr_bloquear_reprogramacion_en_consulta
  before update of fecha_hora on public.citas
  for each row execute function public.hfx_audit_bloquear_reprogramacion_en_consulta();

-- ---------------------------------------------------------------------------
-- F3-04 · Un booleano del cliente desactivaba el control de solape
--
-- El índice de exclusión `citas_sin_solape` excluye las urgencias, y `updateCita`
-- mandaba `es_emergencia` **desde el cliente** junto con la fecha. La sonda S4b
-- lo ejerció: la misma doctora, la misma hora, dos citas, con un booleano.
--
-- Marcar una urgencia sigue siendo legítimo, pero es una decisión clínica que
-- deja rastro: la toma `registrar_cita_emergencia`, que corre como SECURITY
-- DEFINER y exige motivo. Encenderla con un `PATCH` no.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_audit_proteger_emergencia_cita()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  -- Sólo se vigila al cliente; las RPC clínicas corren como el dueño de la
  -- función y son las que sí pueden declarar una urgencia.
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if coalesce(new.es_emergencia, false)
     and not coalesce(old.es_emergencia, false) then
    raise exception
      'Una cita se marca como urgencia al registrarla, no editándola: hacerlo '
      'después la saca del control de solapes sin dejar constancia del motivo.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists tr_proteger_emergencia_cita on public.citas;
create trigger tr_proteger_emergencia_cita
  before update of es_emergencia on public.citas
  for each row execute function public.hfx_audit_proteger_emergencia_cita();

-- ---------------------------------------------------------------------------
-- §1.5 · `registrar_llegada_cita` no miraba el reloj
--
-- Tras el early-return de `en_espera` hacía el UPDATE sin comprobar que la cita
-- fuera de hoy. El grafo de estados lo permite y nadie miraba la fecha, así que
-- cualquier vista que listara citas futuras ofrecía el botón y la llegada
-- pasaba. La exposición era baja mientras la única vista fuera la del día, pero
-- el control no existía en la base.
-- ---------------------------------------------------------------------------
create or replace function public.registrar_llegada_cita(p_cita_id uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_cita   public.citas%rowtype;
  v_estado text;
  v_zona constant text := 'America/Santo_Domingo';
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null
          or not (public.es_admin() or public.es_doctor() or public.es_asistente())) then
    raise exception 'Sesión activa requerida para registrar la llegada.'
      using errcode = '42501';
  end if;

  select * into v_cita
    from public.citas
   where id = p_cita_id and deleted_at is null
   for update;
  if not found then
    raise exception 'La cita ya no existe o fue eliminada.' using errcode = 'CL015';
  end if;

  -- Un doctor registra la llegada de sus pacientes; quien gestiona la agenda
  -- completa (admin y asistente) la de cualquiera.
  if not public.es_contexto_interno()
     and not (public.es_admin() or public.es_asistente())
     and v_cita.doctor_id is distinct from auth.uid() then
    raise exception 'No puede registrar la llegada de una cita ajena.'
      using errcode = '42501';
  end if;

  v_estado := public.hfx_clin_004_estado_cita_canonico(v_cita.estado::text);
  if v_estado = 'en_espera' then
    return jsonb_build_object('cita_id', p_cita_id, 'estado', 'en_espera',
                             'ya_registrada', true);
  end if;

  -- La llegada es un hecho de hoy. Registrarla sobre una cita de otro día
  -- adelanta o retrasa el expediente y descuadra cualquier recuento de la
  -- jornada.
  if (v_cita.fecha_hora at time zone v_zona)::date
     <> (current_timestamp at time zone v_zona)::date then
    raise exception
      'Esta cita no es de hoy (%). Reprográmala para la fecha de hoy antes de '
      'registrar la llegada.',
      to_char((v_cita.fecha_hora at time zone v_zona)::date, 'DD/MM/YYYY')
      using errcode = 'CL015';
  end if;

  update public.citas
     set estado = 'en_espera', updated_at = now()
   where id = p_cita_id;

  return jsonb_build_object('cita_id', p_cita_id, 'estado', 'en_espera',
                           'ya_registrada', false);
end;
$$;

revoke all on function public.registrar_llegada_cita(uuid) from public, anon;
grant execute on function public.registrar_llegada_cita(uuid)
  to authenticated, service_role;

commit;
