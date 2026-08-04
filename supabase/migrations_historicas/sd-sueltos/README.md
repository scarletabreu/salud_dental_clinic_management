# Scripts `sd-*.sql` — residuo histórico, NO ejecutar

Estos diez scripts vivían sueltos en `supabase/`, fuera del flujo de
`supabase/migrations/`. **Ya no falta ninguno en ningún ambiente**: todo lo que
hacían está incorporado a la línea base (`20260725000000_linea_base.sql`, 5.158
líneas, más `20260725000100_linea_base_objetos_no_public.sql`) y a las
migraciones HFX/QA que van encima.

Se archivan aquí, y no se borran, porque son el registro de cómo llegó el
esquema a donde está.

## Por qué no se ejecutan

El audit del 2 ago 2026 (F5-08) los señaló como un riesgo humano, no técnico:
varias notas del proyecto todavía dicen «falta correr X», y **ejecutarlos a mano
sobre una base ya migrada es una de las fuentes de drift que este proyecto ya
sufrió**. Un ambiente nuevo se levanta con `supabase db reset`, que aplica
`migrations/` en orden; nada de esta carpeta entra en ese flujo.

Si alguna vez hace falta reintroducir algo de aquí, va como una migración nueva
en `supabase/migrations/`, con su fecha y su explicación.
