import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
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

  PacienteCubit(
    this._repository,
    this._consultaRepository,
    this._citaRepository,
  ) : super(const PacienteLoading());

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
