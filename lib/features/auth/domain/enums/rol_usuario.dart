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

extension RolPermisosLista on List<RolUsuario> {
  bool get puedeAccederAConfiguracion => contains(RolUsuario.admin);
  bool get puedeAccederACompras => contains(RolUsuario.admin);

  bool get puedeVerExpedientes =>
      contains(RolUsuario.admin) || contains(RolUsuario.doctor);

  bool get puedeEditarAlertasYRecetas =>
      contains(RolUsuario.admin) || contains(RolUsuario.doctor);

  bool get puedeGestionarCitas => true;
}
