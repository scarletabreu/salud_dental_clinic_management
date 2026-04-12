import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/get_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/add_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/update_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/delete_medicina.dart';

part 'medicina_state.dart';

class MedicinaCubit extends Cubit<MedicinaState> {
  final GetMedicinas _getMedicinas;
  final AddMedicina _addMedicina;
  final UpdateMedicina _updateMedicina;
  final DeleteMedicina _deleteMedicina;

  MedicinaCubit({
    required GetMedicinas getMedicinas,
    required AddMedicina addMedicina,
    required UpdateMedicina updateMedicina,
    required DeleteMedicina deleteMedicina,
  })  : _getMedicinas = getMedicinas,
        _addMedicina = addMedicina,
        _updateMedicina = updateMedicina,
        _deleteMedicina = deleteMedicina,
        super(const MedicinaInitial());

  Future<void> loadMedicinas() async {
    emit(const MedicinaLoading());
    final result = await _getMedicinas();
    result.fold(
      (failure) => emit(MedicinaError(failure.message)),
      (medicinas) => emit(MedicinaLoaded(medicinas)),
    );
  }

  Future<void> addMedicina(Medicina medicina) async {
    emit(const MedicinaLoading());
    final result = await _addMedicina(medicina);
    result.fold(
      (failure) => emit(MedicinaError(failure.message)),
      (_) => loadMedicinas(),
    );
  }

  Future<void> updateMedicina(Medicina medicina) async {
    emit(const MedicinaLoading());
    final result = await _updateMedicina(medicina);
    result.fold(
      (failure) => emit(MedicinaError(failure.message)),
      (_) => loadMedicinas(),
    );
  }

  Future<void> deleteMedicina(String id) async {
    emit(const MedicinaLoading());
    final result = await _deleteMedicina(id);
    result.fold(
      (failure) => emit(MedicinaError(failure.message)),
      (_) => loadMedicinas(),
    );
  }
}
