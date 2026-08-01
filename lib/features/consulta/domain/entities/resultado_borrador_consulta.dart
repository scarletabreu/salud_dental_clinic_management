import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

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

  /// Lo registrado sin pieza, tal como quedó en el servidor tras el guardado.
  ///
  /// A diferencia de las marcas de pieza —cuyos ids el RPC devuelve en el
  /// orden en que se enviaron— estas filas se releen enteras. La RPC no
  /// devuelve sus ids, así que sin esto cada autoguardado las anulaba y las
  /// reinsertaba con identidad nueva (defecto D5). Releerlas es una consulta
  /// de dos filas y deja la identidad donde manda: en la base.
  final List<TratamientoAplicado> tratamientosGenerales;
  final List<DiagnosticoAplicado> diagnosticosGenerales;

  /// `true` si los generales de arriba vienen del servidor. Se distingue de
  /// «vinieron vacíos» para no borrar en memoria lo que sólo no se pudo releer.
  final bool generalesConfirmados;

  const ResultadoBorradorConsulta({
    this.version,
    this.actualizadoEn,
    this.tratamientosPorFdi = const {},
    this.diagnosticosPorFdi = const {},
    this.recetaIds = const [],
    this.alertas = const [],
    this.tratamientosGenerales = const [],
    this.diagnosticosGenerales = const [],
    this.generalesConfirmados = false,
  });

  ResultadoBorradorConsulta conGenerales({
    required List<TratamientoAplicado> tratamientos,
    required List<DiagnosticoAplicado> diagnosticos,
  }) => ResultadoBorradorConsulta(
    version: version,
    actualizadoEn: actualizadoEn,
    tratamientosPorFdi: tratamientosPorFdi,
    diagnosticosPorFdi: diagnosticosPorFdi,
    recetaIds: recetaIds,
    alertas: alertas,
    tratamientosGenerales: tratamientos,
    diagnosticosGenerales: diagnosticos,
    generalesConfirmados: true,
  );

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
