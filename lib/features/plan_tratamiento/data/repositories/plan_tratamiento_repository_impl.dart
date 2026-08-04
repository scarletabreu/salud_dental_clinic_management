import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/consentimiento_plan.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/datasources/plan_tratamiento_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/models/item_plan_tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/models/plan_tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/errors/transicion_plan_invalida.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/models/resumen_actividad_plan_model.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';

class PlanTratamientoRepositoryImpl implements PlanTratamientoRepository {
  final PlanTratamientoRemoteDatasource remoteDataSource;

  PlanTratamientoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PlanTratamiento> crearPlan(PlanTratamiento plan) {
    return runGuarded(() async {
      final planId = await remoteDataSource.insertPlan(
        PlanTratamientoModel.fromEntity(plan).toJson(),
      );

      final items = await _insertarItems(planId, plan.items);
      return plan.copyWith(id: planId, items: items);
    }, context: 'crear el plan de tratamiento');
  }

  @override
  Future<PlanTratamiento?> getPlanDeConsulta(String consultaId) {
    return runGuarded(() async {
      final fila = await remoteDataSource.fetchPlanPorConsulta(consultaId);
      return fila == null ? null : PlanTratamientoModel.fromJson(fila);
    }, context: 'obtener el plan de tratamiento de la consulta');
  }

    @override
  Future<List<ResumenActividadPlan>> getResumenPorPlan(String planId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchResumenPorPlan(planId);
      return data.map(ResumenActividadPlanModel.fromJson).toList();
    }, context: 'obtener el resumen del plan de tratamiento');
  }

  @override
  Future<List<ResumenActividadPlan>> getResumenPorPaciente(
    String pacienteId,
  ) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchResumenPorPaciente(pacienteId);
      return data.map(ResumenActividadPlanModel.fromJson).toList();
    }, context: 'obtener el resumen financiero del paciente');
  }

  @override
  Future<List<PlanTratamiento>> getPlanesPaciente(String pacienteId) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchPlanesPorPaciente(pacienteId);
      return filas.map(PlanTratamientoModel.fromJson).toList();
    }, context: 'obtener los planes de tratamiento del paciente');
  }

  @override
  Future<List<ItemPlanTratamiento>> getItemsEjecutables(String pacienteId) {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchItemsEjecutables(pacienteId);
      return filas.map(ItemPlanTratamientoModel.fromJson).toList();
    }, context: 'obtener las actividades pendientes del paciente');
  }

  @override
  Future<PlanTratamiento> cambiarEstadoPlan(
    PlanTratamiento plan,
    EstadoPlanTratamiento destino, {
    String? motivoRechazo,
  }) {
    // La transición se valida antes del guard: es una regla de dominio, no un
    // fallo de red, y el llamador debe poder distinguirlas.
    final actualizado = plan.transicionarA(
      destino,
      motivoRechazo: motivoRechazo,
    );
    if (actualizado == null) {
      throw TransicionPlanInvalida(
        origen: plan.estado.etiqueta,
        destino: destino.etiqueta,
        sujeto: 'el plan',
      );
    }

    return runGuarded(() async {
      final id = plan.id;
      if (id == null) {
        throw Exception('El plan no está persistido: no se puede actualizar.');
      }
      await remoteDataSource.updatePlan(
        id,
        PlanTratamientoModel.fromEntity(actualizado).toJson(),
      );
      return actualizado;
    }, context: 'actualizar el estado del plan de tratamiento');
  }

  @override
  Future<ItemPlanTratamiento> cambiarEstadoItem(
    ItemPlanTratamiento item,
    EstadoItemPlan destino, {
    String? motivoRechazo,
  }) {
    final actualizado = item.transicionarA(
      destino,
      motivoRechazo: motivoRechazo,
    );
    if (actualizado == null) {
      throw TransicionPlanInvalida(
        origen: item.estado.etiqueta,
        destino: destino.etiqueta,
      );
    }

    return runGuarded(() async {
      final id = item.id;
      if (id == null) {
        throw Exception(
          'La actividad no está persistida: no se puede actualizar.',
        );
      }
      final fila = await remoteDataSource.updateItem(
        id,
        ItemPlanTratamientoModel.fromEntity(actualizado).toJson(),
      );
      return ItemPlanTratamientoModel.fromJson(fila);
    }, context: 'actualizar el estado de la actividad planificada');
  }

  @override
  Future<List<ItemPlanTratamiento>> agregarItems(
    String planId,
    List<ItemPlanTratamiento> items,
  ) {
    return runGuarded(
      () => _insertarItems(planId, items),
      context: 'agregar actividades al plan de tratamiento',
    );
  }

  @override
  Future<void> eliminarItem(String id) {
    return runGuarded(
      () => remoteDataSource.deleteItem(id),
      context: 'eliminar la actividad del plan',
    );
  }

  Future<List<ItemPlanTratamiento>> _insertarItems(
    String planId,
    List<ItemPlanTratamiento> items,
  ) async {
    if (items.isEmpty) return const [];
    final filas = await remoteDataSource.insertItems([
      for (final item in items)
        ItemPlanTratamientoModel.fromEntity(
          item.copyWith(planId: planId),
        ).toJson(),
    ]);
    return filas.map(ItemPlanTratamientoModel.fromJson).toList();
  }

  @override
  Future<ConsentimientoPlan> registrarConsentimiento({
    required String planId,
    required bool aceptado,
    required String persona,
    required MetodoConsentimiento metodo,
    String relacion = 'titular',
    String? motivoRechazo,
  }) {
    return runGuarded(() async {
      final respuesta = await remoteDataSource.registrarConsentimiento(
        planId: planId,
        decision: aceptado ? 'aceptado' : 'rechazado',
        persona: persona,
        metodo: metodo.dbValue,
        relacion: relacion,
        motivo: motivoRechazo,
      );
      return ConsentimientoPlan.fromRpc(respuesta);
    }, context: 'registrar el consentimiento del plan');
  }
}
