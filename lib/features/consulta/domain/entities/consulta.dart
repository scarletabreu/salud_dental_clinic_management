import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';

class Consulta {
  final String? id;
  final String pacienteId;
  final String doctorId;
  final String? citaId;
  final DateTime fecha;
  final List<Receta> recetas;
  final List<InsumoUtilizado> insumosUtilizados;
  final List<DocumentoClinico> documentosClinicos;
  final Odontograma? odontograma;
  /// Texto libre de la anamnesis. Desde HFX-CLIN-003 es un complemento:
  /// lo que participa en contraindicaciones es [condicionesDetectadas].
  final List<String> tempCondiciones;

  /// Condiciones de catálogo descubiertas hoy. Cuentan desde que se registran.
  final List<CondicionDetectada> condicionesDetectadas;

  /// Lo que el catálogo declara global o de arcada: no cuelga de ninguna pieza,
  /// y la base rechaza que se le asigne una.
  final List<TratamientoAplicado> tratamientosGenerales;
  final List<DiagnosticoAplicado> diagnosticosGenerales;

  /// Alertas vigentes que devolvió el motor en el último guardado.
  final List<AlertaClinica> alertas;
  final String? motivoConsulta;
  final String? notas;
  final SignosVitales? signosVitales;
  final bool finalizada;
  final TipoAtencionClinica tipoAtencion;

  /// Versión confirmada por el servidor (HFX-CLIN-002). Viaja en cada guardado
  /// para que dos pestañas no se pisen en silencio: si no coincide, el
  /// servidor rechaza la escritura en vez de aceptar la última que llegó.
  final int? version;

  final bool tienePreFactura;

  Consulta({
    this.id,
    required this.pacienteId,
    required this.doctorId,
    this.citaId,
    required this.fecha,
    this.recetas = const [],
    this.insumosUtilizados = const [],
    this.documentosClinicos = const [],
    this.odontograma,
    this.tempCondiciones = const [],
    this.condicionesDetectadas = const [],
    this.tratamientosGenerales = const [],
    this.diagnosticosGenerales = const [],
    this.alertas = const [],
    this.motivoConsulta,
    this.notas,
    this.signosVitales,
    this.finalizada = false,
    this.tipoAtencion = TipoAtencionClinica.consulta,
    this.tienePreFactura = false,
    this.version,
  });

  bool get tieneRecetas => recetas.isNotEmpty;

  /// Alertas que impiden cerrar mientras nadie las confirme o documente.
  List<AlertaClinica> get alertasBloqueantes =>
      [for (final a in alertas) if (a.bloqueaCierre) a];
  bool get estaEnCurso => !finalizada;
  bool get tieneTratamientosAplicados =>
      odontograma?.dientes.any(
        (d) =>
            d.tratamientos.isNotEmpty || d.tratamientosAplicadosIds.isNotEmpty,
      ) ??
      false;

  Consulta copyWith({
    String? id,
    String? pacienteId,
    String? doctorId,
    DateTime? fecha,
    List<Receta>? recetas,
    List<InsumoUtilizado>? insumosUtilizados,
    List<DocumentoClinico>? documentosClinicos,
    Odontograma? odontograma,
    String? citaId,
    List<String>? tempCondiciones,
    List<CondicionDetectada>? condicionesDetectadas,
    List<TratamientoAplicado>? tratamientosGenerales,
    List<DiagnosticoAplicado>? diagnosticosGenerales,
    List<AlertaClinica>? alertas,
    String? motivoConsulta,
    String? notas,
    SignosVitales? signosVitales,
    bool? finalizada,
    TipoAtencionClinica? tipoAtencion,
    bool? tienePreFactura,
    int? version,
  }) {
    return Consulta(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      doctorId: doctorId ?? this.doctorId,
      citaId: citaId ?? this.citaId,
      fecha: fecha ?? this.fecha,
      recetas: recetas ?? List.from(this.recetas),
      insumosUtilizados: insumosUtilizados ?? List.from(this.insumosUtilizados),
      documentosClinicos:
          documentosClinicos ?? List.from(this.documentosClinicos),
      odontograma: odontograma ?? this.odontograma,
      tempCondiciones: tempCondiciones ?? List.from(this.tempCondiciones),
      condicionesDetectadas:
          condicionesDetectadas ?? List.from(this.condicionesDetectadas),
      tratamientosGenerales:
          tratamientosGenerales ?? List.from(this.tratamientosGenerales),
      diagnosticosGenerales:
          diagnosticosGenerales ?? List.from(this.diagnosticosGenerales),
      alertas: alertas ?? List.from(this.alertas),
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      notas: notas ?? this.notas,
      signosVitales: signosVitales ?? this.signosVitales,
      finalizada: finalizada ?? this.finalizada,
      tipoAtencion: tipoAtencion ?? this.tipoAtencion,
      tienePreFactura: tienePreFactura ?? this.tienePreFactura,
      version: version ?? this.version,
    );
  }
}
