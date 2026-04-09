enum EstadoCita {
  pendiente,
  confirmada,
  cancelada,
  atendida,
  noAsistida;

  String get name {
    switch (this) {
      case EstadoCita.pendiente:
        return 'Pendiente';
      case EstadoCita.confirmada:
        return 'Confirmada';
      case EstadoCita.cancelada:
        return 'Cancelada';
      case EstadoCita.atendida:
        return 'Atendida';
      case EstadoCita.noAsistida:
        return 'No Asistida';
    }
  }
}