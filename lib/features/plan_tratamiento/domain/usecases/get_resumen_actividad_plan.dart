import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';

class GetResumenActividadPlan {
  final PlanTratamientoRepository repository;
  GetResumenActividadPlan(this.repository);

  Future<List<ResumenActividadPlan>> porPlan(String planId) =>
      repository.getResumenPorPlan(planId);

  Future<List<ResumenActividadPlan>> porPaciente(String pacienteId) =>
      repository.getResumenPorPaciente(pacienteId);
}