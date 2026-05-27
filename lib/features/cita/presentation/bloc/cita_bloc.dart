import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/usecases/create_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/usecases/delete_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/usecases/get_citas.dart';

part 'cita_event.dart';
part 'cita_state.dart';

class CitaBloc extends Bloc<CitaEvent, CitaState> {
  final GetCitas _getCitas;
  final CreateCita _createCita;
  final DeleteCita _deleteCita;

  CitaBloc(CitaRepository repository)
      : _getCitas = GetCitas(repository),
        _createCita = CreateCita(repository),
        _deleteCita = DeleteCita(repository),
        super(CitaInitial()) {
    on<LoadCitasEvent>(_onLoadCitas);
    on<CreateCitaEvent>(_onCreateCita);
    on<DeleteCitaEvent>(_onDeleteCita);
  }

  Future<void> _onLoadCitas(LoadCitasEvent event, Emitter<CitaState> emit) async {
    emit(CitaLoading());
    try {
      final citas = await _getCitas();
      emit(CitaLoaded(citas));
    } catch (e) {
      emit(CitaError('$e'));
    }
  }

  Future<void> _onCreateCita(CreateCitaEvent event, Emitter<CitaState> emit) async {
    final previous = state is CitaLoaded ? (state as CitaLoaded).citas : <Cita>[];
    emit(CitaLoading());
    try {
      await _createCita(event.cita);
      emit(CitaCreated());
      final updated = await _getCitas();
      emit(CitaLoaded(updated));
    } catch (e) {
      emit(CitaError('$e'));
      emit(CitaLoaded(previous));
    }
  }

  Future<void> _onDeleteCita(DeleteCitaEvent event, Emitter<CitaState> emit) async {
    final previous = state is CitaLoaded ? (state as CitaLoaded).citas : <Cita>[];
    try {
      await _deleteCita(event.id);
      final updated = await _getCitas();
      emit(CitaLoaded(updated));
    } catch (e) {
      emit(CitaError('$e'));
      emit(CitaLoaded(previous));
    }
  }
}