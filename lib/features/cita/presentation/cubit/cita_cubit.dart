import 'dart:async';

import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/core/util/metricas_clinicas.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/cancelacion_con_consulta_abierta.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/errors/transicion_estado_invalida.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/consulta_abierta_lookup.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';
import 'cita_cubit_state.dart';

class CitaCubit extends Cubit<CitaCubitState> {
  final CitaRepository _repository;
  final ConsultaAbiertaLookup? _consultas;
  List<String>? _doctorIdsPermitidos;
  String? _restringidoADoctorId;
  StreamSubscription<List<Cita>>? _citasDeHoyEnVivo;

  /// Meses cargados a cada lado del día enfocado.
  ///
  /// Traer toda la historia de la clínica en cada apertura de la agenda es la
  /// bomba de tiempo del §1.3: hoy no se nota y con dos años de operación
  /// degrada linealmente. La ventana sigue a la navegación, así que moverse por
  /// el calendario nunca deja huecos.
  static const _mesesDeMargen = 3;

  DateTime? _ventanaDesde;
  DateTime? _ventanaHasta;

  void _fijarVentana(DateTime centro) {
    _ventanaDesde = DateTime(centro.year, centro.month - _mesesDeMargen, 1);
    _ventanaHasta = DateTime(centro.year, centro.month + _mesesDeMargen + 1, 1);
  }

  /// `true` si [dia] cae fuera del mes central de la ventana cargada: es el
  /// momento de traer la siguiente tanda, antes de que el usuario llegue al
  /// borde y vea días vacíos.
  bool _fueraDeVentana(DateTime dia) {
    final desde = _ventanaDesde;
    final hasta = _ventanaHasta;
    if (desde == null || hasta == null) return true;
    return dia.isBefore(desde.add(const Duration(days: 31))) ||
        !dia.isBefore(hasta.subtract(const Duration(days: 31)));
  }

  Future<void> _asegurarVentana(DateTime dia) async {
    if (!_fueraDeVentana(dia)) return;
    _fijarVentana(dia);
    final current = state;
    if (current is! CitaCubitLoaded) return;
    try {
      final citas = _aplicarFiltroDoctor(await _cargarSegunAlcance());
      if (isClosed) return;
      final vigente = state;
      if (vigente is! CitaCubitLoaded) return;
      emit(
        vigente.copyWith(
          citas: _aplicarFiltroDeVista(citas),
          todas: citas,
          consultasPorCitaId: await _consultasDe(citas),
        ),
      );
    } catch (e) {
      AppLog.error('ampliar la ventana de la agenda', e);
    }
  }

  CitaCubit(this._repository, [this._consultas])
    : super(const CitaCubitLoading());

  Future<void> load({
    String? restringidoADoctorId,
    List<String>? doctorIdsPermitidos,
  }) async {
    if (isClosed) return;

    // El alcance se fija en la primera carga y sobrevive a los `load()` sin
    // argumentos que hacen las pantallas al refrescar.
    if (restringidoADoctorId != null) {
      _restringidoADoctorId = restringidoADoctorId;
      _doctorIdsPermitidos = [restringidoADoctorId];
    } else if (doctorIdsPermitidos != null) {
      _doctorIdsPermitidos = doctorIdsPermitidos;
    }

    emit(const CitaCubitLoading());
    _fijarVentana(DateTime.now());
    try {
      // La agenda es lo primero que se abre cada mañana: si va lenta, se nota
      // aquí antes que en ningún otro sitio. La medición no lleva ni el doctor
      // ni las citas, sólo cuánto tardó (HFX-CLIN-005).
      final (citasFiltradas, consultas) = await MetricasClinicas.medir(
        OperacionClinica.agendaCargada,
        () async {
          final citas = await _cargarSegunAlcance();
          final filtradas = _aplicarFiltroDoctor(citas);
          return (filtradas, await _consultasDe(filtradas));
        },
      );
      if (isClosed) return;
      final now = DateTime.now();
      emit(
        CitaCubitLoaded(
          citas: _aplicarFiltroDeVista(citasFiltradas),
          todas: citasFiltradas,
          doctorIdFiltro: _doctorIdFiltro,
          focusedDay: now,
          selectedDay: now,
          viewMode: CalendarioViewMode.mensual,
          consultasPorCitaId: consultas,
          sinDoctoresAsignados:
              _restringidoADoctorId == null &&
              (_doctorIdsPermitidos?.isEmpty ?? false),
        ),
      );
      _escucharCitasDeHoy();
    } catch (e) {
      if (isClosed) return;
      emit(CitaCubitError(e.toString()));
    }
  }

