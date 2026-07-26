import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';

sealed class ResumenPlanState extends Equatable {
  const ResumenPlanState();
  @override
  List<Object?> get props => [];
}

class ResumenPlanCargando extends ResumenPlanState {
  const ResumenPlanCargando();
}

class ResumenPlanCargado extends ResumenPlanState {
  final List<ResumenActividadPlan> actividades;
  const ResumenPlanCargado(this.actividades);

  double get totalPresupuestado =>
      actividades.fold(0, (s, a) => s + a.montoPresupuestado);
  double get totalRealizado =>
      actividades.fold(0, (s, a) => s + a.montoRealizado);
  double get totalFacturado =>
      actividades.fold(0, (s, a) => s + a.montoFacturado);
  double get totalPagado => actividades.fold(0, (s, a) => s + a.montoPagado);
  double get totalPendiente =>
      actividades.fold(0, (s, a) => s + a.montoPendiente);

  @override
  List<Object?> get props => [actividades];
}

class ResumenPlanError extends ResumenPlanState {
  final String mensaje;
  const ResumenPlanError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}