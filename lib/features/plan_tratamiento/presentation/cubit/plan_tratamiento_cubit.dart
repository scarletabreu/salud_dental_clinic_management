import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/errors/transicion_plan_invalida.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Gobierna el plan de tratamiento de una consulta: qué se propone tratar y en
/// qué punto está cada decisión.
///
/// Nada de lo que ocurre aquí factura. El cargo nace cuando la actividad se
/// ejecuta y se registra en `tratamientos_aplicados` (SD-135).
class PlanTratamientoCubit extends Cubit<PlanTratamientoState> {
  final PlanTratamientoRepository _repository;

  PlanTratamientoCubit({required PlanTratamientoRepository repository})
    : _repository = repository,
      super(const PlanTratamientoInitial());

  Future<void> cargarDeConsulta(String consultaId) async {
    emit(const PlanTratamientoCargando());
    try {
      final plan = await _repository.getPlanDeConsulta(consultaId);
      emit(PlanTratamientoCargado(plan: plan));
    } catch (e) {
      emit(PlanTratamientoError('No se pudo cargar el plan.\n$e'));
    }
  }

  /// Registra que la actividad se ejecutó (total o parcialmente) y refleja el
  /// cambio de estado del plan junto con la ejecución real, en la misma
  /// operación. Sin esto, mover el estado del plan es solo una etiqueta.
  Future<void> registrarEjecucion(
    ItemPlanTratamiento item, {
    required EstadoItemPlan destinoEstado,
    required double cantidadRealizada,
    required String consultaId,
    required String doctorId,
    String? notas,
  }) async {
    final actual = state is PlanTratamientoCargado
        ? state as PlanTratamientoCargado
        : null;
    final plan = actual?.plan;
    if (actual == null || plan == null) return;

    emit(actual.copyWith(guardando: true, limpiarAviso: true));
    try {
      // 1. Registra la ejecución real (crea o suma sobre la existente).
      await _repository.registrarEjecucionItem(
        item: item,
        consultaId: consultaId,
        doctorId: doctorId,
        cantidadRealizada: cantidadRealizada,
        notas: notas,
        estadoTratamientoAplicado: destinoEstado == EstadoItemPlan.completado
            ? EstadoTratamientoAplicado.completado
            : EstadoTratamientoAplicado.enProceso,
      );

      // 2. Refleja el nuevo estado en el plan (misma transición de siempre).
      final actualizado = await _repository.cambiarEstadoItem(
        item,
        destinoEstado,
      );

      emit(
        PlanTratamientoCargado(
          plan: plan.copyWith(
            items: [
              for (final existente in plan.items)
                if (existente.id == actualizado.id) actualizado else existente,
            ],
          ),
        ),
      );
    } on TransicionPlanInvalida catch (e) {
      emit(actual.copyWith(guardando: false, aviso: e.mensaje));
    } catch (e) {
      emit(
        actual.copyWith(
          guardando: false,
          aviso: 'No se pudo registrar la ejecución: $e',
        ),
      );
    }
  }

  /// Lleva al plan las actividades que el doctor decidió tratar. Si la consulta
  /// aún no tiene plan, lo crea; si ya lo tiene, agrega.
  Future<void> proponerActividades({
    required String pacienteId,
    required String doctorId,
    required String consultaId,
    String? evaluacionId,
    required List<ItemPlanTratamiento> actividades,
  }) async {
    if (actividades.isEmpty) return;
    final actual = state is PlanTratamientoCargado
        ? state as PlanTratamientoCargado
        : const PlanTratamientoCargado();
    emit(actual.copyWith(guardando: true, limpiarAviso: true));

    try {
      final existente = actual.plan;
      if (existente?.id == null) {
        final creado = await _repository.crearPlan(
          PlanTratamiento(
            pacienteId: pacienteId,
            doctorId: doctorId,
            consultaOrigenId: consultaId,
            evaluacionId: evaluacionId,
            estado: EstadoPlanTratamiento.propuesto,
            fechaPropuesta: DateTime.now(),
            items: actividades,
          ),
        );
        emit(PlanTratamientoCargado(plan: creado));
        return;
      }

      final agregados = await _repository.agregarItems(
        existente!.id!,
        actividades,
      );
      emit(
        PlanTratamientoCargado(
          plan: existente.copyWith(items: [...existente.items, ...agregados]),
        ),
      );
    } catch (e) {
      emit(actual.copyWith(guardando: false, aviso: 'No se pudo guardar: $e'));
    }
  }

  Future<void> cambiarEstadoActividad(
    ItemPlanTratamiento item,
    EstadoItemPlan destino, {
    String? motivoRechazo,
  }) async {
    final actual = state is PlanTratamientoCargado
        ? state as PlanTratamientoCargado
        : null;
    final plan = actual?.plan;
    if (actual == null || plan == null) return;

    emit(actual.copyWith(guardando: true, limpiarAviso: true));
    try {
      final actualizado = await _repository.cambiarEstadoItem(
        item,
        destino,
        motivoRechazo: motivoRechazo,
      );
      emit(
        PlanTratamientoCargado(
          plan: plan.copyWith(
            items: [
              for (final existente in plan.items)
                if (existente.id == actualizado.id) actualizado else existente,
            ],
          ),
        ),
      );
    } on TransicionPlanInvalida catch (e) {
      // Regla de dominio, no fallo de red: el plan sigue en pantalla intacto.
      emit(actual.copyWith(guardando: false, aviso: e.mensaje));
    } catch (e) {
      emit(
        actual.copyWith(
          guardando: false,
          aviso: 'No se pudo actualizar la actividad: $e',
        ),
      );
    }
  }

  Future<void> cambiarEstadoPlan(
    EstadoPlanTratamiento destino, {
    String? motivoRechazo,
  }) async {
    final actual = state is PlanTratamientoCargado
        ? state as PlanTratamientoCargado
        : null;
    final plan = actual?.plan;
    if (actual == null || plan == null) return;

    emit(actual.copyWith(guardando: true, limpiarAviso: true));
    try {
      final actualizado = await _repository.cambiarEstadoPlan(
        plan,
        destino,
        motivoRechazo: motivoRechazo,
      );
      emit(PlanTratamientoCargado(plan: actualizado.copyWith(items: plan.items)));
    } on TransicionPlanInvalida catch (e) {
      emit(actual.copyWith(guardando: false, aviso: e.mensaje));
    } catch (e) {
      emit(
        actual.copyWith(
          guardando: false,
          aviso: 'No se pudo actualizar el plan: $e',
        ),
      );
    }
  }

  Future<void> quitarActividad(ItemPlanTratamiento item) async {
    final actual = state is PlanTratamientoCargado
        ? state as PlanTratamientoCargado
        : null;
    final plan = actual?.plan;
    final id = item.id;
    if (actual == null || plan == null || id == null) return;

    emit(actual.copyWith(guardando: true, limpiarAviso: true));
    try {
      await _repository.eliminarItem(id);
      emit(
        PlanTratamientoCargado(
          plan: plan.copyWith(
            items: plan.items.where((i) => i.id != id).toList(),
          ),
        ),
      );
    } catch (e) {
      emit(
        actual.copyWith(
          guardando: false,
          aviso: 'No se pudo quitar la actividad: $e',
        ),
      );
    }
  }

  void limpiarAviso() {
    if (state case final PlanTratamientoCargado cargado) {
      emit(cargado.copyWith(limpiarAviso: true));
    }
  }
}
