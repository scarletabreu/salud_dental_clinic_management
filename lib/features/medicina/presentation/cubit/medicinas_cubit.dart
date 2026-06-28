import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/get_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/providers/medicinas_state.dart';

class MedicinasCubit extends Cubit<MedicinasState> {
  final GetMedicinas _getMedicinas;

  MedicinasCubit({required GetMedicinas getMedicinas})
    : _getMedicinas = getMedicinas,
      super(MedicinasInitial());

  Future<void> loadMedicinas() async {
    emit(MedicinasLoading());
    final result = await _getMedicinas();
    result.fold(
      (failure) => emit(MedicinasError(failure.message)),
      (list) =>
          emit(MedicinasLoaded(allMedicinas: list, filteredMedicinas: list)),
    );
  }

  void updateSearchQuery(String query) {
    final currentState = state;
    if (currentState is! MedicinasLoaded) return;

    final updatedQuery = query.toLowerCase().trim();
    final updatedFiltered = _filterData(
      currentState.allMedicinas,
      updatedQuery,
      currentState.selectedEfectos,
    );

    emit(
      currentState.copyWith(
        searchQuery: query,
        filteredMedicinas: updatedFiltered,
      ),
    );
  }

  void toggleEfectoSecundario(EfectoSecundario efecto) {
    final currentState = state;
    if (currentState is! MedicinasLoaded) return;

    final updatedEfectos = Set<EfectoSecundario>.from(
      currentState.selectedEfectos,
    );
    if (updatedEfectos.contains(efecto)) {
      updatedEfectos.remove(efecto);
    } else {
      updatedEfectos.add(efecto);
    }

    final updatedFiltered = _filterData(
      currentState.allMedicinas,
      currentState.searchQuery.toLowerCase().trim(),
      updatedEfectos,
    );

    emit(
      currentState.copyWith(
        selectedEfectos: updatedEfectos,
        filteredMedicinas: updatedFiltered,
      ),
    );
  }

  List<Medicina> _filterData(
    List<Medicina> medicinas,
    String query,
    Set<EfectoSecundario> efectos,
  ) {
    return medicinas.where((m) {
      final matchesText =
          query.isEmpty || m.nombre.toLowerCase().contains(query);
      final matchesEfectos =
          efectos.isEmpty ||
          efectos.every((e) => m.efectosSecundarios.contains(e));

      return matchesText && matchesEfectos;
    }).toList();
  }
}
