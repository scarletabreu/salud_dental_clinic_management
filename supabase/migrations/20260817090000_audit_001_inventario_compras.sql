-- Audit 2026-08-02 · Frente inventario y compras (I1, I2, I5, I6).
--
-- El módulo de compras no funcionaba en ninguna instancia: la función que
-- recibe una compra escribía un motivo de stock que el CHECK de su propia
-- tabla rechaza, el enum de estados de la base no coincidía con el del
-- cliente, la compra se creaba en dos escrituras sin transacción y el egreso
-- se cargaba contra cualquier caja abierta —regla distinta a la que exigen los
-- pagos—.

begin;

-- ---------------------------------------------------------------------------
-- I1 · «Recibir compra» contra su propio CHECK
--
-- `hfx_base_recibir_compra` inserta el movimiento de stock con
-- motivo='compra_recibida' desde 20260811090000, pero el CHECK de la línea
-- base sólo admitía los cuatro motivos de ajuste manual. Cada clic en
-- «Recibir» respondía 23514 y el stock nunca subía por una compra.
--
-- Se admite el motivo en vez de cambiar la función: recibir una compra es un
-- movimiento de stock legítimo y distinto de un ajuste, y el historial tiene
-- que poder decir de dónde vino cada unidad.
-- ---------------------------------------------------------------------------
alter table public.movimientos_stock_consumible
  drop constraint if exists movimientos_stock_consumible_motivo_check;

alter table public.movimientos_stock_consumible
  add constraint movimientos_stock_consumible_motivo_check
  check (motivo = any (array[
    'merma'::text,
    'correccion'::text,
    'usoInterno'::text,
    'consumoClinico'::text,
    'compra_recibida'::text
  ]));

comment on constraint movimientos_stock_consumible_motivo_check
  on public.movimientos_stock_consumible is
  'Motivos válidos. `compra_recibida` sólo lo escribe hfx_base_recibir_compra; '
  '`consumoClinico`, el cierre de consulta; el resto, ajustar_stock_consumible.';

-- ---------------------------------------------------------------------------
-- I2 · El enum `estado_compra` tenía etiquetas duplicadas y el cliente escribía
-- otras que no existen
--
-- Etiquetas reales antes de esta migración: pendiente, completada, cancelada,
-- recibida, envíada, recibido. `completada` y `recibido` son sinónimos
-- históricos de `recibida`. No se pueden borrar etiquetas de un enum en
-- Postgres, así que se normalizan los datos y un CHECK impide volver a
-- escribirlas: quedan como legado imposible de producir.
-- ---------------------------------------------------------------------------
update public.compras
   set estado = 'recibida'::estado_compra,
       updated_at = now()
 where estado in ('completada'::estado_compra, 'recibido'::estado_compra);

alter table public.compras
  drop constraint if exists compras_estado_canonico;

alter table public.compras
  add constraint compras_estado_canonico
  check (estado = any (array[
    'pendiente'::estado_compra,
    'envíada'::estado_compra,
    'recibida'::estado_compra,
    'cancelada'::estado_compra
  ]));

comment on constraint compras_estado_canonico on public.compras is
  'Las etiquetas `completada` y `recibido` del enum son legado sinónimo de '
  '`recibida`; este CHECK impide reintroducirlas. `envíada` conserva la tilde '
  'porque así nació el enum y añadir un sinónimo limpio repetiría el defecto.';

-- ---------------------------------------------------------------------------
-- Hallazgo nuevo · Un segundo camino sumaba el stock por fuera del libro
--
-- `tr_actualizar_stock_al_recibir` (AFTER UPDATE sobre `compras`) sumaba la
-- cantidad comprada directamente a `consumibles.stock_actual` cuando el estado
-- pasaba a `'recibida'`, **sin dejar asiento** en `movimientos_stock_consumible`.
--
-- Nunca se había visto porque `hfx_base_recibir_compra` escribía `'recibido'`
-- —la otra etiqueta del enum— y la condición del trigger no casaba jamás. En
-- cuanto la recepción escribe la etiqueta canónica, el stock sube **dos veces**:
-- una por el movimiento y otra por este trigger. Se destapó al probar la
-- corrección de I1: siete unidades compradas subían el stock en catorce.
--
-- Se retira. Desde HFX-CLIN-007 el stock sólo se mueve por el libro de
-- movimientos, que es lo que deja rastro de quién y por qué.
-- ---------------------------------------------------------------------------
drop trigger if exists tr_actualizar_stock_al_recibir on public.compras;
drop function if exists public.actualizar_stock_por_compra();