  /// La jornada del día se mantiene sola (MU-1): llegada marcada por el
  /// asistente, consulta iniciada por el doctor, reagendas y cancelaciones
  /// aparecen sin refrescar. Si el stream falla, la agenda se queda como
  /// estaba —el comportamiento previo— y los botones de refresh siguen ahí.
  void _escucharCitasDeHoy() {
    if (_citasDeHoyEnVivo != null) return;
    try {
      _citasDeHoyEnVivo = _repository.watchCitasDeHoy().listen(
        _integrarCitasDeHoy,
        onError: (Object e) => AppLog.error('citas de hoy en vivo', e),
      );
    } catch (e) {
      // Sin stream no hay agenda viva, pero la carga ya salió bien: se queda
      // el comportamiento de siempre (datos del load + refresh manual).
      AppLog.error('suscribirse a las citas de hoy', e);
    }
  }

  Future<void> _integrarCitasDeHoy(List<Cita> deHoy) async {
    if (state is! CitaCubitLoaded) return;
    // El techo de seguridad se re-aplica a lo que llega por el stream: RLS ya
    // recortó en el servidor, pero el asistente filtra su lista de doctores
    // en memoria y ese recorte también vale para los eventos.
    final visibles = _aplicarFiltroDoctor(deHoy);
    final consultasDeHoy = await _consultasDe(visibles);
    if (isClosed) return;
    final vigente = state;
    if (vigente is! CitaCubitLoaded) return;

    final hoy = DateTime.now();
    final resto = vigente.citasSinFiltrar
        .where((c) => !_esMismoDia(c.date, hoy))
        .toList();
    final todas = [...resto, ...visibles];
    emit(
      vigente.copyWith(
        citas: _aplicarFiltroDeVista(todas),
        todas: todas,
        consultasPorCitaId: {
          ...vigente.consultasPorCitaId,
          ...consultasDeHoy,
        },
      ),
    );
  }

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Mensaje apto para pantalla: los [Failure] ya vienen redactados para una
  /// persona (solape, permisos, red); el resto conserva su contexto.
  String _mensajeDe(Object e, String contexto) =>
      e is Failure ? e.message : '$contexto: $e';

  @override
  Future<void> close() async {
    await _citasDeHoyEnVivo?.cancel();
    return super.close();
  }

  /// Un doctor pide al servidor solo sus citas, igual que la lista de consultas
  /// pide `getConsultasByDoctor` (SD-160): la misma regla en los dos listados,
  /// y así ninguna agenda ajena viaja al cliente para descartarse después.
  ///
  /// El alcance del asistente abarca varios doctores y no hay filtro remoto
  /// equivalente, así que ahí sí se recorta en memoria.
  Future<List<Cita>> _cargarSegunAlcance() {
    final soloDoctor = _restringidoADoctorId;
    if (soloDoctor != null) {
      return _repository.getCitasByDoctor(
        soloDoctor,
        desde: _ventanaDesde,
        hasta: _ventanaHasta,
      );
    }
    return _repository.getCitas(desde: _ventanaDesde, hasta: _ventanaHasta);
  }

  /// Consulta de cada cita, para que la agenda pueda enlazarla (SD-160). Es
  /// información accesoria: si falla, las citas se muestran igual y solo se
  /// pierde el enlace.
  Future<Map<String, ConsultaDeCita>> _consultasDe(List<Cita> citas) async {
    final lookup = _consultas;
    if (lookup == null) return const {};
    final ids = [for (final c in citas) ?c.id];
    if (ids.isEmpty) return const {};
    try {
      return await lookup.paraCitas(ids);
    } catch (e) {
      AppLog.error('consultas de las citas', e);
      return const {};
    }
  }

  List<Cita> _aplicarFiltroDoctor(List<Cita> citas) {
    final permitidos = _doctorIdsPermitidos;
    if (permitidos == null) return citas;
    return citas.where((c) => permitidos.contains(c.doctor.id)).toList();
  }

  /// Preferencia de vista, no techo de seguridad: sólo recorta lo que ya se
  /// tenía derecho a ver. Los dos filtros son distintos a propósito (D15).
  String? _doctorIdFiltro;

  List<Cita> _aplicarFiltroDeVista(List<Cita> citas) {
    final filtro = _doctorIdFiltro;
    if (filtro == null) return citas;
    return citas.where((c) => c.doctor.id == filtro).toList();
  }

