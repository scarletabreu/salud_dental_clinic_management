import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class Diente {
  final String id;
  final String odontogramaId;
  final List<Superficie> superficies;
  final List<TratamientoAplicado> tratamientos;
  final List<DiagnosticoAplicado> diagnosis;
  final int fdiCode;
  final String? observaciones;

  Diente({
    required this.id,
    required this.odontogramaId,
    required this.superficies,
    this.tratamientos = const [],
    this.diagnosis = const [],
    required this.fdiCode,
    this.observaciones,
  });

  Diente copyWith({
    String? odontogramaId,
    List<Superficie>? superficies,
    List<TratamientoAplicado>? tratamientos,
    List<DiagnosticoAplicado>? diagnosis,
    int? fdiCode,
    String? observaciones,
  }) {
    return Diente(
      id: id,
      odontogramaId: odontogramaId ?? this.odontogramaId,
      superficies: superficies ?? this.superficies,
      tratamientos: tratamientos ?? this.tratamientos,
      diagnosis: diagnosis ?? this.diagnosis,
      fdiCode: fdiCode ?? this.fdiCode,
      observaciones: observaciones ?? this.observaciones,
    );
  }
}
