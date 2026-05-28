import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';

enum EstadoCita {
  pendiente,
  enEspera,
  completada,
  cancelada;

  Color get color {
    switch (this) {
      case EstadoCita.pendiente:
        return kIndigo;
      case EstadoCita.enEspera:
        return kAmber;
      case EstadoCita.completada:
        return kGreen;
      case EstadoCita.cancelada:
        return kRed;
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