-- ---------------------------------------------------------------------------
-- I5 · Crear una compra dejaba de ser atómico a mitad
--
-- El cliente insertaba la cabecera y después los renglones. Si la segunda
-- escritura fallaba quedaba una compra sin renglones, y una compra sin
-- renglones se «recibe» sin mover nada: el monto sale 0 y se marca recibida
-- igual.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_base_crear_compra(p_items jsonb)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_compra_id uuid;
  v_item      jsonb;
begin
  if p_items is null
     or jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0 then
    raise exception 'Una compra necesita al menos un artículo.'
      using errcode = '22023';
  end if;

  insert into compras (estado, fecha, created_at, updated_at)
  values ('pendiente'::estado_compra, now(), now(), now())
  returning id into v_compra_id;

  for v_item in select value from jsonb_array_elements(p_items)
  loop
    insert into consumibles_compras (
      compra_id, consumible_id, suplidor_id, cantidad, precio_unitario,
      created_at, updated_at
    ) values (
      v_compra_id,
      (v_item ->> 'consumible_id')::uuid,
      (v_item ->> 'suplidor_id')::uuid,
      (v_item ->> 'cantidad')::integer,
      (v_item ->> 'precio_unitario')::numeric,
      now(), now()
    );
  end loop;

  return v_compra_id;
end;
$$;

create or replace function public.crear_compra(p_items jsonb)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.es_contexto_interno()
     and (auth.uid() is null or not public.es_admin()) then
    raise exception 'Capacidad de compras requerida.' using errcode = '42501';
  end if;
  return public.hfx_base_crear_compra(p_items);
end;
$$;

