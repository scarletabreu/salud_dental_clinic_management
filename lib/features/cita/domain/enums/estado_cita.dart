import 'package:flutter/material.dart';

enum EstadoCita {
  pendiente,
  enEspera,
  completada,
  cancelada;

  Color get color {
    switch (this) {
      case EstadoCita.pendiente:
        return const Color(0xFF6366F1);
      case EstadoCita.enEspera:
        return const Color(0xFFF59E0B);
      case EstadoCita.completada:
        return const Color(0xFF10B981);
      case EstadoCita.cancelada:
        return const Color(0xFFEF4444);
    }
  }

  String get label {
    switch (this) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.enEspera:
        return 'En Espera';
      case EstadoCita.completada:
        return 'Completada';
      case EstadoCita.cancelada:
        return 'Cancelada';
    }
  }
}
