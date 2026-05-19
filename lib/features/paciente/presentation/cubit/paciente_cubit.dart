import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'paciente_state.dart';

class PacienteCubit extends Cubit<PacienteState> {
  final IPacienteRepository _repository;

  PacienteCubit(this._repository) : super(const PacienteLoading());

  Future<void> load() async {
    emit(const PacienteLoading());
    final result = await _repository.getPacientes();
    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (list) => emit(PacienteLoaded(todos: list, filtrados: list)),
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