-- ---------------------------------------------------------------------------
-- I1 + I6 · Recepción de compra: estado canónico, caja del día y método real
--
-- I6: el egreso se cargaba contra «la última caja abierta», sin mirar el día,
-- mientras el trigger de pagos exige la caja de la fecha civil de Santo
-- Domingo. Ingresos y egresos elegían cajas distintas: una compra recibida el
-- sábado descontaba de la caja del viernes que nadie cerró.
--
-- El método de pago se registraba siempre como efectivo, fuese cual fuese.
-- ---------------------------------------------------------------------------
create or replace function public.hfx_base_recibir_compra(
  p_compra_id uuid,
  p_usuario_id uuid,
  p_metodo_pago text default 'efectivo'
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_caja_id      uuid;
  v_monto_total  numeric(12,2);
  v_estado       text;
  v_renglones    integer;
  v_item         record;
  v_zona constant text := 'America/Santo_Domingo';
begin
  select estado::text into v_estado
    from compras
   where id = p_compra_id and deleted_at is null
   for update;

  if not found then
    raise exception 'La compra especificada no existe.' using errcode = 'P0002';
  end if;

  if v_estado in ('recibido', 'recibida', 'completada') then
    raise exception 'Esta compra ya fue recibida anteriormente.'
      using errcode = '22023';
  end if;

  if v_estado = 'cancelada' then
    raise exception 'Una compra cancelada no puede recibirse.'
      using errcode = '22023';
  end if;

  -- Una compra sin renglones no mueve stock ni dinero: marcarla recibida sólo
  -- serviría para esconder que quedó a medias al crearse.
  select count(*), coalesce(sum(cantidad * precio_unitario), 0)
    into v_renglones, v_monto_total
    from consumibles_compras
   where compra_id = p_compra_id
     and deleted_at is null;

  if v_renglones = 0 then
    raise exception 'La compra no tiene artículos; no puede recibirse.'
      using errcode = '22023';
  end if;

  -- Misma regla que el trigger de pagos: la caja de HOY en hora de Santo
  -- Domingo. Antes bastaba «cualquier caja abierta», así que el egreso de una
  -- compra podía caer en la caja de otro día mientras el cobro de ese mismo
  -- día lo rechazaba.
  if v_monto_total > 0 then
    select id into v_caja_id
      from cajas
     where cerrada = false
       and (fecha at time zone v_zona)::date
         = (current_timestamp at time zone v_zona)::date
     limit 1
     for update;

    if v_caja_id is null then
      raise exception
        'No hay una caja abierta para hoy. Abre la caja antes de recibir la compra.'
        using errcode = 'P0001';
    end if;
  end if;

  update compras
     set estado = 'recibida'::estado_compra,
         updated_at = now()
   where id = p_compra_id;

  -- El trigger fn_aplicar_movimiento_stock calcula stock_anterior/stock_nuevo
  -- bajo lock y actualiza consumibles.stock_actual.
  for v_item in
    select consumible_id, sum(cantidad) as cantidad
      from consumibles_compras
     where compra_id = p_compra_id
       and deleted_at is null
     group by consumible_id
  loop
    -- `stock_anterior` y `stock_nuevo` los rellena el trigger BEFORE INSERT con
    -- la fila del consumible bloqueada; escribirlos aquí sería adivinar.
    insert into movimientos_stock_consumible (
      consumible_id, diferencia, motivo, creado_por
    ) values (
      v_item.consumible_id, v_item.cantidad, 'compra_recibida', p_usuario_id
    );
  end loop;

  if v_monto_total > 0 then
    insert into movimientos_caja (
      caja_diaria_id, tipo, monto, descripcion, metodo_pago, referencia_id,
      fecha, created_at
    ) values (
      v_caja_id,
      'egreso',
      v_monto_total,
      'Pago por recepción de compra #' || substring(p_compra_id::text, 1, 8),
      coalesce(nullif(btrim(p_metodo_pago), ''), 'efectivo'),
      p_compra_id,
      now(),
      now()
    );

    update cajas
       set monto_esperado = coalesce(monto_esperado, 0) - v_monto_total,
           updated_at = now()
     where id = v_caja_id;
  end if;
end;
$$;

-- La firma de dos argumentos queda retirada: dejarla viva repetiría el drift de
-- sobrecargas que este mismo audit señala (F5-03).
drop function if exists public.hfx_base_recibir_compra(uuid, uuid);

create or replace function public.recibir_compra(
  p_compra_id uuid,
  p_usuario_id uuid,
  p_metodo_pago text default 'efectivo'
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if not public.es_contexto_interno()
     and (
       auth.uid() is null
       or not (public.es_admin() or public.es_asistente())
     ) then
    raise exception 'Capacidad de compras requerida.' using errcode = '42501';
  end if;
  if not public.es_contexto_interno()
     and p_usuario_id is distinct from auth.uid() then
    raise exception 'El actor de la compra no coincide con la sesión.'
      using errcode = '42501';
  end if;
  perform public.hfx_base_recibir_compra(p_compra_id, p_usuario_id, p_metodo_pago);
end;
$$;

drop function if exists public.recibir_compra(uuid, uuid);

-- ---------------------------------------------------------------------------
-- Grants: las `hfx_base_*` no son alcanzables desde el cliente; sólo sus
-- envoltorios con guardia. Los defaults de Postgres publican toda función nueva
-- a `public`, así que hay que revocarlo explícitamente.
-- ---------------------------------------------------------------------------
revoke all on function public.hfx_base_crear_compra(jsonb) from public, anon, authenticated;
revoke all on function public.hfx_base_recibir_compra(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.hfx_base_crear_compra(jsonb) to service_role;
grant execute on function public.hfx_base_recibir_compra(uuid, uuid, text) to service_role;

revoke all on function public.crear_compra(jsonb) from public, anon;
revoke all on function public.recibir_compra(uuid, uuid, text) from public, anon;
grant execute on function public.crear_compra(jsonb) to authenticated, service_role;
grant execute on function public.recibir_compra(uuid, uuid, text) to authenticated, service_role;

commit;
