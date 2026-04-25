import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

class Diente {
  final String id;
  final String odontogramaId;
  final List<Superficie> superficies;
  final List<Tratamiento> tratamientos;
  final Diagnosis? diagnosis;
  final String fdiCode;
  final String? observaciones;

  Diente({
    required this.id,
    required this.odontogramaId,
    required this.superficies,
    this.tratamientos = const [],
    this.diagnosis,
    required this.fdiCode,
    this.observaciones,
  });

  Diente copyWith({
    String? odontogramaId,
    List<Superficie>? superficies,
    List<Tratamiento>? tratamientos,
    Diagnosis? diagnosis,
    String? fdiCode,
    String? observaciones,
  }) {
    return Diente(
      id: id,
      odontogramaId: odontogramaId ?? this.odontogramaId,
      superficies: superficies ?? List.from(this.superficies),
      tratamientos: tratamientos ?? List.from(this.tratamientos),
      diagnosis: diagnosis ?? this.diagnosis,
      fdiCode: fdiCode ?? this.fdiCode,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  factory Diente.fromJson(Map<String, dynamic> json) {
  return Diente(
    id: json['id'] as String,
    odontogramaId: json['odontogramaId'] as String,

    superficies: (json['superficies'] as List<dynamic>? ?? [])
        .map((e) => Superficie.fromJson(e as Map<String, dynamic>))
        .toList(),

    tratamientos: (json['tratamientos'] as List<dynamic>? ?? [])
        .map((e) => Tratamiento.fromJson(e as Map<String, dynamic>))
        .toList(),

    diagnosis: json['diagnosis'] != null
        ? Diagnosis.fromJson(json['diagnosis'] as Map<String, dynamic>)
        : null,

    fdiCode: json['fdiCode'] as String,
    observaciones: json['observaciones'] as String?,
  );
}
}
