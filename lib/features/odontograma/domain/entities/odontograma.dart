import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';

class Odontograma {
  final String id;
  final String consultaId;
  final List<Diente> dientes;
  final List<Tratamiento> tratamientos;
  final List<Diagnosis> diagnosis;

  Odontograma({
    required this.id,
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

  factory Odontograma.fromJson(Map<String, dynamic> json) {
  return Odontograma(
    id: json['id'] as String,
    consultaId: json['consultaId'] as String,

    dientes: (json['dientes'] as List<dynamic>? ?? [])
        .map((e) => Diente.fromJson(e as Map<String, dynamic>))
        .toList(),

    tratamientos: (json['tratamientos'] as List<dynamic>? ?? [])
        .map((e) => Tratamiento.fromJson(e as Map<String, dynamic>))
        .toList(),

    diagnosis: (json['diagnosis'] as List<dynamic>? ?? [])
        .map((e) => Diagnosis.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
}
