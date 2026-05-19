import 'package:flutter/material.dart';

enum EstadoCita {
  pendiente,
  enEspera,
  completada,
  cancelada;

  Color get color {
    switch (this) {
      case EstadoCita.pendiente:
        return Colors.blue.shade600;
      case EstadoCita.enEspera:
        return Colors.amber.shade700;
      case EstadoCita.completada:
        return Colors.green.shade600;
      case EstadoCita.cancelada:
        return Colors.red.shade600;
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
