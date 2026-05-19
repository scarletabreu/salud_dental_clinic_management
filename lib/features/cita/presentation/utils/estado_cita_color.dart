import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

extension EstadoCitaColor on EstadoCita {
  Color get color {
    switch (this) {
      case EstadoCita.pendiente:
        return const Color(0xFF2196F3);
      case EstadoCita.confirmada:
        return const Color(0xFF009688);
      case EstadoCita.atendida:
        return const Color(0xFF4CAF50);
      case EstadoCita.cancelada:
        return const Color(0xFF9E9E9E);
      case EstadoCita.noAsistida:
        return const Color(0xFFFF9800);
    }
  }
}
