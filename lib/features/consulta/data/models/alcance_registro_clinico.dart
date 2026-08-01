/// Decide si una fila aplicada debe leerse fuera de una pieza.
///
/// La columna normalizada es el alcance del catálogo. `diente_id IS NULL` se
/// conserva como respaldo para filas históricas cuyo catálogo cambió o ya no
/// está disponible. Esto permite leer correctamente los registros anteriores
/// a HFX-CLIN-003, cuando la base todavía aceptaba procedimientos de arcada o
/// globales pegados a una pieza.
bool registroClinicoEsGeneral(
  Map<String, dynamic> fila, {
  required String catalogoKey,
}) {
  if (fila['diente_id'] == null) return true;

  final rawCatalogo = fila[catalogoKey];
  if (rawCatalogo is! Map) return false;
  final alcance = rawCatalogo['alcance']?.toString().toLowerCase();
  return alcance == 'arcada' || alcance == 'global';
}
