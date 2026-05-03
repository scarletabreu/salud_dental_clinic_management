import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';

class Odontograma {
  final String? id;
  final String consultaId;
  final List<Diente> dientes;
  final List<Tratamiento> tratamientos;
  final List<Diagnosis> diagnosis;

  Odontograma({
    this.id,
    required this.consultaId,
    required this.dientes,
    this.tratamientos = const [],
    this.diagnosis = const [],
  });

  Odontograma copyWith({
    String? consultaId,
    List<Diente>? dientes,
    List<Tratamiento>? tratamientos,
    List<Diagnosis>? diagnosis,
  }) {
    return Odontograma(
      id: id,
      consultaId: consultaId ?? this.consultaId,
      dientes: dientes ?? List.from(this.dientes),
      tratamientos: tratamientos ?? List.from(this.tratamientos),
      diagnosis: diagnosis ?? List.from(this.diagnosis),
    );
  }
}
