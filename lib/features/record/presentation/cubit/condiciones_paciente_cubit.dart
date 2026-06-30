import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/agregar_condicion_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/get_condiciones_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/quitar_condicion_paciente.dart';
import 'condiciones_paciente_state.dart';

/// Gestiona las condiciones médicas de un paciente desde su expediente:
/// listar, agregar (del catálogo o creando una nueva) y quitar. Alimenta la
/// verificación de contraindicaciones en consulta (SD-85).
class CondicionesPacienteCubit extends Cubit<CondicionesPacienteState> {
  final String pacienteId;
  final GetCondicionesPaciente _getCondiciones;
  final AgregarCondicionPaciente _agregarCondicion;
  final QuitarCondicionPaciente _quitarCondicion;
  final CondicionRepository _catalogoRepository;

  CondicionesPacienteCubit({
    required this.pacienteId,
    required GetCondicionesPaciente getCondiciones,
    required AgregarCondicionPaciente agregarCondicion,
    required QuitarCondicionPaciente quitarCondicion,
    required CondicionRepository catalogoRepository,
  })  : _getCondiciones = getCondiciones,
        _agregarCondicion = agregarCondicion,
        _quitarCondicion = quitarCondicion,
        _catalogoRepository = catalogoRepository,
        super(const CondicionesPacienteLoading());

  Future<void> cargar() async {
    emit(const CondicionesPacienteLoading());
    try {
      final condiciones = await _getCondiciones(pacienteId);
      emit(CondicionesPacienteLoaded(condiciones));
    } catch (e) {
      emit(CondicionesPacienteError(e.toString()));
    }
  }

  /// Catálogo maestro para el selector de "Agregar".
  Future<List<Condicion>> catalogo() => _catalogoRepository.getCondiciones();

  Future<void> agregarExistente(String condicionId) async {
    await _mutar(() => _agregarCondicion(pacienteId, condicionId));
  }

  /// Crea una condición nueva en el catálogo y la asocia al paciente.
  Future<void> crearYAgregar(Condicion nueva) async {
    await _mutar(() async {
      final creada = await _catalogoRepository.registrarNuevaCondicion(nueva);
      if (creada.id != null) {
        await _agregarCondicion(pacienteId, creada.id!);
      }
    });
  }

  Future<void> quitar(String condicionId) async {
    await _mutar(() => _quitarCondicion(pacienteId, condicionId));
  }

  /// Marca `procesando`, ejecuta la mutación y recarga la lista. Conserva la
  /// lista actual en pantalla para no parpadear.
  Future<void> _mutar(Future<void> Function() accion) async {
    final actual = state;
    if (actual is CondicionesPacienteLoaded) {
      emit(actual.copyWith(procesando: true));
    }
    try {
      await accion();
      final condiciones = await _getCondiciones(pacienteId);
      emit(CondicionesPacienteLoaded(condiciones));
    } catch (e) {
      emit(CondicionesPacienteError(e.toString()));
    }
  }
}
