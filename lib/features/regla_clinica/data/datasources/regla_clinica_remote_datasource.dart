abstract class ReglaClinicaRemoteDatasource {
  /// Reglas no retiradas, con la marca de cuáles admiten umbral editable.
  Future<List<Map<String, dynamic>>> fetchReglasVigentes();

  /// Catálogo de signos vitales: qué se mide, en qué unidad y en qué rango es
  /// físicamente posible.
  Future<List<Map<String, dynamic>>> fetchCatalogoSignosVitales();

  /// Publica una versión nueva de la regla y retira la anterior.
  Future<Map<String, dynamic>> publicarRegla({
    required String codigo,
    required Map<String, dynamic> parametros,
    String? severidad,
    String? accion,
    String? nota,
  });
}
