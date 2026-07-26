import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/usecases/get_resumen_actividad_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/resumen_plan_state.dart';

class ResumenPlanCubit extends Cubit<ResumenPlanState> {
  final GetResumenActividadPlan _getResumen;

  ResumenPlanCubit(this._getResumen) : super(const ResumenPlanCargando());

  Future<void> cargarPorPlan(String planId) async {
    emit(const ResumenPlanCargando());
    try {
      final actividades = await _getResumen.porPlan(planId);
      emit(ResumenPlanCargado(actividades));
    } catch (e) {
      emit(ResumenPlanError('No se pudo cargar el resumen del plan.'));
    }
  }

  Future<void> cargarPorPaciente(String pacienteId) async {
    emit(const ResumenPlanCargando());
    try {
      final actividades = await _getResumen.porPaciente(pacienteId);
      emit(ResumenPlanCargado(actividades));
    } catch (e) {
      emit(ResumenPlanError('No se pudo cargar el resumen financiero.'));
    }
  }
}