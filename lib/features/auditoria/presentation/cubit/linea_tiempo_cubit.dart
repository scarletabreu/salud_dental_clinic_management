import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/metricas_clinicas.dart';
import 'package:salud_dental_clinic_management/features/auditoria/domain/repositories/auditoria_repository.dart';
import 'package:salud_dental_clinic_management/features/auditoria/presentation/cubit/linea_tiempo_state.dart';

class LineaTiempoCubit extends Cubit<LineaTiempoState> {
  final AuditoriaRepository _repository;

  LineaTiempoCubit(this._repository) : super(const LineaTiempoInicial());

  Future<void> cargar(String consultaId) async {
    if (isClosed) return;
    emit(const LineaTiempoCargando());
    try {
      final eventos = await MetricasClinicas.medir(
        OperacionClinica.lineaTiempoCargada,
        () => _repository.getLineaTiempo(consultaId),
        codigoDeError: (error) => error is Failure ? 'FALLO' : null,
      );
      if (isClosed) return;
      emit(LineaTiempoCargada(eventos));
    } on Failure catch (fallo) {
      if (isClosed) return;
      emit(LineaTiempoError(fallo.message));
    } catch (_) {
      if (isClosed) return;
      // El mensaje no lleva el error crudo: en esta pantalla el payload puede
      // contener datos del paciente y la consola no es sitio para eso.
      emit(
        const LineaTiempoError(
          'No se pudo cargar el historial de esta consulta.',
        ),
      );
    }
  }
}
