import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/repositories/regla_clinica_repository.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_state.dart';

class ReglasClinicasCubit extends Cubit<ReglasClinicasState> {
  final ReglaClinicaRepository _repository;
  StreamSubscription<void>? _senalReglas;

  ReglasClinicasCubit(this._repository, {SenalesRealtime? senales})
    : super(const ReglasClinicasInicial()) {
    // La versión publicada por otro admin llega sola a esta pantalla (MU-5).
    // Los umbrales que la BD impone en cada escritura no necesitan esto: los
    // triggers leen `reglas_clinicas` en el momento del guardado, así que un
    // cambio ya aplica a la siguiente consulta de todas las sesiones.
    _senalReglas = senales
        ?.de(DominioSenal.reglasClinicas)
        .listen((_) => _refrescarEnSilencio());
  }

  Future<void> _refrescarEnSilencio() async {
    final actual = state;
    // Con una publicación en vuelo no se pisa el estado: `publicar` ya
    // recarga desde la base al terminar.
    if (actual is! ReglasClinicasCargadas || actual.publicando != null) return;
    try {
      final reglas = await _repository.getReglasVigentes();
      final vigente = state;
      if (isClosed ||
          vigente is! ReglasClinicasCargadas ||
          vigente.publicando != null) {
        return;
      }
      emit(vigente.copyWith(reglas: reglas));
    } catch (e) {
      AppLog.error('refrescar las reglas clínicas', e);
    }
  }

  @override
  Future<void> close() async {
    await _senalReglas?.cancel();
    return super.close();
  }

  Future<void> cargar() async {
    if (isClosed) return;
    emit(const ReglasClinicasCargando());
    try {
      final reglas = await _repository.getReglasVigentes();
      final catalogo = await _repository.getCatalogoSignosVitales();
      if (isClosed) return;
      emit(ReglasClinicasCargadas(reglas: reglas, catalogo: catalogo));
    } on Failure catch (fallo) {
      if (isClosed) return;
      emit(ReglasClinicasError(fallo.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        const ReglasClinicasError(
          'No se pudieron cargar las reglas clínicas.',
        ),
      );
    }
  }

  /// Publica los cambios de una regla.
  ///
  /// Al terminar recarga desde la base en lugar de reemplazar la fila con lo
  /// que la pantalla creía haber enviado: la base normaliza, versiona y puede
  /// haber decidido que no había nada que cambiar. Pintar el optimismo local
  /// es exactamente lo que HFX-CLIN-005 vino a erradicar.
  Future<void> publicar(ReglaClinica regla, {String? nota}) async {
    final actual = state;
    if (actual is! ReglasClinicasCargadas) return;
    if (actual.publicando != null) return;

    emit(
      actual.copyWith(publicando: regla.codigo, limpiarMensajes: true),
    );

    try {
      final resultado = await _repository.publicar(regla, nota: nota);
      final reglas = await _repository.getReglasVigentes();
      if (isClosed) return;
      emit(
        actual.copyWith(
          reglas: reglas,
          limpiarPublicando: true,
          aviso: resultado.sinCambios
              ? 'La regla ya estaba así: no se publicó una versión nueva.'
              : 'Regla ${resultado.codigo} publicada como versión '
                    '${resultado.version}.',
        ),
      );
    } on Failure catch (fallo) {
      if (isClosed) return;
      emit(actual.copyWith(limpiarPublicando: true, error: fallo.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        actual.copyWith(
          limpiarPublicando: true,
          error: 'No se pudo publicar la regla.',
        ),
      );
    }
  }

  void descartarMensajes() {
    final actual = state;
    if (actual is ReglasClinicasCargadas) {
      emit(actual.copyWith(limpiarMensajes: true));
    }
  }
}
