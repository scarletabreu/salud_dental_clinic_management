import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/eliminar_suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/get_directorio_suplidores.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/guardar_suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_state.dart';

class SuplidorCubit extends Cubit<SuplidorState> {
  final GetDirectorioSuplidores _getDirectorio;
  final GuardarSuplidor _guardarSuplidor;
  final EliminarSuplidor _eliminarSuplidor;

  SuplidorCubit({
    required GetDirectorioSuplidores getDirectorio,
    required GuardarSuplidor guardarSuplidor,
    required EliminarSuplidor eliminarSuplidor,
  }) : _getDirectorio = getDirectorio,
       _guardarSuplidor = guardarSuplidor,
       _eliminarSuplidor = eliminarSuplidor,
       super(const SuplidorLoading());

  Future<void> cargar() async {
    emit(const SuplidorLoading());
    try {
      final list = await _getDirectorio();
      emit(SuplidorLoaded(suplidores: list));
    } catch (_) {
      emit(const SuplidorError('No se pudieron obtener los suplidores.'));
    }
  }

  void filtrarPorBusqueda(String query) {
    final currentState = state;
    if (currentState is SuplidorLoaded) {
      emit(currentState.copyWith(busqueda: query));
    }
  }

  Future<String?> guardar(Suplidor suplidor) async {
    try {
      await _guardarSuplidor(suplidor);
      await cargar();
      return null;
    } catch (e) {
      return 'Error al guardar el suplidor: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  Future<String?> eliminar(String id) async {
    try {
      await _eliminarSuplidor(id);
      await cargar();
      return null;
    } catch (e) {
      return 'Error al eliminar el suplidor.';
    }
  }
}
