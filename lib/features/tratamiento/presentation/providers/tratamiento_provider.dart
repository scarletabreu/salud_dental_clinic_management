import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'tratamiento_state.dart';

class TratamientoNotifier extends Notifier<TratamientoState> {
  late final TratamientoRepository _repository;

  @override
  TratamientoState build() {
    _repository = sl<TratamientoRepository>();
    return TratamientoInitial();
  }

  Future<void> loadTratamientos() async {
    state = TratamientoLoading();
    try {
      final lista = await _repository.getCatalogoTratamientos();
      state = TratamientoLoaded(lista);
    } catch (e) {
      state = TratamientoError('Error al cargar datos desde el servidor: $e');
    }
  }

  Future<bool> guardarTratamiento(Tratamiento tratamiento) async {
    if (state is! TratamientoLoaded) return false;
    final tratamientosActuales = (state as TratamientoLoaded).tratamientos;

    final existeDuplicado = tratamientosActuales.any(
      (t) =>
          t.nombre.trim().toLowerCase() ==
              tratamiento.nombre.trim().toLowerCase() &&
          t.id != tratamiento.id,
    );

    if (existeDuplicado) {
      state = TratamientoError(
        'Ya existe un tratamiento con el nombre "${tratamiento.nombre}".',
      );
      state = TratamientoLoaded(tratamientosActuales);
      return false;
    }

    try {
      await _repository.guardarTratamiento(tratamiento);
      await loadTratamientos();
      return true;
    } catch (e) {
      state = TratamientoError('Error al guardar el tratamiento: $e');
      state = TratamientoLoaded(tratamientosActuales);
      return false;
    }
  }

  Future<void> eliminarTratamiento(String id) async {
    if (state is! TratamientoLoaded) return;
    final tratamientosActuales = (state as TratamientoLoaded).tratamientos;

    try {
      await _repository.eliminarTratamiento(id);
      await loadTratamientos();
    } catch (e) {
      state = TratamientoError('Error al eliminar: $e');
      state = TratamientoLoaded(tratamientosActuales);
    }
  }

  /// Lista de tratamientos ficticios para pruebas locales de UI y flujo de formularios
  List<Tratamiento> _obtenerTratamientosPrueba() {
    return [
      Tratamiento(
        id: 'mock-uuid-1',
        nombre: 'Profilaxis Dental',
        descripcion:
            'Limpieza clínica profunda utilizando ultrasonido para eliminar sarro y placa bacteriana acumulada.',
        costo: 2500.00,
        alcance: Alcance.global,
        contraindicaciones: [],
      ),
      Tratamiento(
        id: 'mock-uuid-2',
        nombre: 'Endodoncia Unirradicular',
        descripcion:
            'Tratamiento de conducto en piezas dentales de una sola raíz para eliminar la pulpa afectada.',
        costo: 8500.00,
        alcance: Alcance.diente,
        contraindicaciones: [],
      ),
      Tratamiento(
        id: 'mock-uuid-3',
        nombre: 'Extracción Dental Simple',
        descripcion:
            'Remoción quirúrgica de una pieza dental con destrucción severa irreversible.',
        costo: 1800.00,
        alcance: Alcance.diente,
        contraindicaciones: [],
      ),
      Tratamiento(
        id: 'mock-uuid-4',
        nombre: 'Blanqueamiento Dental',
        descripcion:
            'Tratamiento estético aclarante en consultorio a base de peróxido de hidrógeno.',
        costo: 12000.00,
        alcance: Alcance.global,
        contraindicaciones: [],
      ),
    ];
  }
}

final tratamientoProvider =
    NotifierProvider<TratamientoNotifier, TratamientoState>(() {
      return TratamientoNotifier();
    });
