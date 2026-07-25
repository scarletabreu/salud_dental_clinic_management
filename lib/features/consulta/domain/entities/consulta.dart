import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';

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
  final List<String> tempCondiciones;
  final String? motivoConsulta;
  final String? notas;
  final SignosVitales? signosVitales;
  final bool finalizada;

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
    this.motivoConsulta,
    this.notas,
    this.signosVitales,
    this.finalizada = false,
    this.tienePreFactura = false,
  });

  bool get tieneRecetas => recetas.isNotEmpty;
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
    String? motivoConsulta,
    String? notas,
    SignosVitales? signosVitales,
    bool? finalizada,
    bool? tienePreFactura,
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
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
      notas: notas ?? this.notas,
      signosVitales: signosVitales ?? this.signosVitales,
      finalizada: finalizada ?? this.finalizada,
      tienePreFactura: tienePreFactura ?? this.tienePreFactura,
    );
  }
}
