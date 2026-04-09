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