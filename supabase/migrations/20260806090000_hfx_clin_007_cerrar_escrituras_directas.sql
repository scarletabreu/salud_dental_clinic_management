-- HFX-CLIN-007 · cerrar las escrituras directas que dejaban las RPC opcionales.
--
-- HFX-CLIN-001 y 002 endurecieron el `execute` de las funciones y reescribieron
-- las políticas RLS, pero no revocaron los `grant all ... to authenticated` de
-- tabla que venía arrastrando la línea base. PostgREST expone esas tablas
-- directamente, así que cada invariante que las RPC defienden —el bloqueo
-- optimista, el libro de inventario, la facturación, las barreras de cierre—
-- era, desde el cliente, opcional. La propia migración de HFX-CLIN-002 declara
-- que «la escritura pasa exclusivamente por las RPC de esta migración»: esto es
-- lo que hacía falta para que fuese cierto.
--
-- Se usan privilegios por columna en vez de un trigger de guarda porque
-- `es_contexto_interno()` es falso dentro de una RPC llamada por PostgREST
-- —`session_user` sigue siendo `authenticator`, tal como advierte el comentario
-- de HFX-CLIN-001—, de modo que un trigger con esa condición habría bloqueado
-- el cierre legítimo. Las RPC son `security definer` y pertenecen a `postgres`,
-- así que los privilegios de `authenticated` no las afectan.

-- ---------------------------------------------------------------------------
-- 1 · El estado del consumible se recalcula en el libro, no en cada llamador
-- ---------------------------------------------------------------------------
-- `cerrar_consulta` movía `stock_actual` sin tocar `estado`, así que un
-- consumible consumido hasta cero seguía marcado «disponible» y los avisos de
-- stock bajo quedaban ciegos. El único sitio que lo recalculaba era el ajuste
-- manual del administrador. Al bajarlo al trigger que aplica cada movimiento,
-- toda vía —cierre de consulta, ajuste manual y `recibir_compra`— queda
-- cubierta por construcción.
create or replace function public.fn_aplicar_movimiento_stock()
returns trigger
language plpgsql
as $$
declare
  v_stock_actual int;
  v_stock_nuevo  int;
  v_stock_minimo int;
begin
  select stock_actual, stock_minimo
    into v_stock_actual, v_stock_minimo
    from public.consumibles
   where id = new.consumible_id
     for update; -- bloquea la fila mientras se calcula: evita la carrera con
                 -- otro movimiento simultáneo sobre el mismo consumible.

  if v_stock_actual is null then
    raise exception 'Consumible % no existe', new.consumible_id;
  end if;

  v_stock_nuevo := greatest(v_stock_actual + new.diferencia, 0);

  new.stock_anterior := v_stock_actual;
  new.stock_nuevo := v_stock_nuevo;

  update public.consumibles
     set stock_actual = v_stock_nuevo,
         estado = case
           when v_stock_nuevo <= 0 then 'agotado'::public.estado_consumible
           when v_stock_nuevo <= coalesce(v_stock_minimo, 0)
             then 'bajo_stock'::public.estado_consumible
           else 'disponible'::public.estado_consumible
         end,
         updated_at = now()
   where id = new.consumible_id;

  return new;
end;
$$;

alter function public.fn_aplicar_movimiento_stock() owner to postgres;

comment on function public.fn_aplicar_movimiento_stock() is
  'Aplica el movimiento bajo lock y recalcula el estado del consumible. '
  'HFX-CLIN-007: el estado vive aquí para que ninguna vía de consumo lo olvide.';

-- Reparar lo que ya quedó desalineado por los cierres anteriores.
update public.consumibles
   set estado = case
         when stock_actual <= 0 then 'agotado'::public.estado_consumible
         when stock_actual <= coalesce(stock_minimo, 0)
           then 'bajo_stock'::public.estado_consumible
         else 'disponible'::public.estado_consumible
       end
 where deleted_at is null
   and estado is distinct from case
         when stock_actual <= 0 then 'agotado'::public.estado_consumible
         when stock_actual <= coalesce(stock_minimo, 0)
           then 'bajo_stock'::public.estado_consumible
         else 'disponible'::public.estado_consumible
       end
   and estado <> 'descontinuado'::public.estado_consumible;

-- ---------------------------------------------------------------------------
-- 2 · El libro de inventario deja de ser escribible desde el cliente
-- ---------------------------------------------------------------------------
-- `authenticated_adjust_stock_consumible` era `for insert with check (true)`:
-- cualquier usuario autenticado —incluida una asistente, que no tiene ninguna
-- capacidad de inventario— podía escribir el libro y mover el stock a voluntad.
--
-- Peor todavía: HFX-CLIN-002 añadió `consulta_id` y un índice único por
-- `(consulta_id, consumible_id)`, y `cerrar_consulta` inserta el consumo real
-- con `on conflict do nothing`. Insertando antes una fila con ese `consulta_id`
-- y `diferencia = 0` se conseguía que el cierre **saltara el descuento en
-- silencio**: paciente facturado, inventario intacto y un asiento de aspecto
-- legítimo en la auditoría.
drop policy if exists authenticated_adjust_stock_consumible
  on public.movimientos_stock_consumible;

revoke insert, update, delete, truncate, references
  on public.movimientos_stock_consumible from authenticated;

-- La lectura se conserva: el historial de movimientos se muestra en pantalla y
-- su política de SELECT sigue mandando quién ve qué.

-- El stock sólo se mueve por el libro, nunca escribiendo la columna a mano.
-- `stock_actual` y `estado` los mantiene el trigger de arriba; dejarlos
-- escribibles permitía descuadrar el consumible respecto de sus movimientos sin
-- dejar rastro.
revoke update on public.consumibles from authenticated;
grant update (
  nombre, descripcion, stock_minimo, precio,
  suplidor_id, activo, updated_at, deleted_at
) on public.consumibles to authenticated;

-- ---------------------------------------------------------------------------
-- 3 · Una consulta no se cierra con un PATCH
-- ---------------------------------------------------------------------------
-- `consulta_update` sólo comprueba `doctor_id = auth.uid()` en su `with check`,
-- y un `with check` no distingue qué columna cambió. Con `grant all` de tabla,
-- un doctor podía hacer `PATCH {"finalizada": true}` sobre su propia consulta y
-- darla por cerrada: sin cuenta, sin descuento de inventario, sin pasar las
-- barreras clínicas y sin asiento `consulta_cerrada` en la auditoría.
--
-- Y quedaba peor de lo que parece: al no escribirse `cierre_key`, un
-- `cerrar_consulta` posterior encontraba `finalizada = true` con clave nula y
-- devolvía éxito, dejando la consulta permanentemente sin facturar.
--
-- `version` entra en la lista prohibida por el mismo motivo: es el bloqueo
-- optimista, y un cliente que pudiera reescribirlo podría pisar el guardado de
-- otra pestaña sin recibir `CL001`.
revoke update on public.consultas from authenticated;
grant update (
  motivo_consulta, notas, signos_vitales, temp_condiciones,
  tipo_atencion, fecha, updated_at, deleted_at
) on public.consultas to authenticated;

comment on column public.consultas.cierre_key is
  'Clave de idempotencia del cierre. HFX-CLIN-007: junto con finalizada, '
  'finalizada_at, cerrada_por y version, no es escribible por authenticated; '
  'sólo la escribe cerrar_consulta.';
