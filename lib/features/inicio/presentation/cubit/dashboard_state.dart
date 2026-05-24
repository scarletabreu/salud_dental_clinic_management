import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final int citasHoy;
  final int citasEnEspera;
  final int citasCompletadas;
  final int totalPacientes;
  final int totalMedicinas;
  final List<Cita> citasDeHoy;

  const DashboardLoaded({
    required this.citasHoy,
    required this.citasEnEspera,
    required this.citasCompletadas,
    required this.totalPacientes,
    required this.totalMedicinas,
    required this.citasDeHoy,
  });

  @override
  List<Object?> get props => [
    citasHoy,
    citasEnEspera,
    citasCompletadas,
    totalPacientes,
    totalMedicinas,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
