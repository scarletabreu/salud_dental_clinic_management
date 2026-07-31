# HFX-CLIN-008 · La consulta nacía sin piezas y no se podía guardar

Fecha: 2026-07-31.
Rama: `hotfix`, sobre HFX-CLIN-007.

Encontrado usando la aplicación a mano contra el stack local, no por una
prueba. Es el defecto más grave del programa hasta ahora: **ninguna consulta
abierta desde una cita podía guardarse ni cerrarse.**

---

## Síntoma

Toda llamada a `guardar_borrador_consulta` y a `cerrar_consulta` respondía 400.
En pantalla, «No se pudo guardar el trabajo de esta consulta», con reintento
automático que volvía a fallar. En el log de Postgres:

```
ERROR: La pieza 11 no pertenece al odontograma de la consulta d98171c8-… (CL004)
```

## Causa

`crear_consulta_completa` materializa las piezas a partir de `p_dientes`, que
le llega **desde el cliente**. El camino antiguo (`CrearConsultaUseCase`) le
inyecta las 52 piezas FDI antes de llamar. El camino nuevo,
`iniciar_consulta_de_cita` (HFX-CLIN-004), no pasa por ese caso de uso:
`ConsultaCubit` construye la consulta inicial **sin odontograma**, así que
enviaba `[]` y la consulta nacía con odontograma y con cero dientes.

La pantalla, en cambio, dibuja las 52 piezas en memoria
(`_emitirConsultaNueva` → `kFdiTodas`). El odontograma se veía entero, se podía
marcar un diente, y cada guardado se estrellaba contra una fila inexistente.

## Por qué la certificación no lo vio

`abrir_consulta()` en `hfx_clin_006_lib.sh` llama así:

```bash
rpc "$token" iniciar_consulta_de_cita \
  "{\"p_cita_id\":\"$cita\",\"p_dientes\":$DENTICION_FDI}"
```

El arnés manda la dentición que el cliente no manda, y el resto de las pruebas
insertan sus `dientes` a mano. Las catorce jornadas ejercían un odontograma que
en la aplicación real nunca existía.

Es la misma lección de HFX-CLIN-007, en su forma más cara: **una prueba sólo
demuestra lo que realmente ejecuta.** Cuando el arnés rellena por el cliente lo
que el cliente debía rellenar, la prueba deja de hablar del producto.

## Corrección

La dentición completa deja de depender de lo que mande el cliente. La
invariante vive en la base, donde ningún camino puede saltársela:

- `hfx_clin_008_denticion_fdi()` y `hfx_clin_008_superficies_de(fdi)` — las 52
  piezas y el reparto de caras, espejo de `dientes_iniciales.dart`. Duplicar la
  numeración FDI en SQL es aceptable: es norma internacional, no decisión de
  producto.
- `hfx_clin_008_completar_odontograma(odontograma_id)` — materializa las piezas
  que falten con sus caras. Idempotente y aditiva: nunca toca una pieza
  existente, así que no puede borrar un hallazgo. No se expone por PostgREST.
- `hfx_base_crear_consulta_completa` la invoca tras aplicar `p_dientes`. Se
  eligió el cuerpo real y no los dos envoltorios (`crear_consulta_completa` de
  8 y 9 argumentos) para que valga por igual en todos los caminos.
- La migración repara los odontogramas ya creados vacíos, excluyendo las
  consultas finalizadas: su expediente está cerrado y añadirle piezas en blanco
  no lo mejora.

De paso, la cabecera del workspace (`workspace_consulta.dart`) desbordaba al
estrechar la ventana: los distintivos de estado pasaron a un `Wrap` flexible y
los títulos llevan `ellipsis`.

## Cobertura nueva

`supabase/tests/hfx_clin_008_odontograma_completo_test.sql`, 5 comprobaciones.
Llama a `iniciar_consulta_de_cita` **sin dientes**, como llama la aplicación:

1. La consulta nace con las 52 piezas correctas y sus 260 caras.
2. El reparto de caras respeta la anatomía (interna palatina/lingual, quinta
   incisal/oclusal), no un valor por defecto.
3. Se puede anotar un diagnóstico sobre la pieza 11 y guardarlo — la
   comprobación que reproduce el defecto.
4. Completar dos veces no duplica piezas ni pierde anotaciones.
5. Completar un odontograma no es una capacidad del cliente.

La prueba se verificó en negativo: neutralizando la corrección, falla con «la
consulta nació con 0 piezas en vez de 52».

## Validación

- 13 suites SQL, todas en verde (incluida la nueva).
- 765 pruebas Dart aprobadas.
- `flutter analyze`: 0 errores, 0 advertencias, 129 info.
- Verificado contra la base viva: el odontograma de la consulta que falló quedó
  con 52 piezas y 260 caras, con el reparto correcto en 11, 18, 38, 51 y 75.

Pendiente: la certificación completa (`hfx_clin_006_certificacion.sh`) no se ha
vuelto a correr porque hace `supabase db reset` y había una sesión de pruebas
manuales en curso.
