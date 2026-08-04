import 'dart:async';

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'cuentas_por_cobrar_state.dart';

class CuentasPorCobrarCubit extends Cubit<CuentasPorCobrarState> {
  final CuentaRepository _repository;
  final IPacienteRepository _pacienteRepository;

  /// Nombre por `paciente_id`. Se resuelve una vez por carga y sobrevive a los
  /// filtros, que sólo recortan la lista ya traída.
  Map<String, String> _nombres = const {};

  StreamSubscription<void>? _senalCuentas;

  CuentasPorCobrarCubit(
    this._repository,
    this._pacienteRepository, {
    SenalesRealtime? senales,
  }) : super(const CuentasPorCobrarInitial()) {
    // El mostrador se entera solo (MU-2): `finalizar_consulta` crea la
    // pre-factura en otra sesión y la cuenta aparece aquí sin refrescar; un
    // cobro o una anulación ajenos actualizan saldo y estado.
    _senalCuentas = senales
        ?.de(DominioSenal.cuentas)
        .listen((_) => _refrescarEnSilencio());
  }

  /// Recarga la lista sin pasar por `Loading` y sin perder lo que el usuario
  /// tiene entre manos: la búsqueda y los filtros activos se re-aplican sobre
  /// la lista fresca. Los nombres sólo se piden para los pacientes que aún no
  /// están en el mapa (una cuenta nueva), no para toda la lista.
  Future<void> _refrescarEnSilencio() async {
    final current = state;
    if (current is! CuentasPorCobrarLoaded ||
        current is CuentasPorCobrarOperating) {
      return;
    }
    try {
      final cuentas = await _repository.getCuentasPorCobrar();
      await _completarNombres(cuentas);
      final vigente = state;
      if (isClosed || vigente is! CuentasPorCobrarLoaded) return;
      _evaluarYEmitir(
        cuentas: cuentas,
        query: vigente.searchQuery,
        estado: vigente.filtroEstado,
        orden: vigente.orden,
        rangoCreacion: vigente.rangoCreacion,
        rangoVencimiento: vigente.rangoVencimiento,
        soloCuotasVencidas: vigente.soloCuotasVencidas,
        montoMin: vigente.montoPendienteMin,
      );
    } catch (e) {
      // La lista conserva lo último que sí cargó.
      AppLog.error('refrescar cuentas por cobrar', e);
    }
  }

  Future<void> _completarNombres(List<Cuenta> cuentas) async {
    final faltantes = {
      for (final cuenta in cuentas)
        if (cuenta.pacienteId != null &&
            !_nombres.containsKey(cuenta.pacienteId))
          cuenta.pacienteId!,
    }.toList();
    if (faltantes.isEmpty) return;
    final resultado = await _pacienteRepository.getNombresPacientes(faltantes);
    resultado.fold((_) {}, (nuevos) => _nombres = {..._nombres, ...nuevos});
  }

  @override
  Future<void> close() async {
    await _senalCuentas?.cancel();
    return super.close();
  }

  Future<void> cargarCuentas() async {
    emit(const CuentasPorCobrarLoading());
    try {
      final cuentas = await _repository.getCuentasPorCobrar();
      _nombres = await _cargarNombres(cuentas);
      _evaluarYEmitir(cuentas: cuentas);
    } catch (e) {
      emit(CuentasPorCobrarError('Error al cargar cuentas por cobrar: $e'));
    }
  }

  /// Los nombres salen del directorio de pacientes, igual que en el listado de
  /// consultas: es la vista que atraviesa el recorte de `puede_ver_paciente`
  /// para poder poner un nombre en una fila cuyo expediente el rol no abre.
  /// Si falla, la lista se pinta igual con la referencia de la consulta.
  Future<Map<String, String>> _cargarNombres(List<Cuenta> cuentas) async {
    final ids = {
      for (final cuenta in cuentas)
        if (cuenta.pacienteId != null) cuenta.pacienteId!,
    }.toList();
    if (ids.isEmpty) return const {};
    final resultado = await _pacienteRepository.getNombresPacientes(ids);
    return resultado.fold(
      (_) => const <String, String>{},
      (nombres) => nombres,
    );
  }

  void aplicarFiltros({
    String? query,
    EstadoCuenta? Function()? estado,
    OrdenCuenta? orden,
    DateTimeRange? Function()? rangoCreacion,
    DateTimeRange? Function()? rangoVencimiento,
    bool? soloCuotasVencidas,
    double? Function()? montoPendienteMin,
  }) {
    if (state is! CuentasPorCobrarLoaded) return;
    final current = state as CuentasPorCobrarLoaded;

    final updated = current.copyWith(
      searchQuery: query,
      filtroEstado: estado,
      orden: orden,
      rangoCreacion: rangoCreacion,
      rangoVencimiento: rangoVencimiento,
      soloCuotasVencidas: soloCuotasVencidas,
      montoPendienteMin: montoPendienteMin,
    );

    _evaluarYEmitir(
      cuentas: updated.todas,
      query: updated.searchQuery,
      estado: updated.filtroEstado,
      orden: updated.orden,
      rangoCreacion: updated.rangoCreacion,
      rangoVencimiento: updated.rangoVencimiento,
      soloCuotasVencidas: updated.soloCuotasVencidas,
      montoMin: updated.montoPendienteMin,
    );
  }

