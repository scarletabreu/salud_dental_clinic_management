enum RolUsuario {
  admin,
  doctor,
  asistente;

  String get value => name;

  String get label {
    switch (this) {
      case RolUsuario.admin:
        return 'Administrador';
      case RolUsuario.doctor:
        return 'Doctor(a)';
      case RolUsuario.asistente:
        return 'Asistente';
    }
  }

}

extension RolPermisos on RolUsuario {
  // Módulo de Configuración y Finanzas
  bool get puedeAccederAConfiguracion => this == RolUsuario.admin;
  bool get puedeAccederACompras => this == RolUsuario.admin;

  // Módulo Médico / Clínico
  bool get puedeVerExpedientes => 
      this == RolUsuario.admin || this == RolUsuario.doctor;
  bool get puedeEditarAlertasYRecetas => 
      this == RolUsuario.admin || this == RolUsuario.doctor;

  // Gestión de Citas (Acceso irrestricto para el flujo operativo)
  bool get puedeGestionarCitas => true;
}