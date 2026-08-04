import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/capacidades_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/services/alerta_operativa_generator.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final CitaRepository _citaRepository;
  final IPacienteRepository _pacienteRepository;
  final IMedicinaRepository _medicinaRepository;
  final ConsumibleRepository _consumibleRepository;
  final CajaDiariaRepository _cajaDiariaRepository;
  final EquipoRepository _equipoRepository;
  final AlertaOperativaGenerator _alertaGenerator;

  List<RolUsuario> _roles = const [];
  String? _doctorId;
  String? _doctorName;

  // AÑADIDO: cache del último histórico completo cargado (no solo "hoy"),
  // para poder recalcular hoy/semana/mes y alertas en updateEstado sin
  // volver a golpear el backend.
  List<Cita> _citasCache = const [];
  List<Consumible> _consumiblesCache = const [];
  List<Equipo> _equiposCache = const [];
  CajaDiaria? _cajaActualCache;

  DashboardCubit({
    required CitaRepository citaRepository,
    required IPacienteRepository pacienteRepository,
    required IMedicinaRepository medicinaRepository,
    required ConsumibleRepository consumibleRepository,
    required CajaDiariaRepository cajaDiariaRepository,
    required EquipoRepository equipoRepository,
    AlertaOperativaGenerator alertaGenerator = const AlertaOperativaGenerator(),
  }) : _citaRepository = citaRepository,
       _pacienteRepository = pacienteRepository,
       _medicinaRepository = medicinaRepository,
       _consumibleRepository = consumibleRepository,
       _cajaDiariaRepository = cajaDiariaRepository,
       _equipoRepository = equipoRepository,
       _alertaGenerator = alertaGenerator,
       super(const DashboardLoading());

  Future<void> load({
    required List<RolUsuario> roles,
    String? doctorId,
    String? doctorName,
  }) async {
    emit(const DashboardLoading());
    try {
      _roles = roles;
      _doctorId = doctorId;
      _doctorName = doctorName;

      final esClinico = roles.puedeEjercerClinica;
      final gestionaAgendaCompleta = roles.puedeGestionarAgendaCompleta;
      final tieneAccesoOperativo = roles.puedeGestionarCaja;

      // Quien gestiona la agenda completa la ve entera; el clínico que no la
      // gestiona ve la suya.
      //
      // El rango se acota en el servidor: el tablero sólo mide hoy, esta semana
      // y este mes, y traer toda la historia de la clínica para contar tres
      // números degradaba con cada año de operación (§1.3). La ventana empieza
      // en el primero de la semana o del mes —lo que caiga antes— para que
      // ninguna de las tres cifras quede corta.
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final inicioDeSemana = _inicioSemana(ahora);
      final desde = inicioDeSemana.isBefore(inicioMes)
          ? inicioDeSemana
          : inicioMes;
      final hasta = DateTime(ahora.year, ahora.month + 1, 1);

      final citas = (esClinico && !gestionaAgendaCompleta && doctorId != null)
          ? await _citaRepository.getCitasByDoctor(
              doctorId,
              desde: desde,
              hasta: hasta,
            )
          : await _citaRepository.getCitas(desde: desde, hasta: hasta);

      final pacientesResult = await _pacienteRepository.getPacientes();
      final totalPacientes = pacientesResult.fold(
        (_) => 0,
        (list) => list.length,
      );

      final medicinas = roles.puedeGestionarCatalogosClinicos
          ? await _medicinaRepository.getCatalogoMedicinas()
          : <dynamic>[];

      final consumibles = tieneAccesoOperativo
          ? await _consumibleRepository.getInventario()
          : const <Consumible>[];
      final cajaActual = tieneAccesoOperativo
          ? await _cajaDiariaRepository.getCajaActual()
          : null;
      final equipos = tieneAccesoOperativo
          ? await _equipoRepository.getInventarioEquipos()
          : const <Equipo>[];

      _citasCache = citas;
      _consumiblesCache = consumibles;
      _cajaActualCache = cajaActual;
      _equiposCache = equipos;

      emit(
        _construirEstado(
          roles: roles,
          nombreDoctor: doctorName,
          citas: citas,
          consumibles: consumibles,
          cajaActual: cajaActual,
          equipos: equipos,
          totalPacientes: totalPacientes,
          totalMedicinas: medicinas.length,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> updateEstado(String citaId, EstadoCita nuevoEstado) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    // CORREGIDO: se actualiza el histórico completo en cache, no solo
    // "citasDeHoy", para que semana/mes y alertas queden consistentes.
    _citasCache = _citasCache
        .map((c) => c.id == citaId ? c.copyWith(estado: nuevoEstado) : c)
        .toList();

    emit(
      _construirEstado(
        roles: current.roles,
        nombreDoctor: current.nombreDoctor,
        citas: _citasCache,
        consumibles: _consumiblesCache,
        cajaActual: _cajaActualCache,
        equipos: _equiposCache,
        totalPacientes: current.totalPacientes,
        totalMedicinas: current.totalMedicinas,
      ),
    );

    try {
      await _citaRepository.updateCitaEstado(citaId, nuevoEstado);
    } catch (_) {
      await load(roles: _roles, doctorId: _doctorId, doctorName: _doctorName);
    }
  }

  // AÑADIDO: único punto que arma el DashboardLoaded, usado por load() y
  // updateEstado() — evita la duplicación de conteos que había antes.
  DashboardLoaded _construirEstado({
    required List<RolUsuario> roles,
    String? nombreDoctor,
    required List<Cita> citas,
    required List<Consumible> consumibles,
    CajaDiaria? cajaActual,
    List<Equipo> equipos = const [],
    required int totalPacientes,
    required int totalMedicinas,
  }) {
    final now = DateTime.now();

    final citasDeHoy = citas.where((c) => _esMismoDia(c.date, now)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final inicioSemana = _inicioSemana(now);
    final finSemana = inicioSemana.add(const Duration(days: 7));
    final citasCanceladasHoy = _contarPorEstado(
      citasDeHoy,
      EstadoCita.cancelada,
    );
    final citasSemana = citas
        .where(
          (c) => !c.date.isBefore(inicioSemana) && c.date.isBefore(finSemana),
        )
        .toList();

    final citasMes = citas
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .toList();

    final consumiblesAgotados = consumibles.where((c) => c.estaAgotado).length;
    final consumiblesBajoStock = consumibles
        .where((c) => c.estaBajoStock && !c.estaAgotado)
        .length;
    final consumiblesNormal =
        consumibles.length - consumiblesAgotados - consumiblesBajoStock;

    final alertas = _alertaGenerator.generar(
      citasDeHoy: citasDeHoy,
      consumibles: consumibles,
      cajaActual: cajaActual,
      equipos: equipos,
      ahora: now,
    );

    return DashboardLoaded(
      roles: roles,
      nombreDoctor: nombreDoctor,
      citasHoy: citasDeHoy.length,
      citasPendientes: _contarPorEstado(citasDeHoy, EstadoCita.programada),
      citasEnEspera: _contarPorEstado(citasDeHoy, EstadoCita.enEspera),
      citasCompletadas: _contarPorEstado(citasDeHoy, EstadoCita.completada),
      citasCanceladas: citasCanceladasHoy,
      totalPacientes: totalPacientes,
      totalMedicinas: totalMedicinas,
      citasDeHoy: citasDeHoy,
      citasSemanaPendientes: _contarPorEstado(
        citasSemana,
        EstadoCita.programada,
      ),
      citasSemanaEnEspera: _contarPorEstado(citasSemana, EstadoCita.enEspera),
      citasSemanaCompletadas: _contarPorEstado(
        citasSemana,
        EstadoCita.completada,
      ),
      citasMesPendientes: _contarPorEstado(citasMes, EstadoCita.programada),
      citasMesEnEspera: _contarPorEstado(citasMes, EstadoCita.enEspera),
      citasMesCompletadas: _contarPorEstado(citasMes, EstadoCita.completada),
      consumiblesNormal: consumiblesNormal,
      consumiblesBajoStock: consumiblesBajoStock,
      consumiblesAgotados: consumiblesAgotados,
      alertas: alertas,
    );
  }

  int _contarPorEstado(List<Cita> citas, EstadoCita estado) =>
      citas.where((c) => c.estado == estado).length;

  bool _esMismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Lunes 00:00 de la semana que contiene [fecha] (semana ISO).
  DateTime _inicioSemana(DateTime fecha) {
    final soloFecha = DateTime(fecha.year, fecha.month, fecha.day);
    return soloFecha.subtract(Duration(days: soloFecha.weekday - 1));
  }
}
