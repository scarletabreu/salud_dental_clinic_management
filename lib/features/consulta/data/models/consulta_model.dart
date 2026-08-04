import 'package:salud_dental_clinic_management/features/condicion/data/models/condicion_model.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/models/diagnostico_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/models/documento_clinico_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/models/odontograma_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

class ConsultaModel extends Consulta {
  ConsultaModel({
    super.id,
    required super.pacienteId,
    required super.doctorId,
    super.citaId,
    required super.fecha,
    super.recetas,
    super.documentosClinicos,
    super.odontograma,
    super.tempCondiciones,
    super.motivoConsulta,
    super.notas,
    super.signosVitales,
    super.finalizada,
    super.tipoAtencion,
    super.tienePreFactura,
    super.version,
    super.insumosUtilizados,
    super.tratamientosGenerales,
    super.diagnosticosGenerales,
    super.condicionesDetectadas,
    super.alertas,
  });

  factory ConsultaModel.fromJson(Map<String, dynamic> json) {
    return ConsultaModel(
      id: json['id'] as String?,
      pacienteId: (json['paciente_id'] ?? json['pacienteId'] ?? '') as String,
      doctorId: (json['doctor_id'] ?? json['doctorId'] ?? '') as String,
      citaId: json['cita_id'] ?? json['citaId'],
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      motivoConsulta: json['motivo_consulta'] ?? json['motivoConsulta'],
      notas: json['notas'] as String?,
      finalizada: (json['finalizada'] ?? false) as bool,
      tipoAtencion: TipoAtencionClinica.fromDb(
        json['tipo_atencion'] as String?,
      ),
      signosVitales: _parseSignosVitales(json),
      condicionesDetectadas: _parseCondiciones(json),
      alertas: _parseAlertas(json),
      recetas: json['recetas'] != null
          ? (json['recetas'] as List)
                .map((x) => RecetaModel.fromJson(x))
                .toList()
          : [],
      documentosClinicos: json['documentos_clinicos'] != null
          ? (json['documentos_clinicos'] as List)
                .map((x) => DocumentoClinicoModel.fromJson(x))
                .toList()
          : [],
      odontograma: _parseOdontograma(json['odontograma']),
      tempCondiciones: json['temp_condiciones'] != null
          ? List<String>.from(json['temp_condiciones'])
          : [],
      tienePreFactura:
          (json['tiene_pre_factura'] ?? json['tienePreFactura'] ?? false)
              as bool,
      version: (json['version'] as num?)?.toInt(),
      insumosUtilizados: [
        for (final fila in (json['consumos'] as List? ?? const []))
          if (fila['consumible_id'] != null)
            InsumoUtilizado(
              consumibleId: fila['consumible_id'] as String,
              nombre: (fila['nombre'] as String?) ?? 'Insumo',
              cantidad: (fila['cantidad'] as num?)?.toInt() ?? 0,
            ),
      ],
      // Lo registrado sin pieza llega en una colección hermana, no colgando de
      // `dientes` (defecto D5): la escritura ya lo guardaba y la lectura lo
      // ignoraba, así que se veía desaparecer al recargar la consulta.
      tratamientosGenerales: [
        for (final fila in _generales(json, 'tratamientos'))
          TratamientoAplicadoModel.fromJson(fila),
      ],
      diagnosticosGenerales: [
        for (final fila in _generales(json, 'diagnosticos'))
          DiagnosticoAplicadoModel.fromJson(fila),
      ],
    );
  }

  /// Filas vivas de una colección embebida.
  static List<Map<String, dynamic>> _vivas(Map<String, dynamic> json, String c) {
    final lista = json[c];
    if (lista is! List) return const [];
    return [
      for (final fila in lista)
        if (fila is Map)
          if (fila['deleted_at'] == null) Map<String, dynamic>.from(fila),
    ];
  }

  /// La tabla `signos_vitales_consulta` es la verdad; `consultas.signos_vitales`
  /// es sólo su resumen plano `{codigo: valor}`.
  ///
  /// Al reanudar se leía el resumen, y `SignosVitales.fromJson` reconstruía cada
  /// medición con los valores por defecto: origen «medido en consulta», sin
  /// hora, sin quién la tomó, sin observación y con estado «válido». El
  /// siguiente guardado reenviaba esa reconstrucción y el servidor la escribía
  /// encima. Una presión de 190/110 marcada como referida por el paciente, con
  /// su nota y confirmada por el doctor, volvía como una medición de consulta
  /// sin contexto: la cifra sobrevivía y lo que la hacía interpretable, no
  /// (F1-04).
  static SignosVitales? _parseSignosVitales(Map<String, dynamic> json) {
    final medidos = _vivas(json, 'signos_medidos');
    if (medidos.isNotEmpty) return SignosVitales.fromMediciones(medidos);

    final resumen = json['signos_vitales'];
    if (resumen is Map<String, dynamic>) return SignosVitales.fromJson(resumen);
    return null;
  }

  /// Sin esto, `Consulta.condicionesDetectadas` volvía vacía al reanudar y el
  /// siguiente guardado anulaba las condiciones —el payload las manda siempre,
  /// y lo que no viene en la lista se borra—. La diabetes anotada hace diez
  /// minutos desaparecía al volver de la agenda, y con ella las
  /// contraindicaciones que sostenía (F1-02).
  static List<CondicionDetectada> _parseCondiciones(Map<String, dynamic> json) {
    return [
      for (final fila in _vivas(json, 'condiciones'))
        CondicionDetectada.fromJson(
          fila,
          condicion: fila['condicion'] is Map
              ? CondicionModel.fromJson(
                  Map<String, dynamic>.from(fila['condicion'] as Map),
                )
              : null,
        ),
    ];
  }

  /// Las alertas las decide el servidor y sólo llegaban en la respuesta del
  /// guardado. Al reanudar volvían vacías, así que `alertasBloqueantes` daba
  /// cero y el botón «Terminar consulta» se ofrecía habilitado; el servidor lo
  /// rechazaba después con «Alerta clínica sin resolver» (F1-03).
  static List<AlertaClinica> _parseAlertas(Map<String, dynamic> json) {
    final lista = json['alertas'];
    if (lista is! List) return const [];
    return [
      for (final fila in lista)
        if (fila is Map)
          if (fila['estado'] != 'obsoleta')
            AlertaClinica.fromJson(Map<String, dynamic>.from(fila)),
    ];
  }

  static List<Map<String, dynamic>> _generales(
    Map<String, dynamic> json,
    String clave,
  ) {
    final generales = json['generales'];
    if (generales is! Map) return const [];
    final lista = generales[clave];
    if (lista is! List) return const [];
    return lista.whereType<Map<String, dynamic>>().toList();
  }

  static OdontogramaModel? _parseOdontograma(dynamic raw) {
    if (raw is Map<String, dynamic>) return OdontogramaModel.fromJson(raw);
    if (raw is List && raw.isNotEmpty) {
      return OdontogramaModel.fromJson(raw.first as Map<String, dynamic>);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'paciente_id': pacienteId,
      'doctor_id': doctorId,
      'cita_id': citaId,
      'fecha': fecha.toUtc().toIso8601String(),
      'motivo_consulta': motivoConsulta,
      'temp_condiciones': tempCondiciones,
      'signos_vitales': signosVitales?.toJson(),
      'finalizada': finalizada,
      'tipo_atencion': tipoAtencion.name,
      'tiene_pre_factura': tienePreFactura,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
