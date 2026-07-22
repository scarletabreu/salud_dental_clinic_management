import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

class ShellDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;

  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });
}

/// Single permission policy shared by every responsive navigation surface.
class ShellDestinationAccess {
  const ShellDestinationAccess._();

  static bool allows(String label, List<RolUsuario> roles) {
    if (roles.isEmpty) return false;
    switch (label) {
      case 'Configuración':
        return roles.contains(RolUsuario.admin) ||
            roles.contains(RolUsuario.doctor) ||
            roles.contains(RolUsuario.asistente);
      case 'Perfiles':
      case 'Equipos':
        return roles.contains(RolUsuario.admin);
      case 'Consultas':
      case 'Medicinas':
      case 'Tratamientos':
        return roles.contains(RolUsuario.admin) ||
            roles.contains(RolUsuario.doctor);
      case 'Pacientes':
      case 'Mis Citas del Día':
      case 'Cuentas por Cobrar':
        return roles.contains(RolUsuario.admin) ||
            roles.contains(RolUsuario.doctor) ||
            roles.contains(RolUsuario.asistente);
      case 'Caja':
        return roles.contains(RolUsuario.admin) ||
            roles.contains(RolUsuario.asistente);
      case 'Inicio':
        return true;
      default:
        return false;
    }
  }
}
