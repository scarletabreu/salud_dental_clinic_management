-- HFX-CLIN-007 · las RPC dejan de ser opcionales.
-- Se ejecuta tras `supabase db reset` y revierte todos sus datos.
--
--   psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/hfx_clin_007_escrituras_directas_test.sql

begin;
set local role postgres;

-- ---------------------------------------------------------------------------
-- 1 · El cliente no puede cerrar una consulta escribiendo la columna
-- ---------------------------------------------------------------------------
-- Se comprueba sobre los privilegios y no haciendo un `set role`, porque lo que
-- se quiere demostrar es precisamente lo que PostgREST le concede al rol
-- `authenticated`. Si alguien vuelve a conceder `update` de tabla, esto se cae.
do $$
declare
  v_prohibidas constant text[] := array[
    'finalizada', 'finalizada_at', 'cerrada_por', 'cierre_key', 'version'
  ];
  v_col text;
  v_permitidas text[];
begin
  if has_table_privilege('authenticated', 'public.consultas', 'update') then
    -- `has_table_privilege` con 'update' es cierto si hay privilegio sobre
    -- *cualquier* columna, así que sólo interesa el detalle por columna.
    null;
  end if;

  foreach v_col in array v_prohibidas loop
    if has_column_privilege('authenticated', 'public.consultas', v_col, 'update') then
      raise exception
        'authenticated todavía puede escribir consultas.%: una consulta se podría cerrar con un PATCH',
        v_col;
    end if;
  end loop;

  -- Y lo que sí necesita seguir escribiendo, sigue escribiéndose: la app anota
  -- los signos vitales por esta vía justo después de crear la consulta.
  select array_agg(c)
    into v_permitidas
    from unnest(array['signos_vitales', 'notas', 'motivo_consulta']) c
   where not has_column_privilege('authenticated', 'public.consultas', c, 'update');

  if v_permitidas is not null then
    raise exception 'se revocó de más en consultas: %', v_permitidas;
  end if;

  raise notice 'OK 1 · las columnas de cierre no son escribibles y las clínicas sí';
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · El libro de inventario sólo lo escriben las RPC
-- ---------------------------------------------------------------------------
do $$
begin
  if has_table_privilege(
       'authenticated', 'public.movimientos_stock_consumible', 'insert') then
    raise exception
      'authenticated puede insertar movimientos de stock: puede mover el inventario a voluntad';
  end if;

  if exists (
    select 1 from pg_policies
     where schemaname = 'public'
       and tablename = 'movimientos_stock_consumible'
       and cmd = 'INSERT'
  ) then
    raise exception 'sigue habiendo una política de INSERT en el libro de stock';
  end if;

  -- La lectura se conserva: el historial se muestra en pantalla.
  if not has_table_privilege(
       'authenticated', 'public.movimientos_stock_consumible', 'select') then
    raise exception 'se revocó también la lectura del historial de movimientos';
  end if;

  -- El stock del consumible no se escribe a mano por ninguna vía de cliente.
  if has_column_privilege(
       'authenticated', 'public.consumibles', 'stock_actual', 'update') then
    raise exception
      'authenticated puede escribir consumibles.stock_actual y descuadrarlo del libro';
  end if;
  if has_column_privilege(
       'authenticated', 'public.consumibles', 'estado', 'update') then
    raise exception 'authenticated puede escribir consumibles.estado a mano';
  end if;
  if not has_column_privilege(
       'authenticated', 'public.consumibles', 'stock_minimo', 'update') then
    raise exception 'el administrador ya no puede editar el stock mínimo';
  end if;

  raise notice 'OK 2 · el inventario sólo se mueve por el libro, y el libro por las RPC';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · Todo movimiento deja el estado del consumible al día
-- ---------------------------------------------------------------------------
-- Es el defecto que dejaba ciegos los avisos de stock: `cerrar_consulta` movía
-- `stock_actual` sin tocar `estado`, así que un consumible consumido hasta cero
-- seguía marcado «disponible».
do $$
declare
  v_sup  uuid;
  v_cons uuid;
  v_estado public.estado_consumible;
begin
  insert into public.suplidores (nombre, tipo_suplidor)
  values ('HFX007 Suplidor', 'consumible')
    returning id into v_sup;

  insert into public.consumibles (
    nombre, descripcion, stock_actual, stock_minimo, estado, precio, suplidor_id
  ) values (
    'HFX007 Gasa', 'para la prueba', 10, 3, 'disponible', 5.00, v_sup
  ) returning id into v_cons;

  -- Baja hasta el mínimo: pasa a bajo_stock sin que nadie lo calcule fuera.
  insert into public.movimientos_stock_consumible (
    consumible_id, diferencia, motivo
  ) values (v_cons, -7, 'correccion');

  select estado into v_estado from public.consumibles where id = v_cons;
  if v_estado <> 'bajo_stock' then
    raise exception 'con 3 de 3 el estado quedó en % en vez de bajo_stock', v_estado;
  end if;

  -- Hasta cero: agotado.
  insert into public.movimientos_stock_consumible (
    consumible_id, diferencia, motivo
  ) values (v_cons, -3, 'correccion');

  select estado into v_estado from public.consumibles where id = v_cons;
  if v_estado <> 'agotado' then
    raise exception 'con 0 el estado quedó en % en vez de agotado', v_estado;
  end if;

  -- Y una reposición lo devuelve a disponible: el recálculo va en las dos
  -- direcciones, no sólo al consumir.
  insert into public.movimientos_stock_consumible (
    consumible_id, diferencia, motivo
  ) values (v_cons, 20, 'correccion');

  select estado into v_estado from public.consumibles where id = v_cons;
  if v_estado <> 'disponible' then
    raise exception 'tras reponer el estado quedó en % en vez de disponible', v_estado;
  end if;

  raise notice 'OK 3 · el estado del consumible sigue a su stock en toda vía';
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · El tipo de sangre que envía la aplicación es válido
-- ---------------------------------------------------------------------------
-- La grafía es contrato entre el enum de Dart y el de Postgres. La aplicación
-- enviaba `name` (camelCase) y el cast reventaba con 22P02, tumbando entera la
-- transacción de `registrar_paciente`: ninguna alta llegaba a completarse.
-- Estas son exactamente las cadenas que produce `TipoSangre.dbValue`.
do $$
declare
  v_etiqueta text;
begin
  foreach v_etiqueta in array array[
    'a_positivo', 'a_negativo', 'b_positivo', 'b_negativo',
    'ab_positivo', 'ab_negativo', 'o_positivo', 'o_negativo', 'desconocido'
  ] loop
    begin
      perform v_etiqueta::public.tipo_sangre;
    exception when others then
      raise exception 'la app enviaría «%», que el enum tipo_sangre rechaza', v_etiqueta;
    end;
  end loop;

  -- Y la grafía vieja sigue siendo inválida: si algún día vuelve a colarse un
  -- `.name`, esta prueba lo dice en vez de dejarlo fallar en producción.
  begin
    perform 'oPositivo'::public.tipo_sangre;
    raise exception 'el enum aceptó camelCase: la prueba ya no demuestra nada';
  exception when invalid_text_representation then
    null;
  end;

  raise notice 'OK 4 · las nueve etiquetas de TipoSangre.dbValue son válidas';
end;
$$;

rollback;
