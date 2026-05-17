import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class Consulta {
  final String? id;
  final String pacienteId;
  final String doctorId;
  final String citaId;
  final DateTime fecha;
  final List<Receta> recetas;
  final List<DocumentoClinico> documentosClinicos;
  final Odontograma? odontograma;
  final List<String> tempCondiciones;
  final String? motivoConsulta;

  Consulta({
    this.id,
    required this.pacienteId,
    required this.doctorId,
    required this.citaId,
    required this.fecha,
    this.recetas = const [],
    this.documentosClinicos = const [],
    this.odontograma,
    this.tempCondiciones = const [],
    this.motivoConsulta,
  });

  Consulta copyWith({
    String? pacienteId,
    String? doctorId,
    DateTime? fecha,
    List<Receta>? recetas,
    List<DocumentoClinico>? documentosClinicos,
    Odontograma? odontograma,
    String? citaId,
    List<String>? tempCondiciones,
    String? motivoConsulta,
  }) {
    return Consulta(
      id: id,
      pacienteId: pacienteId ?? this.pacienteId,
      doctorId: doctorId ?? this.doctorId,
      citaId: citaId ?? this.citaId,
      fecha: fecha ?? this.fecha,
      recetas: recetas ?? List.from(this.recetas),
      documentosClinicos:
          documentosClinicos ?? List.from(this.documentosClinicos),
      odontograma: odontograma ?? this.odontograma,
      tempCondiciones: tempCondiciones ?? List.from(this.tempCondiciones),
      motivoConsulta: motivoConsulta ?? this.motivoConsulta,
    );
  }
}
