import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/capacidades_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

enum ShellDestinationId {
  inicio,
  citasDelDia,
  consultas,
  pacientes,
  cuentasPorCobrar,
  caja,
  tratamientos,
  procedimientos,
  diagnosticos,
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
      // Deuda saldada en la jornada de QA del 1 ago 2026 (defecto D9):
      // `administrarPersonal` siempre fue capacidad sólo del admin y Perfiles
      // seguía abierto al doctor «por si gestiona sus asistentes». QA lo pidió
      // cerrado; asignar asistentes es administración.
      case ShellDestinationId.perfiles:
        return roles.puedeAdministrarPersonal;
      case ShellDestinationId.equipos:
      case ShellDestinationId.inventario:
      case ShellDestinationId.medicinas:
      case ShellDestinationId.tratamientos:
      case ShellDestinationId.procedimientos:
      case ShellDestinationId.diagnosticos:
        return roles.puedeGestionarCatalogosClinicos;
      case ShellDestinationId.consultas:
        return roles.puedeEjercerClinica;
      case ShellDestinationId.pacientes:
      case ShellDestinationId.citasDelDia:
        return _hasAnyRole(roles, const [
          RolUsuario.admin,
          RolUsuario.doctor,
          RolUsuario.asistente,
        ]);
      // Cobrar es de quien lleva la caja. Estaba agrupado con Pacientes y
      // Citas del Día sólo por compartir la lista de roles (defecto D9).
      //
      // En `dev` se arregló en paralelo agrupándolo con Caja bajo
      // `puedeGestionarCaja`. Se conserva la misma regla —hoy los dos
      // resuelven a admin+asistente— con capacidad propia, porque no son lo
      // mismo: una es entrar a Cuentas por Cobrar y la otra operar la caja, y
      // el día que se separen no habrá que descubrirlo por un defecto.
      case ShellDestinationId.cuentasPorCobrar:
        return roles.puedeVerCuentasPorCobrar;
      case ShellDestinationId.caja:
        return roles.puedeGestionarCaja;
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
