import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';

/// Lo que el servidor confirmó de un guardado clínico.
///
/// Sellar estas identidades en memoria evita que el siguiente autoguardado
/// vuelva a insertar la misma marca dental con otro id, y la [version] es lo
/// que permite detectar que otra pestaña escribió primero.
class ResultadoBorradorConsulta {
  /// Versión de la consulta después de este guardado.
  final int? version;

  /// Momento en que el servidor confirmó el guardado.
  final DateTime? actualizadoEn;

  final Map<int, List<String>> tratamientosPorFdi;
  final Map<int, List<String>> diagnosticosPorFdi;

  /// Ids de receta en el mismo orden en que se enviaron.
  final List<String> recetaIds;

  /// Alertas vigentes que devolvió el motor tras aplicar el borrador
  /// (HFX-CLIN-003). Vienen del servidor porque las reglas viven allí.
  final List<AlertaClinica> alertas;

  const ResultadoBorradorConsulta({
    this.version,
    this.actualizadoEn,
    this.tratamientosPorFdi = const {},
    this.diagnosticosPorFdi = const {},
    this.recetaIds = const [],
    this.alertas = const [],
  });

  bool get sinIdentidades =>
      tratamientosPorFdi.isEmpty &&
      diagnosticosPorFdi.isEmpty &&
      recetaIds.isEmpty;

  factory ResultadoBorradorConsulta.fromRpc(Map<String, dynamic> json) {
    final tratamientos = <int, List<String>>{};
    final diagnosticos = <int, List<String>>{};

    for (final fila in (json['dientes'] as List? ?? const [])) {
      if (fila is! Map) continue;
      final fdi = (fila['fdi_code'] as num?)?.toInt();
      if (fdi == null) continue;
      tratamientos[fdi] = _ids(fila['tratamientos']);
      diagnosticos[fdi] = _ids(fila['diagnosticos']);
    }

    return ResultadoBorradorConsulta(
      version: (json['version'] as num?)?.toInt(),
      actualizadoEn: DateTime.tryParse(
        json['actualizado_en']?.toString() ?? '',
      ),
      tratamientosPorFdi: tratamientos,
      diagnosticosPorFdi: diagnosticos,
      recetaIds: [
        for (final receta in (json['recetas'] as List? ?? const []))
          if (receta is Map && receta['id'] != null) receta['id'].toString(),
      ],
      alertas: AlertaClinica.listaFromJson(json['alertas']),
    );
  }

  static List<String> _ids(dynamic valor) => [
    for (final id in (valor as List? ?? const []))
      if (id != null) id.toString(),
  ];
}
