import 'package:salud_dental_clinic_management/features/auditoria/domain/entities/evento_auditoria.dart';

sealed class LineaTiempoState {
  const LineaTiempoState();
}

class LineaTiempoInicial extends LineaTiempoState {
  const LineaTiempoInicial();
}

class LineaTiempoCargando extends LineaTiempoState {
  const LineaTiempoCargando();
}

class LineaTiempoCargada extends LineaTiempoState {
  final List<EventoAuditoria> eventos;
  const LineaTiempoCargada(this.eventos);
}

class LineaTiempoError extends LineaTiempoState {
  final String mensaje;
  const LineaTiempoError(this.mensaje);
}