  /// `null` para volver a «todos los odontólogos».
  void filtrarPorDoctor(String? doctorId) {
    _doctorIdFiltro = doctorId;
    final actual = state;
    if (actual is! CitaCubitLoaded) return;
    emit(
      actual.copyWith(
        citas: _aplicarFiltroDeVista(actual.citasSinFiltrar),
        doctorIdFiltro: () => doctorId,
      ),
    );
  }

  /// Aviso temprano de solapamiento, para no hacer ir al servidor a por un «no».
  ///
  /// La autoridad es la restricción `citas_sin_solape` (HFX-CLIN-004); esta
  /// comprobación replica exactamente su alcance para no rechazar aquí lo que
  /// la base sí aceptaría: los estados terminales ya no reservan el hueco, y una
  /// urgencia no reserva agenda, la interrumpe.
  bool _tieneConflictoHorario(Cita nuevaCita, List<Cita> todasLasCitas) {
    if (nuevaCita.esEmergencia) return false;
    return todasLasCitas.any((c) {
      if (c.id == nuevaCita.id) return false;
      if (c.doctor.id != nuevaCita.doctor.id) return false;
      if (c.esEmergencia) return false;
      if (c.estado == EstadoCita.cancelada ||
          c.estado == EstadoCita.completada ||
          c.estado == EstadoCita.noAsistio) {
        return false;
      }

      return nuevaCita.date.isBefore(c.fechaFin) &&
          c.date.isBefore(nuevaCita.fechaFin);
    });
  }

