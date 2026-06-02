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
  final int citasPendientes;
  final int citasEnEspera;
  final int citasCompletadas;
  final int totalPacientes;
  final int totalMedicinas;
  final List<Cita> citasDeHoy;
  final String? nombreDoctor;

  const DashboardLoaded({
    required this.citasHoy,
    required this.citasPendientes,
    required this.citasEnEspera,
    required this.citasCompletadas,
    required this.totalPacientes,
    required this.totalMedicinas,
    required this.citasDeHoy,
    this.nombreDoctor,
  });

  DashboardLoaded copyWith({
    int? citasHoy,
    int? citasPendientes,
    int? citasEnEspera,
    int? citasCompletadas,
    int? totalPacientes,
    int? totalMedicinas,
    List<Cita>? citasDeHoy,
    String? nombreDoctor,
  }) {
    return DashboardLoaded(
      citasHoy: citasHoy ?? this.citasHoy,
      citasPendientes: citasPendientes ?? this.citasPendientes,
      citasEnEspera: citasEnEspera ?? this.citasEnEspera,
      citasCompletadas: citasCompletadas ?? this.citasCompletadas,
      totalPacientes: totalPacientes ?? this.totalPacientes,
      totalMedicinas: totalMedicinas ?? this.totalMedicinas,
      citasDeHoy: citasDeHoy ?? this.citasDeHoy,
      nombreDoctor: nombreDoctor ?? this.nombreDoctor,
    );
  }

  @override
  List<Object?> get props => [
    citasHoy,
    citasPendientes,
    citasEnEspera,
    citasCompletadas,
    totalPacientes,
    totalMedicinas,
    citasDeHoy,
    nombreDoctor,
  ];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
