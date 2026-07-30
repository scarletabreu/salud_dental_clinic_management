import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

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
  Future<List<ResumenActividadPlan>> getResumenPorPlan(String planId);
  Future<List<ResumenActividadPlan>> getResumenPorPaciente(String pacienteId);
  /// Registra una ejecución (total o parcial) de [item] en
  /// `tratamientos_aplicados`, vinculada por `item_plan_id`. Cada llamada crea
  /// una fila nueva — consistente con `resumen_actividad_plan`, que suma
  /// `cantidad_realizada` agrupando por `item_plan_id`.
  Future<void> registrarEjecucionItem({
    required ItemPlanTratamiento item,
    required String consultaId,
    required String doctorId,
    required double cantidadRealizada,
    required EstadoTratamientoAplicado estadoTratamientoAplicado,
    String? notas,
  });
}
