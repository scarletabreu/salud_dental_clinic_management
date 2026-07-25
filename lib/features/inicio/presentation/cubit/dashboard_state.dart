import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/entities/alerta_operativa.dart';

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
  final int citasCanceladas;

  final int totalPacientes;
  final int totalMedicinas;
  final List<Cita> citasDeHoy;

  final int citasSemanaPendientes;
  final int citasSemanaEnEspera;
  final int citasSemanaCompletadas;
  final int citasSemanaCanceladas;

  final int citasMesPendientes;
  final int citasMesEnEspera;
  final int citasMesCompletadas;
  final int citasMesCanceladas;

  final int consumiblesNormal;
  final int consumiblesBajoStock;
  final int consumiblesAgotados;

  final List<AlertaOperativa> alertas;

  const DashboardLoaded({
    required this.roles,
    this.nombreDoctor,
    required this.citasHoy,
    required this.citasPendientes,
    required this.citasEnEspera,
    required this.citasCompletadas,
    this.citasCanceladas = 0,
    required this.totalPacientes,
    required this.totalMedicinas,
    required this.citasDeHoy,
    this.citasSemanaPendientes = 0,
    this.citasSemanaEnEspera = 0,
    this.citasSemanaCompletadas = 0,
    this.citasSemanaCanceladas = 0,
    this.citasMesPendientes = 0,
    this.citasMesEnEspera = 0,
    this.citasMesCompletadas = 0,
    this.citasMesCanceladas = 0,
    this.consumiblesNormal = 0,
    this.consumiblesBajoStock = 0,
    this.consumiblesAgotados = 0,
    this.alertas = const [],
  });

  bool get isAdmin => roles.contains(RolUsuario.admin);
  bool get isDoctor => roles.contains(RolUsuario.doctor);
  bool get isSecretaria => roles.contains(RolUsuario.asistente);

  bool get tieneAccesoOperativo => isAdmin || isSecretaria;

  // Totales derivados incluyendo canceladas
  int get citasSemanaTotal =>
      citasSemanaPendientes +
      citasSemanaEnEspera +
      citasSemanaCompletadas +
      citasSemanaCanceladas;

  int get citasMesTotal =>
      citasMesPendientes +
      citasMesEnEspera +
      citasMesCompletadas +
      citasMesCanceladas;

  List<AlertaOperativa> get alertasVisibles =>
      alertas.where((a) => a.esVisibleParaRoles(roles)).toList();

  DashboardLoaded copyWith({
    List<RolUsuario>? roles,
    String? nombreDoctor,
    int? citasHoy,
    int? citasPendientes,
    int? citasEnEspera,
    int? citasCompletadas,
    int? citasCanceladas,
    List<Cita>? citasDeHoy,
    int? citasSemanaPendientes,
    int? citasSemanaEnEspera,
    int? citasSemanaCompletadas,
    int? citasSemanaCanceladas,
    int? citasMesPendientes,
    int? citasMesEnEspera,
    int? citasMesCompletadas,
    int? citasMesCanceladas,
    int? totalPacientes,
    int? totalMedicinas,
    int? consumiblesNormal,
    int? consumiblesBajoStock,
    int? consumiblesAgotados,
    List<AlertaOperativa>? alertas,
  }) => DashboardLoaded(
    roles: roles ?? this.roles,
    nombreDoctor: nombreDoctor ?? this.nombreDoctor,
    citasHoy: citasHoy ?? this.citasHoy,
    citasPendientes: citasPendientes ?? this.citasPendientes,
    citasEnEspera: citasEnEspera ?? this.citasEnEspera,
    citasCompletadas: citasCompletadas ?? this.citasCompletadas,
    citasCanceladas: citasCanceladas ?? this.citasCanceladas,
    totalPacientes: totalPacientes ?? this.totalPacientes,
    totalMedicinas: totalMedicinas ?? this.totalMedicinas,
    citasDeHoy: citasDeHoy ?? this.citasDeHoy,
    citasSemanaPendientes: citasSemanaPendientes ?? this.citasSemanaPendientes,
    citasSemanaEnEspera: citasSemanaEnEspera ?? this.citasSemanaEnEspera,
    citasSemanaCompletadas:
        citasSemanaCompletadas ?? this.citasSemanaCompletadas,
    citasSemanaCanceladas: citasSemanaCanceladas ?? this.citasSemanaCanceladas,
    citasMesPendientes: citasMesPendientes ?? this.citasMesPendientes,
    citasMesEnEspera: citasMesEnEspera ?? this.citasMesEnEspera,
    citasMesCompletadas: citasMesCompletadas ?? this.citasMesCompletadas,
    citasMesCanceladas: citasMesCanceladas ?? this.citasMesCanceladas,
    consumiblesNormal: consumiblesNormal ?? this.consumiblesNormal,
    consumiblesBajoStock: consumiblesBajoStock ?? this.consumiblesBajoStock,
    consumiblesAgotados: consumiblesAgotados ?? this.consumiblesAgotados,
    alertas: alertas ?? this.alertas,
  );

  @override
  List<Object?> get props => [
    roles,
    nombreDoctor,
    citasHoy,
    citasPendientes,
    citasEnEspera,
    citasCompletadas,
    citasCanceladas,
    totalPacientes,
    totalMedicinas,
    citasDeHoy,
    citasSemanaPendientes,
    citasSemanaEnEspera,
    citasSemanaCompletadas,
    citasSemanaCanceladas,
    citasMesPendientes,
    citasMesEnEspera,
    citasMesCompletadas,
    citasMesCanceladas,
    consumiblesNormal,
    consumiblesBajoStock,
    consumiblesAgotados,
    alertas,
  ];
}
