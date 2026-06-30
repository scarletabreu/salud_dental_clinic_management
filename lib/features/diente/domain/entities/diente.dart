import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class Diente {
  final String? id;
  final String odontogramaId;
  final List<Superficie> superficies;
  final List<TratamientoAplicado> tratamientos;

  /// Tratamientos aplicados en consultas ANTERIORES del paciente, proyectados
  /// sobre este odontograma para dar contexto clínico acumulado. Es una capa de
  /// solo lectura: nunca se persiste desde aquí (el guardado solo toca
  /// [tratamientos], la capa "esta consulta").
  final List<TratamientoAplicado> tratamientosHistoricos;

  /// Ids de `tratamientos_aplicados` vinculados en la BD
  /// (`dientes.tratamientos_aplicados_ids`); las entidades completas se
  /// cargan aparte cuando hacen falta.
  final List<String> tratamientosAplicadosIds;
  final List<DiagnosticoAplicado> diagnosis;
  final int fdiCode;
  final String? observaciones;
  final bool estaAusente;

  Diente({
    this.id,
    required this.odontogramaId,
    required this.superficies,
    this.tratamientos = const [],
    this.tratamientosHistoricos = const [],
    this.tratamientosAplicadosIds = const [],
    this.diagnosis = const [],
    required this.fdiCode,
    this.observaciones,
    this.estaAusente = false,
  });

  Diente copyWith({
    String? odontogramaId,
    List<Superficie>? superficies,
    List<TratamientoAplicado>? tratamientos,
    List<TratamientoAplicado>? tratamientosHistoricos,
    List<String>? tratamientosAplicadosIds,
    List<DiagnosticoAplicado>? diagnosis,
    int? fdiCode,
    String? observaciones,
    bool? estaAusente,
  }) {
    return Diente(
      id: id,
      odontogramaId: odontogramaId ?? this.odontogramaId,
      superficies: superficies ?? this.superficies,
      tratamientos: tratamientos ?? this.tratamientos,
      tratamientosHistoricos:
          tratamientosHistoricos ?? this.tratamientosHistoricos,
      tratamientosAplicadosIds:
          tratamientosAplicadosIds ?? this.tratamientosAplicadosIds,
      diagnosis: diagnosis ?? this.diagnosis,
      fdiCode: fdiCode ?? this.fdiCode,
      observaciones: observaciones ?? this.observaciones,
      estaAusente: estaAusente ?? this.estaAusente,
    );
  }
}
