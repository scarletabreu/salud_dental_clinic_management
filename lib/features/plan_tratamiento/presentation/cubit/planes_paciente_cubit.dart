import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';

sealed class PlanesPacienteState {
  const PlanesPacienteState();
}

class PlanesPacienteInicial extends PlanesPacienteState {
  const PlanesPacienteInicial();
}

class PlanesPacienteCargando extends PlanesPacienteState {
  const PlanesPacienteCargando();
}

class PlanesPacienteCargado extends PlanesPacienteState {
  final List<PlanTratamiento> planes;

  /// Actividades aceptadas y sin cerrar: la bandeja de trabajo de las próximas
  /// citas. Es la pregunta que el expediente tiene que responder de un vistazo.
  final List<ItemPlanTratamiento> pendientesDeEjecutar;

  const PlanesPacienteCargado({
    required this.planes,
    required this.pendientesDeEjecutar,
  });

  double get totalPendiente => pendientesDeEjecutar.fold(
    0,
    (suma, item) => suma + item.precioEstimado,
  );
}

class PlanesPacienteError extends PlanesPacienteState {
  final String mensaje;
  const PlanesPacienteError(this.mensaje);
}

/// Vista longitudinal del plan: todos los planes del paciente y lo que quedó
/// aceptado sin ejecutar.
class PlanesPacienteCubit extends Cubit<PlanesPacienteState> {
  final PlanTratamientoRepository _repository;
  final String pacienteId;

  PlanesPacienteCubit({
    required PlanTratamientoRepository repository,
    required this.pacienteId,
  }) : _repository = repository,
       super(const PlanesPacienteInicial());

  Future<void> cargar() async {
    emit(const PlanesPacienteCargando());
    try {
      final planes = await _repository.getPlanesPaciente(pacienteId);
      final pendientes = await _repository.getItemsEjecutables(pacienteId);
      emit(
        PlanesPacienteCargado(
          planes: planes,
          pendientesDeEjecutar: pendientes,
        ),
      );
    } catch (e) {
      emit(
        PlanesPacienteError(
          'No se pudieron cargar los planes de tratamiento.\n$e',
        ),
      );
    }
  }
}
