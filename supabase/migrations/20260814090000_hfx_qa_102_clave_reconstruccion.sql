-- HFX-QA-102 (continuación) · «Reconstrucción dental» también es una restauración.
--
-- Al aplicar `20260812090000` en producción, su informe listó 9 tratamientos
-- sin `clave_odontograma`. Ocho quedan fuera con razón —flúor, limpieza,
-- blanqueamiento, raspado, brackets, implante, prótesis y un dato de prueba: o
-- son de arcada/cuadrante, o no caben en el vocabulario cerrado del formulario
-- en papel—. El noveno no: «Reconstrucción dental» es trabajo restaurador sobre
-- una pieza, y sin clave no pintaba nada en el odontodiagrama.
--
-- No lo cazó el patrón porque busca `restaurac` y la palabra es `reconstrucc`.
-- Es exactamente para lo que servía el informe: se escribió para que un hueco
-- así se viera al aplicar, en vez de descubrirse meses después por un diagrama
-- vacío.

update public.tratamientos set clave_odontograma = 'restaurada'
 where clave_odontograma is null
   and deleted_at is null
   and translate(lower(nombre), 'áéíóúüñ', 'aeiouun') ~ 'reconstrucc|reconstruy';

do $$
declare
  v_sin_clave text;
  v_conteo    integer;
begin
  select count(*), string_agg(nombre, ', ' order by nombre)
    into v_conteo, v_sin_clave
    from public.tratamientos
   where clave_odontograma is null and deleted_at is null;
  raise notice 'HFX-QA-102: quedan % tratamiento(s) sin clave: %',
    v_conteo, coalesce(v_sin_clave, '(ninguno)');
end;
$$;
