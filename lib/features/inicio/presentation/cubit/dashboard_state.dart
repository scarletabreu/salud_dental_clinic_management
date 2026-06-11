import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';

sealed class DashboardState extends Equatable {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
  @override
  List<Object?> get props => [];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardLoaded extends DashboardState {
  final List<RolUsuario> roles;
  final String? nombreDoctor;
  final int citasHoy;
  final int citasPendientes;
  final int citasEnEspera;
  final int citasCompletadas;
  final int totalPacientes;
  final int totalMedicinas;
  final List<Cita> citasDeHoy;

  const DashboardLoaded({
    required this.roles,
    this.nombreDoctor,
    required this.citasHoy,
    required this.citasPendientes,
    required this.citasEnEspera,
    required this.citasCompletadas,
    required this.totalPacientes,
    required this.totalMedicinas,
    required this.citasDeHoy,
  });

  bool get isAdmin => roles.contains(RolUsuario.admin);
  bool get isDoctor => roles.contains(RolUsuario.doctor);
  bool get isSecretaria => roles.contains(RolUsuario.asistente);

  DashboardLoaded copyWith({
    List<RolUsuario>? roles,
    String? nombreDoctor,
    int? citasHoy,
    int? citasPendientes,
    int? citasEnEspera,
    int? citasCompletadas,
    int? totalPacientes,
    int? totalMedicinas,
    List<Cita>? citasDeHoy,
  }) => DashboardLoaded(
    roles: roles ?? this.roles,
    nombreDoctor: nombreDoctor ?? this.nombreDoctor,
    citasHoy: citasHoy ?? this.citasHoy,
    citasPendientes: citasPendientes ?? this.citasPendientes,
    citasEnEspera: citasEnEspera ?? this.citasEnEspera,
    citasCompletadas: citasCompletadas ?? this.citasCompletadas,
    totalPacientes: totalPacientes ?? this.totalPacientes,
    totalMedicinas: totalMedicinas ?? this.totalMedicinas,
    citasDeHoy: citasDeHoy ?? this.citasDeHoy,
  );

  @override
  List<Object?> get props => [
    roles,
    nombreDoctor,
    citasHoy,
    citasPendientes,
    citasEnEspera,
    citasCompletadas,
    totalPacientes,
    totalMedicinas,
    citasDeHoy,
  ];
}
