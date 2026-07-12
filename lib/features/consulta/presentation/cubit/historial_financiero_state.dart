import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';

sealed class HistorialFinancieroState {
  const HistorialFinancieroState();
}

class HistorialFinancieroInitial extends HistorialFinancieroState {
  const HistorialFinancieroInitial();
}

class HistorialFinancieroLoading extends HistorialFinancieroState {
  const HistorialFinancieroLoading();
}

class HistorialFinancieroLoaded extends HistorialFinancieroState {
  final List<Cuenta> cuentas;

  final double totalPendiente;

  final double totalCobrado;

  final double totalFacturado;

  const HistorialFinancieroLoaded({
    required this.cuentas,
    required this.totalPendiente,
    required this.totalCobrado,
    required this.totalFacturado,
  });

  bool get tieneDeuda => totalPendiente > 0;
  bool get estaSaldado => totalPendiente <= 0 && cuentas.isNotEmpty;
}

class HistorialFinancieroError extends HistorialFinancieroState {
  final String message;
  const HistorialFinancieroError(this.message);
}
