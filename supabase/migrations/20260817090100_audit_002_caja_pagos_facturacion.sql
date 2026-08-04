-- Audit 2026-08-02 · Frente 2 (F2-01 … F2-07) y la sonda S10.
--
-- La contabilidad tenía fugas por los bordes: una caja sin cerrar de un día
-- anterior bloqueaba todos los cobros del día siguiente mientras la pantalla
-- decía que la caja estaba abierta; la cantidad ejecutada nunca llegaba a la
-- factura; un pago que nacía pendiente y se completaba después no entraba nunca
-- en el arqueo; anular un pago no revertía su ingreso; y cualquier doctor podía
-- reescribir el monto de una cuenta ajena con una sola petición.

begin;

-- ---------------------------------------------------------------------------
-- F2-01 · Una caja abierta de ayer bloqueaba todos los cobros de hoy
--
-- `cajas_una_abierta_idx UNIQUE (cerrada) WHERE cerrada = false` permitía UNA
-- sola caja abierta en todo el sistema, mientras el trigger de pagos exige la
-- caja de HOY en hora de Santo Domingo. Si el viernes nadie cerró: el sábado no
-- se podía abrir caja (índice global) ni cobrar (no hay caja de hoy), con un
-- mensaje que contradecía lo que la pantalla mostraba.
--
-- La unicidad pasa a ser por día civil. `fecha_civil` existe porque el índice
-- necesita una expresión IMMUTABLE y `fecha at time zone 'America/Santo_Domingo'`
-- no lo es; la mantiene un trigger, así que no puede desincronizarse.
-- ---------------------------------------------------------------------------
alter table public.cajas
  add column if not exists fecha_civil date;

comment on column public.cajas.fecha_civil is
  'Día civil de la caja en hora de Santo Domingo, derivado de `fecha`. Lo '
  'mantiene el trigger cajas_fijar_fecha_civil; existe sólo para poder indexar '
  'la unicidad por día (la conversión de zona no es IMMUTABLE).';

create or replace function public.hfx_audit_fijar_fecha_civil_caja()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  new.fecha_civil :=
    (coalesce(new.fecha, now()) at time zone 'America/Santo_Domingo')::date;
  return new;
end;
$$;

drop trigger if exists cajas_fijar_fecha_civil on public.cajas;
create trigger cajas_fijar_fecha_civil
  before insert or update of fecha on public.cajas
  for each row execute function public.hfx_audit_fijar_fecha_civil_caja();

update public.cajas
   set fecha_civil = (fecha at time zone 'America/Santo_Domingo')::date
 where fecha_civil is distinct from
       (fecha at time zone 'America/Santo_Domingo')::date;

alter table public.cajas
  alter column fecha_civil set not null;

-- Si el histórico tuviera dos cajas abiertas del mismo día, el índice único no
-- podría crearse. Se cierran las más antiguas dejando constancia: son cajas que
-- el índice global anterior no podía haber producido, así que esto sólo protege
-- contra datos manipulados a mano.
with duplicadas as (
  select id,
         row_number() over (partition by fecha_civil order by created_at desc) as puesto
    from public.cajas
   where cerrada = false
)
update public.cajas c
   set cerrada = true,
       observaciones = coalesce(c.observaciones || E'\n', '')
         || '[audit_002] Cerrada automáticamente: había otra caja abierta del mismo día.',
       updated_at = now()
  from duplicadas d
 where d.id = c.id and d.puesto > 1;

drop index if exists public.cajas_una_abierta_idx;

create unique index if not exists cajas_una_abierta_por_dia_idx
  on public.cajas (fecha_civil)
  where cerrada = false;

comment on index public.cajas_una_abierta_por_dia_idx is
  'Una caja abierta por día civil. El índice anterior era global y una caja sin '
  'cerrar de cualquier día impedía abrir la de hoy y, con ella, cobrar.';

