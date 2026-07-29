import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

enum ShellDestinationId {
  inicio,
  citasDelDia,
  consultas,
  pacientes,
  cuentasPorCobrar,
  caja,
  tratamientos,
  diagnosticos, // ⚡ Agregado
  medicinas,
  inventario,
  perfiles,
  equipos,
  configuracion,
}

class ShellDestination {
  final ShellDestinationId id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final WidgetBuilder builder;

  const ShellDestination({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.builder,
  });
}

class ShellSection {
  final String title;
  final List<ShellDestination> destinations;

  const ShellSection({required this.title, required this.destinations});
}

class ShellDestinationAccess {
  const ShellDestinationAccess._();

  static bool allows(ShellDestinationId id, List<RolUsuario> roles) {
    if (roles.isEmpty) return false;
    switch (id) {
      case ShellDestinationId.configuracion:
        return _hasAnyRole(roles, const [
          RolUsuario.admin,
          RolUsuario.doctor,
          RolUsuario.asistente,
        ]);
      case ShellDestinationId.perfiles:
      case ShellDestinationId.equipos:
      case ShellDestinationId.inventario:
      case ShellDestinationId.medicinas:
      case ShellDestinationId.tratamientos:
      case ShellDestinationId.diagnosticos: // ⚡ Acceso para Admin/Doctores
        return _hasAnyRole(roles, const [RolUsuario.admin, RolUsuario.doctor]);
      case ShellDestinationId.consultas:
        return _hasAnyRole(roles, const [RolUsuario.admin, RolUsuario.doctor]);
      case ShellDestinationId.pacientes:
      case ShellDestinationId.citasDelDia:
      case ShellDestinationId.cuentasPorCobrar:
        return _hasAnyRole(roles, const [
          RolUsuario.admin,
          RolUsuario.doctor,
          RolUsuario.asistente,
        ]);
      case ShellDestinationId.caja:
        return _hasAnyRole(roles, const [
          RolUsuario.admin,
          RolUsuario.asistente,
        ]);
      case ShellDestinationId.inicio:
        return true;
    }
  }

  static List<ShellSection> visibleSections(
    List<ShellSection> sections,
    List<RolUsuario> roles,
  ) => List<ShellSection>.unmodifiable(
    [
      for (final section in sections)
        ShellSection(
          title: section.title,
          destinations: List<ShellDestination>.unmodifiable(
            _orderForRole(
              section.destinations
                  .where((destination) => allows(destination.id, roles))
                  .toList(),
              roles,
            ),
          ),
        ),
    ].where((section) => section.destinations.isNotEmpty),
  );

  static bool _hasAnyRole(List<RolUsuario> roles, List<RolUsuario> allowed) =>
      roles.any(allowed.contains);

  static List<ShellDestination> _orderForRole(
    List<ShellDestination> destinations,
    List<RolUsuario> roles,
  ) {
    if (roles.length != 1 || roles.single != RolUsuario.asistente) {
      return destinations;
    }
    const priority = {
      ShellDestinationId.citasDelDia: 0,
      ShellDestinationId.inicio: 1,
      ShellDestinationId.pacientes: 2,
    };
    destinations.sort(
      (a, b) => (priority[a.id] ?? priority.length).compareTo(
        priority[b.id] ?? priority.length,
      ),
    );
    return destinations;
  }
}
