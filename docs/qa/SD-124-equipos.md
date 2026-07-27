# Validación de equipos — SD-124

## Ciclo 1

| Hallazgo | Impacto | Resolución | Estado |
| --- | --- | --- | --- |
| El destino **Equipos** solo proveía `EquipoCubit`, aunque al pulsar **Registrar mantenimiento** la pantalla requiere `SuplidorCubit` para cargar el directorio. | El flujo fallaba con `ProviderNotFoundException` antes de mostrar el formulario. | El destino ahora provee ambos cubits y se añadió una prueba de widget para abrir y completar el registro. | Corregido |

## Alcance de la repetición

- Listado y búsqueda de equipos.
- Alta, edición y eliminación mediante el cubit.
- Apertura, validaciones y envío del formulario de mantenimiento.
- Cálculo de vencimiento y alerta operativa.
- Diseño responsive de 320 px a escritorio.