-- ---------------------------------------------------------------------------
-- F2-02 · La cantidad ejecutada nunca llegaba a la factura
--
-- `items_cuenta.cantidad` se fijaba en 1 y el total sumaba `precio_aplicado`
-- una vez por fila, aunque `tratamientos_aplicados.cantidad_realizada` existe y
-- la UI la pide. Tres sesiones se cobraban como una.
--
-- Además el filtro `estado <> 'indicado'` era inerte: el CHECK de la tabla sólo
-- admite `aplicado|en_proceso|completado`, así que un tratamiento **empezado y
-- no terminado** se facturaba al 100 %. Ahora se factura lo ejecutado
-- (`aplicado`, `completado`); lo que sigue `en_proceso` se cobrará en el cierre
-- de la consulta en que se termine.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_base_finalizar_consulta(
  p_consulta_id uuid,
  p_metodo_pago text default 'contado',
  p_nota text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_paciente_id uuid;
  v_cita_id     uuid;
  v_cuenta_id   uuid;
  v_monto_total numeric(12,2);
  v_metodo_pago modo_pago;
begin
  -- El método llega como texto desde la app; la columna es el enum `modo_pago`.
  begin
    v_metodo_pago := lower(btrim(coalesce(p_metodo_pago, 'contado')))::modo_pago;
  exception when invalid_text_representation then
    raise exception 'Método de pago inválido: %. Valores admitidos: contado, credito.',
      p_metodo_pago using errcode = '22023';
  end;

  select paciente_id, cita_id into v_paciente_id, v_cita_id
  from consultas where id = p_consulta_id and deleted_at is null;
  if v_paciente_id is null then
    raise exception 'La consulta % no existe o fue eliminada.', p_consulta_id;
  end if;

  -- Cierre clínico ANTES de cualquier retorno: finalizar una consulta cierra su
  -- cita, y eso debe valer también cuando la pre-factura ya existía. El estado
  -- terminal se respeta (no se reabre una cita cancelada a mano).
  if v_cita_id is not null then
    update citas
       set estado     = 'completada'::estado_cita,
           updated_at = now()
     where id = v_cita_id
       and estado <> 'completada'::estado_cita
       and estado <> 'cancelada'::estado_cita;
  end if;

  -- Idempotencia: reintentar finalizar no duplica la pre-factura.
  select id into v_cuenta_id from cuentas
  where consulta_id = p_consulta_id and deleted_at is null limit 1;
  if v_cuenta_id is not null then return v_cuenta_id; end if;

  -- Sólo lo ejecutado y terminado. Las actividades del plan (propuestas,
  -- aceptadas o pendientes) y los hallazgos de la evaluación no facturan, y un
  -- procedimiento que quedó a medias tampoco: se cobra donde se termina.
  select coalesce(
           sum(round(coalesce(precio_aplicado, 0)
                     * coalesce(cantidad_realizada, 1), 2)), 0)
    into v_monto_total
  from tratamientos_aplicados
  where consulta_id = p_consulta_id
    and deleted_at is null
    and coalesce(estado, 'aplicado') in ('aplicado', 'completado');

  insert into cuentas (
    paciente_id, consulta_id, estado, monto_total, metodo_pago,
    fecha_creacion, nota, created_at, updated_at
  ) values (
    v_paciente_id, p_consulta_id, 'abierta', v_monto_total, v_metodo_pago,
    now(), p_nota, now(), now()
  ) returning id into v_cuenta_id;

  insert into items_cuenta (
    cuenta_id, tratamiento_aplicado_id, descripcion, precio_unitario, cantidad,
    created_at, updated_at
  )
  select v_cuenta_id, ta.id, coalesce(t.nombre, 'Tratamiento'),
         coalesce(ta.precio_aplicado, 0),
         coalesce(ta.cantidad_realizada, 1),
         now(), now()
  from tratamientos_aplicados ta
  left join tratamientos t on t.id = ta.tratamiento_id
  where ta.consulta_id = p_consulta_id
    and ta.deleted_at is null
    and coalesce(ta.estado, 'aplicado') in ('aplicado', 'completado');

  return v_cuenta_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- F2-04 y S10 · El arqueo sólo veía los pagos que nacían completados
--
-- `pagos_registrar_ingreso_caja` era AFTER INSERT únicamente:
--   · un pago que nacía `pendiente` y se completaba por UPDATE nunca entraba en
--     caja (S10): el dinero estaba en `pagos` y no en el arqueo;
--   · anular un pago completado no revertía su ingreso (F2-04): el cierre
--     esperaba un dinero que ya no existía y reportaba sobrante.
--
-- El trigger pasa a sincronizar el estado del pago con la caja en las dos
-- direcciones. Revertir un ingreso cuya caja ya está cerrada no reescribe un
-- día cerrado: deja un egreso compensatorio en la caja de hoy, que es como se
-- corrige una caja en contabilidad.
-- ---------------------------------------------------------------------------
create or replace function public.sincronizar_pago_en_caja()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_caja_id       uuid;
  v_caja_original uuid;
  v_cerrada       boolean;
  v_era_ingreso   boolean := false;
  v_es_ingreso    boolean;
  v_zona constant text := 'America/Santo_Domingo';
begin
  if tg_op = 'UPDATE' then
    v_era_ingreso := old.estado = 'completado' and old.deleted_at is null;
  end if;
  v_es_ingreso := new.estado = 'completado' and new.deleted_at is null;

  -- Nada que sincronizar: ni era ni es un cobro efectivo.
  if not v_era_ingreso and not v_es_ingreso then
    return new;
  end if;

  -- Un cobro efectivo que sigue siéndolo por el mismo monto ya está registrado.
  if v_era_ingreso and v_es_ingreso and old.monto = new.monto then
    return new;
  end if;

  if v_es_ingreso and not v_era_ingreso then
    select id into v_caja_id
      from cajas
     where cerrada = false
       and fecha_civil = (current_timestamp at time zone v_zona)::date
     limit 1
     for update;

    if v_caja_id is null then
      raise exception using
        errcode = 'P0001',
        message = 'No hay una caja abierta para hoy. Abre la caja antes de registrar el pago.';
    end if;

    insert into movimientos_caja (
      caja_diaria_id, tipo, monto, descripcion, referencia_id, fecha
    ) values (
      v_caja_id, 'ingreso', new.monto, 'Cobro a cuenta', new.id, new.fecha
    );

    return new;
  end if;

  -- A partir de aquí el pago deja de ser un cobro efectivo (anulado, revertido
  -- a pendiente) o cambió de monto: hay que deshacer el ingreso anterior.
  select mc.caja_diaria_id, c.cerrada
    into v_caja_original, v_cerrada
    from movimientos_caja mc
    join cajas c on c.id = mc.caja_diaria_id
   where mc.referencia_id = old.id
     and mc.tipo = 'ingreso'
     and mc.deleted_at is null
   order by mc.created_at desc
   limit 1;

  if v_caja_original is null then
    -- No había ingreso que revertir (pago anterior a esta migración o creado
    -- sin caja). No se inventa un movimiento negativo.
    return new;
  end if;

  if not v_cerrada then
    update movimientos_caja
       set deleted_at = now(), updated_at = now()
     where referencia_id = old.id
       and tipo = 'ingreso'
       and deleted_at is null;
  else
    -- La caja del cobro ya cerró: corregirla reescribiría un arqueo firmado.
    select id into v_caja_id
      from cajas
     where cerrada = false
       and fecha_civil = (current_timestamp at time zone v_zona)::date
     limit 1
     for update;

    if v_caja_id is null then
      raise exception using
        errcode = 'P0001',
        message = 'El cobro que se anula pertenece a una caja ya cerrada. '
                  'Abre la caja de hoy para registrar la devolución.';
    end if;

    insert into movimientos_caja (
      caja_diaria_id, tipo, monto, descripcion, referencia_id, fecha
    ) values (
      v_caja_id, 'egreso', old.monto,
      'Reverso de cobro anulado de una caja ya cerrada', old.id, now()
    );
  end if;

  -- Si además cambió de monto y sigue siendo cobro efectivo, se vuelve a
  -- registrar por el importe nuevo.
  if v_es_ingreso then
    select id into v_caja_id
      from cajas
     where cerrada = false
       and fecha_civil = (current_timestamp at time zone v_zona)::date
     limit 1
     for update;

    if v_caja_id is null then
      raise exception using
        errcode = 'P0001',
        message = 'No hay una caja abierta para hoy. Abre la caja antes de corregir el pago.';
    end if;

    insert into movimientos_caja (
      caja_diaria_id, tipo, monto, descripcion, referencia_id, fecha
    ) values (
      v_caja_id, 'ingreso', new.monto, 'Cobro a cuenta (corregido)', new.id,
      new.fecha
    );
  end if;

  return new;
end;
$$;

drop trigger if exists pagos_registrar_ingreso_caja on public.pagos;
drop trigger if exists pagos_sincronizar_caja on public.pagos;
create trigger pagos_sincronizar_caja
  after insert or update on public.pagos
  for each row execute function public.sincronizar_pago_en_caja();

drop function if exists public.registrar_pago_en_caja();

-- ---------------------------------------------------------------------------
-- F2-04 · Anular un pago necesita una vía que además recalcule la cuenta
--
-- `anularPago` marcaba `deleted_at` directo: el ingreso quedaba vivo y la cuenta
-- seguía diciendo «saldada». Ahora hay una única vía, transaccional, que revoca
-- el pago, deshace su efecto en la cuota y devuelve la cuenta a su estado real.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_base_anular_pago(
  p_pago_id uuid,
  p_motivo text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_pago    public.pagos%rowtype;
  v_total   numeric(15,2);
  v_pagado  numeric(15,2);
begin
  select * into v_pago
    from pagos
   where id = p_pago_id and deleted_at is null
   for update;

  if not found then
    raise exception 'El pago no existe o ya fue anulado.' using errcode = 'P0002';
  end if;

  select monto_total into v_total
    from cuentas where id = v_pago.cuenta_id for update;

  update pagos
     set deleted_at = now(),
         updated_at = now(),
         estado = 'cancelado'::estado_pago
   where id = p_pago_id;

  if v_pago.cuota_id is not null then
    update cuotas
       set monto_pagado = greatest(monto_pagado - v_pago.monto, 0),
           estado = case
             when greatest(monto_pagado - v_pago.monto, 0) >= monto
               then 'pagada'::estado_cuota
             when fecha_vencimiento < current_date
               then 'vencida'::estado_cuota
             else 'pendiente'::estado_cuota
           end,
           updated_at = now()
     where id = v_pago.cuota_id;
  end if;

  select coalesce(sum(monto), 0) into v_pagado
    from pagos
   where cuenta_id = v_pago.cuenta_id
     and estado = 'completado'
     and deleted_at is null;

  update cuentas
     set estado = case
           when v_pagado >= coalesce(v_total, 0) and coalesce(v_total, 0) > 0
             then 'saldada'
           when v_pagado > 0 then 'pendiente'
           else 'abierta'
         end,
         fecha_pago = case when v_pagado >= coalesce(v_total, 0)
                            and coalesce(v_total, 0) > 0
                           then fecha_pago end,
         nota = case
           when nullif(btrim(coalesce(p_motivo, '')), '') is null then nota
           else coalesce(nota || E'\n', '')
                || '[Pago anulado] ' || btrim(p_motivo)
         end,
         updated_at = now()
   where id = v_pago.cuenta_id;
end;
$$;

create or replace function public.anular_pago(
  p_pago_id uuid,
  p_motivo text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_admin()) then
    raise exception 'Anular un cobro requiere capacidad administrativa.'
      using errcode = '42501';
  end if;
  perform public.hfx_base_anular_pago(p_pago_id, p_motivo);
end;
$$;

-- ---------------------------------------------------------------------------
-- F2-05 · Rutas de escritura directa que esquivan el cobro atómico
--
-- Un insert directo en `pagos` como admin o asistente creaba el pago sin tocar
-- el saldo ni el estado de la cuenta (sonda S1 del audit, confirmada en vivo).
-- La única vía queda `registrar_pago`, que toma el lock, valida el saldo y la
-- cuota, y actualiza la cuenta; y `anular_pago` para deshacerlo. Ambas son
-- SECURITY DEFINER, así que siguen funcionando sin grant de tabla.
--
-- `cuentas` sólo las crea el cierre de consulta: el cliente no necesita INSERT.
-- ---------------------------------------------------------------------------
drop policy if exists pago_insert on public.pagos;
drop policy if exists pago_update on public.pagos;
revoke insert, update on public.pagos from authenticated;

drop policy if exists cuenta_create on public.cuentas;
revoke insert on public.cuentas from authenticated;

-- ---------------------------------------------------------------------------
-- F2-06 · Cualquier doctor podía cambiar el monto de cualquier cuenta
--
-- `cuenta_update` no tenía cláusula de pertenencia, al contrario que
-- `cuenta_select`. La sonda S2 lo ejerció con un token real: RD$3,200 → RD$1.00
-- sobre una cuenta ajena.
--
-- Dos capas: la política limita a las cuentas que el actor puede ver, y un
-- trigger congela las columnas que definen cuánto se debe y a quién. Editar el
-- modo de pago o la nota sigue siendo posible desde la pre-factura.
-- ---------------------------------------------------------------------------
drop policy if exists cuenta_update on public.cuentas;
create policy cuenta_update on public.cuentas
  for update to authenticated
  using (
    (es_admin() or es_doctor() or es_asistente())
    and (
      (paciente_id is not null and puede_ver_paciente(paciente_id))
      or puede_ver_consulta(consulta_id)
    )
  )
  with check (
    (es_admin() or es_doctor() or es_asistente())
    and (
      (paciente_id is not null and puede_ver_paciente(paciente_id))
      or puede_ver_consulta(consulta_id)
    )
  );

create or replace function public.hfx_audit_congelar_cuenta()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  -- Sólo se vigila al cliente: el cuerpo de las RPC clínicas corre como el
  -- dueño de la función (SECURITY DEFINER), no como `authenticated`. No sirve
  -- `es_contexto_interno()`, que mira `session_user` y devuelve `false` dentro
  -- de una RPC llamada desde PostgREST.
  if current_user not in ('authenticated', 'anon') then
    return new;
  end if;

  if new.monto_total is distinct from old.monto_total then
    raise exception
      'El monto de una pre-factura lo fija el cierre de la consulta y no puede '
      'editarse. Corrige los procedimientos registrados y vuelve a cerrarla.'
      using errcode = '42501';
  end if;

  if new.consulta_id is distinct from old.consulta_id
     or new.paciente_id is distinct from old.paciente_id then
    raise exception 'Una cuenta no puede cambiar de consulta ni de paciente.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists cuentas_congelar_columnas on public.cuentas;
create trigger cuentas_congelar_columnas
  before update on public.cuentas
  for each row execute function public.hfx_audit_congelar_cuenta();

-- ---------------------------------------------------------------------------
-- F2-07 · Tolerancia de un centavo por encima del saldo
--
-- `if p_monto > v_saldo + 0.01` admitía sobrepagar un centavo. El dinero se
-- lleva en centavos: la comparación se hace sobre importes ya redondeados y sin
-- holgura.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_base_registrar_pago(
  p_cuenta_id uuid,
  p_monto numeric,
  p_metodo_pago text,
  p_cuota_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_monto_total  numeric(15,2);
  v_estado       text;
  v_pagado       numeric(15,2);
  v_saldo        numeric(15,2);
  v_monto        numeric(15,2);
  v_pago_id      uuid;
  v_cuota_monto  numeric(15,2);
  v_cuota_pagado numeric(15,2);
  v_cuota_estado public.estado_cuota;
begin
  select monto_total, estado
    into v_monto_total, v_estado
    from public.cuentas
   where id = p_cuenta_id
     and deleted_at is null
   for update;

  if not found then
    raise exception 'No se encontró la cuenta solicitada.';
  end if;
  if v_estado in ('saldada', 'cancelada') then
    raise exception 'La cuenta no admite nuevos pagos porque está %.', v_estado;
  end if;
  if p_monto is null or p_monto <= 0 then
    raise exception 'El monto del pago debe ser mayor que cero.';
  end if;

  v_monto := round(p_monto, 2);

  select coalesce(sum(monto), 0)
    into v_pagado
    from public.pagos
   where cuenta_id = p_cuenta_id
     and estado = 'completado'
     and deleted_at is null;

  v_saldo := round(v_monto_total - v_pagado, 2);
  if v_monto > v_saldo then
    raise exception 'El monto del pago (%) excede el saldo pendiente (%).',
      v_monto, v_saldo;
  end if;

  if p_cuota_id is not null then
    select monto, monto_pagado, estado
      into v_cuota_monto, v_cuota_pagado, v_cuota_estado
      from public.cuotas
     where id = p_cuota_id
       and cuenta_id = p_cuenta_id
       and deleted_at is null
     for update;

    if not found then
      raise exception 'La cuota no pertenece a esta cuenta.';
    end if;
    if v_cuota_estado in ('pagada', 'cancelada') then
      raise exception 'La cuota no admite nuevos pagos porque está %.', v_cuota_estado;
    end if;
    if v_monto > round(v_cuota_monto - v_cuota_pagado, 2) then
      raise exception 'El monto del pago (%) excede el saldo de la cuota (%).',
        v_monto, round(v_cuota_monto - v_cuota_pagado, 2);
    end if;
  end if;

  begin
    insert into public.pagos (
      cuenta_id, cuota_id, monto, fecha, estado, metodo_pago,
      created_at, updated_at
    ) values (
      p_cuenta_id, p_cuota_id, v_monto, now(), 'completado',
      p_metodo_pago::public.metodo_pago, now(), now()
    ) returning id into v_pago_id;
  exception
    when invalid_text_representation then
      raise exception 'El método de pago no es válido.';
  end;

  if p_cuota_id is not null then
    update public.cuotas
       set monto_pagado = least(monto, monto_pagado + v_monto),
           estado = case
             when monto_pagado + v_monto >= monto then 'pagada'::public.estado_cuota
             when fecha_vencimiento < current_date then 'vencida'::public.estado_cuota
             else 'pendiente'::public.estado_cuota
           end,
           updated_at = now()
     where id = p_cuota_id;
  end if;

  if v_pagado + v_monto >= v_monto_total then
    update public.cuentas
       set estado = 'saldada', fecha_pago = now(), updated_at = now()
     where id = p_cuenta_id;
  else
    update public.cuentas
       set estado = 'pendiente', updated_at = now()
     where id = p_cuenta_id;
  end if;

  return v_pago_id;
end;
$$;

-- El trigger de exceso comparte la regla: sin holgura y sobre importes
-- redondeados.
create or replace function public.validar_monto_pago()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
  v_total   numeric(15,2);
  v_pagado  numeric(15,2);
  v_balance numeric(15,2);
begin
  if new.estado <> 'completado' or new.deleted_at is not null then
    return new;
  end if;

  select coalesce(monto_total, 0) into v_total
    from public.cuentas where id = new.cuenta_id;

  select coalesce(sum(monto), 0) into v_pagado
    from public.pagos
   where cuenta_id = new.cuenta_id
     and estado = 'completado'
     and deleted_at is null
     and id is distinct from new.id;

  v_balance := round(v_total - v_pagado, 2);

  if round(new.monto, 2) > v_balance then
    raise exception 'El monto del pago (%) excede el balance pendiente (%).',
      new.monto, v_balance;
  end if;

  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
revoke all on function public.hfx_base_anular_pago(uuid, text) from public, anon, authenticated;
grant execute on function public.hfx_base_anular_pago(uuid, text) to service_role;

revoke all on function public.anular_pago(uuid, text) from public, anon;
grant execute on function public.anular_pago(uuid, text) to authenticated, service_role;

commit;
