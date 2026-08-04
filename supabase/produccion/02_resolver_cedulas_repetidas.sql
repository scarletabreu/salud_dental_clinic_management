-- Resolución de las cédulas repetidas de producción.
--
-- Se ejecuta UNA VEZ contra la instancia remota, antes de `supabase db push`.
-- HFX-CLIN-004 impone unicidad de cédula normalizada y se niega a hacerlo
-- mientras haya colisiones entre personas vivas.
--
-- Decisión del dueño de los datos (31 jul 2026): son personas distintas, no
-- fichas duplicadas, y ninguna se borra. Se corrige la cédula equivocada de una
-- de cada par y se le asigna una nueva **válida**.
--
-- Las cédulas nuevas se generaron con el mismo algoritmo que valida la
-- aplicación (`isValidCedula` en `lib/core/util/validators.dart`: módulo 10 de
-- la JCE, multiplicadores 1-2 alternos, suma múltiplo de 10) y se comprobó que
-- no chocan con ninguna cédula ya presente:
--
--     402-9000001-3   →  Alberto Garcia
--     402-9000002-1   →  Leonardo Abreu
--
-- No se toca ninguna otra cédula. Hay varias inválidas en producción
-- —`666-6666666-6`, `99999999999999`, `121-1212121-1`…— pero son únicas y no
-- bloquean nada: corregirlas sería reescribir datos sin que nadie lo haya
-- pedido.
--
-- Idempotente: se identifica a cada persona por su `id`, y sólo se actualiza si
-- la cédula sigue siendo la equivocada.

do $$
declare
  v_cambios integer := 0;
begin
  -- ---------------------------------------------------------------------
  -- Par 1 · 40218382360 — Alberto Garcia vs. ELias De la cruz
  -- ---------------------------------------------------------------------
  -- Personas distintas; la cédula mal escrita es la de Alberto. Se le cambia
  -- a él y ELias conserva la suya, que además es la ficha con más historia
  -- (47 citas, 28 consultas, 16 cuentas frente a 15, 5 y 2).
  update public.personas
     set cedula = '402-9000001-3', updated_at = now()
   where id = 'a2c972d1-c37f-4e90-abe1-413288b9f008'
     and cedula = '402-1838236-0';
  get diagnostics v_cambios = row_count;
  raise notice 'Alberto Garcia: % fila(s) actualizada(s).', v_cambios;

  -- ---------------------------------------------------------------------
  -- Par 2 · 40218321350 — Jake Abreu vs. Leonardo Abreu
  -- ---------------------------------------------------------------------
  -- Ninguna de las dos tiene actividad clínica (0 citas, 0 consultas, 0
  -- cuentas), así que el criterio es cuál mueve menos: Jake está registrado
  -- como paciente y Leonardo sólo existe como usuario, de modo que se cambia
  -- la de Leonardo.
  update public.personas
     set cedula = '402-9000002-1', updated_at = now()
   where id = '9d8dd49b-145d-46ba-87da-1ff2a7c3fc8f'
     and cedula = '40218321350';
  get diagnostics v_cambios = row_count;
  raise notice 'Leonardo Abreu: % fila(s) actualizada(s).', v_cambios;
end;
$$;

-- ---------------------------------------------------------------------------
-- Comprobación: ninguna cédula normalizada se repite entre personas vivas.
-- ---------------------------------------------------------------------------
-- Se verifica aquí y no sólo en HFX-CLIN-004 para que este script falle en el
-- sitio donde se puede entender el problema, en vez de arrastrarlo hasta una
-- migración a medio aplicar.
do $$
declare
  v_repetidas text;
begin
  select string_agg(norm, ', ')
    into v_repetidas
    from (
      select upper(regexp_replace(coalesce(cedula, ''), '[\s\-\._]', '', 'g')) as norm
        from public.personas
       where deleted_at is null
         and nullif(upper(regexp_replace(coalesce(cedula, ''), '[\s\-\._]', '', 'g')), '') is not null
       group by 1
      having count(*) > 1
    ) d;

  if v_repetidas is not null then
    raise exception
      'Siguen repetidas estas cédulas entre personas vivas: %', v_repetidas;
  end if;

  raise notice 'Sin cédulas repetidas entre personas vivas.';
end;
$$;
