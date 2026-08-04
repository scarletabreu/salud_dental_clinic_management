import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'paciente_state.dart';

class PacienteCubit extends Cubit<PacienteState> {
  final IPacienteRepository _repository;
  final ConsultaRepository _consultaRepository;
  final CitaRepository _citaRepository;
  StreamSubscription<void>? _senalPacientes;

  /// Búsqueda activa del directorio. Vive aquí y no en el estado porque debe
  /// sobrevivir a las recargas: si el doctor tiene «Gómez» tecleado cuando el
  /// asistente crea una persona, la lista fresca se re-filtra con «Gómez» en
  /// vez de resetear la pantalla (MU-3).
  String _busqueda = '';

  PacienteCubit(
    this._repository,
    this._consultaRepository,
    this._citaRepository, {
    SenalesRealtime? senales,
  }) : super(const PacienteLoading()) {
    // Mecanismo B a propósito: la lista es grande y el cubit ya carga y
    // filtra bien; la señal sólo dice «recarga». El eco propio es inocuo:
    // quien crea ya recarga por su flujo y el debounce absorbe el resto.
    _senalPacientes = senales
        ?.de(DominioSenal.pacientes)
        .listen((_) => _refrescarDirectorio());
  }

  Future<void> load() async {
    emit(const PacienteLoading());
    final result = await _repository.getPacientes();

    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (list) => emit(
        PacienteLoaded(todos: list, filtrados: _filtrar(list, _busqueda)),
      ),
    );
  }

  /// Recarga silenciosa por señal: sólo cuando el directorio está en
  /// pantalla. El detalle de un paciente abierto no se pisa, y un fallo deja
  /// la lista como estaba (degradación = comportamiento previo).
  Future<void> _refrescarDirectorio() async {
    if (state is! PacienteLoaded) return;
    final result = await _repository.getPacientes();
    final vigente = state;
    if (isClosed || vigente is! PacienteLoaded) return;
    result.fold(
      (failure) =>
          AppLog.error('refrescar el directorio de pacientes', failure),
      (list) => emit(
        PacienteLoaded(todos: list, filtrados: _filtrar(list, _busqueda)),
      ),
    );
  }

  List<Paciente> _filtrar(List<Paciente> pacientes, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return pacientes;
    return pacientes.where((p) {
      return p.fullName.toLowerCase().contains(q) ||
          p.govID.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Future<void> close() async {
    await _senalPacientes?.cancel();
    return super.close();
  }

  Future<void> loadById(String id) async {
    emit(const PacienteDetailLoading());
    final result = await _repository.getPacienteById(id);

    await result.fold((failure) async => emit(PacienteError(failure.message)), (
      paciente,
    ) async {
      final (historial, piezas) = await (
        _historialDe(paciente.id),
        _historialDePiezas(paciente.id),
      ).wait;
      emit(
        PacienteDetailLoaded(
          paciente.copyWith(
            record: paciente.record.copyWith(consultas: historial.consultas),
          ),
          historialNoDisponible: historial.fallo,
          historialPiezas: piezas,
        ),
      );
    });
  }

  Future<bool> isPaciente(String id) async {
    final result = await _repository.faltaRegistro(id);

    return result.fold((failure) {
      emit(PacienteError(failure.message));
      return false;
    }, (success) => !success);
  }

  Future<_Historial> _historialDe(String? pacienteId) async {
    if (pacienteId == null) return const _Historial(const []);
    try {
      return _Historial(
        await _consultaRepository.getHistorialPaciente(pacienteId),
      );
    } catch (e) {
      AppLog.error('historial de $pacienteId', e);
      return const _Historial(const [], fallo: true);
    }
  }

  Future<HistorialPiezas> _historialDePiezas(String? pacienteId) async {
    if (pacienteId == null) return HistorialPiezas.vacio;
    try {
      return await _consultaRepository.getHistorialPiezas(pacienteId);
    } catch (e) {
      AppLog.error('historial de piezas de $pacienteId', e);
      return HistorialPiezas.vacio;
    }
  }

  Future<void> loadParaConsulta(String personaId) async {
    emit(const PacienteDetailLoading());
    final result = await _repository.getOrCreatePacienteByPersonaId(personaId);

    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (paciente) => emit(PacienteDetailLoaded(paciente)),
    );
  }

  void search(String query) {
    _busqueda = query;
    final current = state;
    if (current is! PacienteLoaded) return;

    emit(
      PacienteLoaded(
        todos: current.todos,
        filtrados: _filtrar(current.todos, query),
      ),
    );
  }

  Future<void> addPaciente(Paciente paciente) async {
    emit(const PacienteLoading());
    final result = await _repository.addPaciente(paciente);
    result.fold(
      (failure) => emit(PacienteError(failure.message)),
      (_) => emit(const PacienteOperationSuccess()),
    );
  }

  Future<void> updatePaciente(Paciente paciente, {Uint8List? fotoBytes}) async {
    emit(const PacienteLoading());

    Paciente pacienteAActualizar = paciente;

    if (fotoBytes != null && fotoBytes.isNotEmpty && paciente.id != null) {
      const int maxFotoBytes = 10 * 1024 * 1024;
      if (fotoBytes.length > maxFotoBytes) {
        emit(
          const PacienteError(
            'El tamaño de la imagen es superior a 10 MB. Por favor elige una foto de menor peso.',
          ),
        );
        return;
      }

      final uploadRes = await _repository.uploadFotoPaciente(
        pacienteId: paciente.id!,
        bytes: fotoBytes,
      );

      bool errorSubida = false;
      uploadRes.fold(
        (failure) {
          errorSubida = true;
          emit(
            const PacienteError(
              'No se pudo subir la fotografía. Asegúrate de que pese menos de 10 MB e intente nuevamente.',
            ),
          );
        },
        (publicUrl) {
          pacienteAActualizar = paciente.copyWith(
            fotoRuta: publicUrl,
            fotoMimeType: 'image/jpeg',
            fotoTamanoBytes: fotoBytes.length,
            fotoActualizadaEn: DateTime.now(),
          );
        },
      );

      if (errorSubida) return;
    }

    final result = await _repository.updatePaciente(pacienteAActualizar);
    result.fold((failure) {
      if (failure.message.contains('pacientes_foto_tamano_bytes_check')) {
        emit(
          const PacienteError(
            'El tamaño de la fotografía no es válido o excede el límite permitido. Por favor elige una foto de menor peso.',
          ),
        );
      } else {
        emit(PacienteError(failure.message));
      }
    }, (_) => emit(const PacienteOperationSuccess()));
  }

  Future<void> deletePaciente(String id) async {
    emit(const PacienteLoading());

    try {
      final citas = await _citaRepository.getCitasByPaciente(id);

      final citasPendientes = citas.where((cita) {
        return cita.estado != EstadoCita.completada &&
            cita.estado != EstadoCita.cancelada &&
            cita.estado != EstadoCita.noAsistio;
      }).toList();

      if (citasPendientes.isNotEmpty) {
        emit(
          PacienteError(
            'No se puede eliminar el paciente porque tiene ${citasPendientes.length} cita${citasPendientes.length != 1 ? 's' : ''} pendiente${citasPendientes.length != 1 ? 's' : ''}. '
            'Por favor, complete, cancele o marque como no asistida todas las citas antes de eliminar.',
          ),
        );
        return;
      }

      final result = await _repository.deletePaciente(id);
      result.fold(
        (failure) => emit(PacienteError(failure.message)),
        (_) => emit(const PacienteOperationSuccess()),
      );
    } catch (e) {
      emit(PacienteError('Error al verificar citas: $e'));
    }
  }
}

class _Historial {
  final List<Consulta> consultas;
  final bool fallo;

  const _Historial(this.consultas, {this.fallo = false});
}