  Future<void> createCita(Cita cita) async {
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      if (!isClosed) {
        emit(current.copyWith(isSubmitting: true, errorMessage: () => null));
      }

      if (_tieneConflictoHorario(cita, current.citas)) {
        if (!isClosed) {
          emit(
            current.copyWith(
              isSubmitting: false,
              errorMessage: () =>
                  'El odontólogo elegido ya tiene una cita programada en ese horario.',
            ),
          );
        }
        return;
      }

      await _repository.createCita(cita);
      await load();
    } catch (e) {
      AppLog.error('crearCita', e);
      // El caso típico es que otro usuario ocupó el hueco mientras se llenaba
      // el formulario: el mapper ya lo redacta («Ese horario ya está
      // ocupado…») y la cita que lo tomó llega sola por el stream del día.
      if (!isClosed) {
        emit(
          current.copyWith(
            isSubmitting: false,
            errorMessage: () => _mensajeDe(e, 'No se pudo crear la cita'),
          ),
        );
      }
    }
  }

  /// Marca que el paciente ya llegó. Es la puerta a «Iniciar consulta», y desde
  /// HFX-CLIN-004 puede abrirla el propio doctor: trabajar sin asistente dejó de
  /// significar quedarse fuera de la consulta.
  Future<void> registrarLlegada(String citaId) async {
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      await _repository.registrarLlegada(citaId);
      final todas = [
        for (final cita in current.citasSinFiltrar)
          cita.id == citaId
              ? cita.copyWith(estado: EstadoCita.enEspera)
              : cita,
      ];
      emit(
        current.copyWith(citas: _aplicarFiltroDeVista(todas), todas: todas),
      );
    } catch (e) {
      AppLog.error('registrarLlegada', e);
      emit(
        current.copyWith(
          errorMessage: () =>
              _mensajeDe(e, 'No se pudo registrar la llegada'),
        ),
      );
    }
  }

  /// Registra una urgencia para un paciente que ya está en la clínica y
  /// devuelve su cita, para poder entrar directamente a la consulta.
  ///
  /// Devuelve `null` si falló; el motivo queda en `errorMessage`.
  Future<String?> registrarEmergencia({
    required String pacienteId,
    required String doctorId,
    String? motivo,
  }) async {
    final current = state;
    if (current is! CitaCubitLoaded) return null;

    try {
      final citaId = await _repository.registrarEmergencia(
        pacienteId: pacienteId,
        doctorId: doctorId,
        motivo: motivo,
      );
      await load();
      return citaId;
    } catch (e) {
      AppLog.error('registrarEmergencia', e);
      if (!isClosed) {
        emit(
          current.copyWith(
            errorMessage: () =>
                _mensajeDe(e, 'No se pudo registrar la emergencia'),
          ),
        );
      }
      return null;
    }
  }

  Future<void> cambiarEstadoCita(String id, EstadoCita nuevoEstado) async {
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      await _repository.updateCitaEstado(id, nuevoEstado);

      final todas = [
        for (final cita in current.citasSinFiltrar)
          cita.id == id ? cita.copyWith(estado: nuevoEstado) : cita,
      ];
      emit(
        current.copyWith(citas: _aplicarFiltroDeVista(todas), todas: todas),
      );
    } on CancelacionConConsultaAbierta catch (e) {
      // Motivo accionable: el usuario tiene que cerrar la consulta primero. Un
      // "no se pudo actualizar: <excepción>" no le diría qué hacer.
      emit(current.copyWith(errorMessage: e.toString));
    } on TransicionEstadoInvalida catch (e) {
      // Otro usuario movió la cita primero. El mensaje ya nombra el estado
      // real («No se puede pasar de "Cancelada" a…») y la tarjeta se corrige
      // a lo que hay en la base, no a lo que esta sesión creía.
      final todas = [
        for (final cita in current.citasSinFiltrar)
          cita.id == id ? cita.copyWith(estado: e.actual) : cita,
      ];
      emit(
        current.copyWith(
          errorMessage: e.toString,
          citas: _aplicarFiltroDeVista(todas),
          todas: todas,
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          errorMessage: () =>
              _mensajeDe(e, 'No se pudo actualizar el estado de la cita'),
        ),
      );
    }
  }

  void selectDay(DateTime selectedDay, DateTime focusedDay) {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    emit(
      current.copyWith(
        selectedDay: selectedDay,
        focusedDay: focusedDay,
        errorMessage: () => null,
      ),
    );
  }

  void onPageChanged(DateTime focusedDay) {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    emit(current.copyWith(focusedDay: focusedDay));
    _asegurarVentana(focusedDay);
  }

  void changeViewMode(CalendarioViewMode mode) {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    emit(current.copyWith(viewMode: mode));
  }

  void goToToday() {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    final now = DateTime.now();
    emit(current.copyWith(focusedDay: now, selectedDay: now));
  }

  void goToNext() {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    if (current.viewMode == CalendarioViewMode.diaria) {
      final next = current.selectedDay.add(const Duration(days: 1));
      emit(current.copyWith(focusedDay: next, selectedDay: next));
      _asegurarVentana(next);
      return;
    }
    final next = current.viewMode == CalendarioViewMode.mensual
        ? DateTime(current.focusedDay.year, current.focusedDay.month + 1, 1)
        : current.focusedDay.add(const Duration(days: 7));
    emit(current.copyWith(focusedDay: next));
    _asegurarVentana(next);
  }

  void goPrevious() {
    final current = state;
    if (current is! CitaCubitLoaded) return;
    if (current.viewMode == CalendarioViewMode.diaria) {
      final prev = current.selectedDay.subtract(const Duration(days: 1));
      emit(current.copyWith(focusedDay: prev, selectedDay: prev));
      _asegurarVentana(prev);
      return;
    }
    final prev = current.viewMode == CalendarioViewMode.mensual
        ? DateTime(current.focusedDay.year, current.focusedDay.month - 1, 1)
        : current.focusedDay.subtract(const Duration(days: 7));
    emit(current.copyWith(focusedDay: prev));
    _asegurarVentana(prev);
  }

  List<Cita> eventLoader(DateTime day) {
    final current = state;
    if (current is! CitaCubitLoaded) return [];
    return current.citasForDay(day);
  }

  Future<void> actualizarCita(Cita citaActualizada) async {
    final current = state;
    if (current is! CitaCubitLoaded) return;

    try {
      emit(current.copyWith(isSubmitting: true, errorMessage: () => null));

      final tieneChoque = current.citas.any((c) {
        if (c.id == citaActualizada.id) return false;
        if (c.doctor.id != citaActualizada.doctor.id) return false;

        return citaActualizada.date.isBefore(c.fechaFin) &&
            c.date.isBefore(citaActualizada.fechaFin);
      });

      if (tieneChoque) {
        emit(
          current.copyWith(
            isSubmitting: false,
            errorMessage: () =>
                'El odontólogo elegido no tiene disponibilidad en este horario.',
          ),
        );
        return;
      }

      await _repository.updateCita(citaActualizada);

      final citasActualizadas = _aplicarFiltroDoctor(
        await _cargarSegunAlcance(),
      );

      emit(
        current.copyWith(
          citas: _aplicarFiltroDeVista(citasActualizadas),
          todas: citasActualizadas,
          isSubmitting: false,
          errorMessage: () => null,
          consultasPorCitaId: await _consultasDe(citasActualizadas),
        ),
      );
    } catch (e) {
      AppLog.error('actualizarCita', e);
      emit(
        current.copyWith(
          isSubmitting: false,
          errorMessage: () =>
              _mensajeDe(e, 'No se pudieron guardar los cambios de la cita'),
        ),
      );
    }
  }
}
