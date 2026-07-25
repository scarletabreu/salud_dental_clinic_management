import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';

abstract class PlanTratamientoRepository {
  /// Crea el plan con sus actividades y devuelve el plan persistido (con ids).
  Future<PlanTratamiento> crearPlan(PlanTratamiento plan);

  Future<PlanTratamiento?> getPlanDeConsulta(String consultaId);

  Future<List<PlanTratamiento>> getPlanesPaciente(String pacienteId);

  /// Actividades ya decididas y sin cerrar: la bandeja de trabajo del paciente.
  Future<List<ItemPlanTratamiento>> getItemsEjecutables(String pacienteId);

  Future<PlanTratamiento> cambiarEstadoPlan(
    PlanTratamiento plan,
    EstadoPlanTratamiento destino, {
    String? motivoRechazo,
  });

  Future<ItemPlanTratamiento> cambiarEstadoItem(
    ItemPlanTratamiento item,
    EstadoItemPlan destino, {
    String? motivoRechazo,
  });

  Future<List<ItemPlanTratamiento>> agregarItems(
    String planId,
    List<ItemPlanTratamiento> items,
  );

  Future<void> eliminarItem(String id);
}
