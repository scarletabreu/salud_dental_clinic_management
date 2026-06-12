import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'paciente_state.dart';

class PacienteCubit extends Cubit<PacienteState> {
  final IPacienteRepository _repository;
  final ConsultaRepository _consultaRepository;

  PacienteCubit(this._repository, this._consultaRepository)
      : super(const PacienteLoading());

  Future<void> load() async {
    emit(const PacienteLoading());
    final result = await _repository.getPacientes();

    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (list) => emit(PacienteLoaded(todos: list, filtrados: list)),
    );
  }

  Future<void> loadById(String id) async {
    emit(const PacienteDetailLoading());
    final result = await _repository.getPacienteById(id);

    await result.fold(
      (failure) async => emit(PacienteError(failure.message)),
      (paciente) async {
        final consultas = await _historialDe(paciente.id);
        emit(
          PacienteDetailLoaded(
            paciente.copyWith(
              record: paciente.record.copyWith(consultas: consultas),
            ),
          ),
        );
      },
    );
  }

  /// El expediente no debe romperse si falla el historial (p. ej. pacientes
  /// de prueba con id no-uuid): se degrada a lista vacía.
  Future<List<Consulta>> _historialDe(String? pacienteId) async {
    if (pacienteId == null) return const [];
    try {
      return await _consultaRepository.getHistorialPaciente(pacienteId);
    } catch (_) {
      return const [];
    }
  }

  /// Carga el paciente para una consulta a partir del id de la persona de la
  /// cita; si la persona aún no es paciente, se crea en este momento.
  Future<void> loadParaConsulta(String personaId) async {
    emit(const PacienteDetailLoading());
    final result = await _repository.getOrCreatePacienteByPersonaId(personaId);

    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (paciente) => emit(PacienteDetailLoaded(paciente)),
    );
  }

  void search(String query) {
    final current = state;
    if (current is! PacienteLoaded) return;

    final q = query.toLowerCase().trim();

    if (q.isEmpty) {
      emit(PacienteLoaded(todos: current.todos, filtrados: current.todos));
      return;
    }

    final filtrados = current.todos.where((p) {
      return p.fullName.toLowerCase().contains(q) ||
          p.govID.toLowerCase().contains(q);
    }).toList();

    emit(PacienteLoaded(todos: current.todos, filtrados: filtrados));
  }

  // --- MÉTODOS DE CONCILIACIÓN PARA EL FORMULARIO ---

  Future<void> addPaciente(Paciente paciente) async {
    emit(const PacienteLoading());
    final result = await _repository.addPaciente(paciente);
    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (_) {
        emit(const PacienteOperationSuccess());
        load();
      },
    );
  }

  Future<void> updatePaciente(Paciente paciente) async {
    emit(const PacienteLoading());
    final result = await _repository.updatePaciente(paciente);
    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (_) {
        emit(const PacienteOperationSuccess());
        load();
      },
    );
  }
}