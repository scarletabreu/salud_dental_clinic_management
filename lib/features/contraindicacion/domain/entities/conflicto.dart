// features/contraindicacion/domain/entities/conflicto.dart

import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

/// Severidad de un conflicto clínico detectado al cruzar las condiciones
/// del paciente con las contraindicaciones de un tratamiento.
///
/// Mapeo desde [TipoContraindicacion]:
///   absoluta  → ABSOLUTA  (bloqueo total, solo botón Cancelar)
///   relativa  → CRITICA   (requiere justificación clínica obligatoria)
///
/// ADVERTENCIA se reserva para lógica futura (p.ej. interacciones medicamentosas
/// de baja gravedad) pero el dialog ya la soporta con color amber.
enum SeveridadConflicto { advertencia, critica, absoluta }

extension SeveridadConflictoX on SeveridadConflicto {
  /// Convierte [TipoContraindicacion] al nivel de severidad correspondiente.
  static SeveridadConflicto fromTipo(TipoContraindicacion tipo) {
    if (tipo == TipoContraindicacion.absoluta) return SeveridadConflicto.absoluta;
    return SeveridadConflicto.critica; // relativa → CRITICA
  }

  String get label => switch (this) {
        SeveridadConflicto.advertencia => 'ADVERTENCIA',
        SeveridadConflicto.critica     => 'CRÍTICA',
        SeveridadConflicto.absoluta    => 'ABSOLUTA',
      };
}

/// Un conflicto detectado entre una condición del paciente y una
/// contraindicación del tratamiento que se intenta aplicar.
class Conflicto {
  final Condicion condicionPaciente;
  final Contraindicacion contraindicacion;
  final SeveridadConflicto severidad;
  final String descripcion;

  const Conflicto({
    required this.condicionPaciente,
    required this.contraindicacion,
    required this.severidad,
    required this.descripcion,
  });
}