  void limpiarFiltros() {
    if (state is! CuentasPorCobrarLoaded) return;
    final current = state as CuentasPorCobrarLoaded;
    _evaluarYEmitir(cuentas: current.todas);
  }

  Future<bool> eliminarCuenta(String id) async {
    if (state is! CuentasPorCobrarLoaded) return false;
    final current = state as CuentasPorCobrarLoaded;

    emit(
      CuentasPorCobrarOperating(
        todas: current.todas,
        filtradas: current.filtradas,
        searchQuery: current.searchQuery,
        filtroEstado: current.filtroEstado,
        orden: current.orden,
        rangoCreacion: current.rangoCreacion,
        rangoVencimiento: current.rangoVencimiento,
        soloCuotasVencidas: current.soloCuotasVencidas,
        montoPendienteMin: current.montoPendienteMin,
        totalPorCobrar: current.totalPorCobrar,
        totalCobrado: current.totalCobrado,
      ),
    );

    try {
      await _repository.eliminarCuenta(id);
      await cargarCuentas();
      return true;
    } catch (_) {
      emit(current);
      return false;
    }
  }

  double _getMontoPendiente(Cuenta c) => c.balancePendiente;

  DateTime _getFecha(Cuenta c) => c.fechaCreacion;

  String _getNotas(Cuenta c) => c.nota ?? '';

  void _evaluarYEmitir({
    required List<Cuenta> cuentas,
    String query = '',
    EstadoCuenta? estado,
    OrdenCuenta orden = OrdenCuenta.mayorBalance,
    DateTimeRange? rangoCreacion,
    DateTimeRange? rangoVencimiento,
    bool soloCuotasVencidas = false,
    double? montoMin,
  }) {
    List<Cuenta> resultado = List.from(cuentas);

    final q = query.toLowerCase().trim();
    if (q.isNotEmpty) {
      resultado = resultado.where((c) {
        final idStr = c.id ?? '';
        final consultaId = c.consultaId;
        final notas = _getNotas(c).toLowerCase();
        // El buscador prometía «por paciente» desde siempre y sólo miraba ids.
        final paciente = (_nombres[c.pacienteId ?? ''] ?? '').toLowerCase();

        return paciente.contains(q) ||
            idStr.toLowerCase().contains(q) ||
            consultaId.toLowerCase().contains(q) ||
            notas.contains(q);
      }).toList();
    }

    if (estado != null) {
      resultado = resultado.where((c) => c.estado == estado).toList();
    }

    if (montoMin != null) {
      resultado = resultado
          .where((c) => _getMontoPendiente(c) >= montoMin)
          .toList();
    }

    if (rangoCreacion != null && resultado.isNotEmpty) {
      resultado = resultado.where((c) {
        final fecha = _getFecha(c);
        return !fecha.isBefore(rangoCreacion.start) &&
            !fecha.isAfter(rangoCreacion.end.add(const Duration(days: 1)));
      }).toList();
    }

    switch (orden) {
      case OrdenCuenta.mayorBalance:
        resultado.sort(
          (a, b) => _getMontoPendiente(b).compareTo(_getMontoPendiente(a)),
        );
        break;
      case OrdenCuenta.deudaMasAntigua:
        resultado.sort((a, b) => _getFecha(a).compareTo(_getFecha(b)));
        break;
      case OrdenCuenta.actualizacionReciente:
        resultado.sort((a, b) => _getFecha(b).compareTo(_getFecha(a)));
        break;
      case OrdenCuenta.proximoVencimiento:
        resultado.sort(
          (a, b) => _getMontoPendiente(a).compareTo(_getMontoPendiente(b)),
        );
        break;
    }

    final totalPorCobrar = resultado.fold<double>(
      0.0,
      (sum, item) => sum + _getMontoPendiente(item),
    );
    final totalCobrado = resultado.fold<double>(
      0.0,
      (sum, item) => sum + item.montoPagado,
    );

    emit(
      CuentasPorCobrarLoaded(
        todas: cuentas,
        filtradas: resultado,
        nombresPacientes: _nombres,
        searchQuery: query,
        filtroEstado: estado,
        orden: orden,
        rangoCreacion: rangoCreacion,
        rangoVencimiento: rangoVencimiento,
        soloCuotasVencidas: soloCuotasVencidas,
        montoPendienteMin: montoMin,
        totalPorCobrar: totalPorCobrar,
        totalCobrado: totalCobrado,
      ),
    );
  }
}
