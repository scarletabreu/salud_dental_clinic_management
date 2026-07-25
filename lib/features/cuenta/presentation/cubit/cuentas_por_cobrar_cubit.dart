import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'cuentas_por_cobrar_state.dart';

class CuentasPorCobrarCubit extends Cubit<CuentasPorCobrarState> {
  final CuentaRepository _repository;

  CuentasPorCobrarCubit(this._repository)
    : super(const CuentasPorCobrarInitial());

  Future<void> cargarCuentas() async {
    emit(const CuentasPorCobrarLoading());
    try {
      final dynamic repo = _repository;
      List<Cuenta> cuentas;
      try {
        cuentas = await repo.getCuentasPorCobrar();
      } catch (_) {
        try {
          cuentas = await repo.getCuentas();
        } catch (_) {
          cuentas = await repo.getTodasLasCuentas();
        }
      }

      _evaluarYEmitir(cuentas: cuentas);
    } catch (e) {
      emit(CuentasPorCobrarError('Error al cargar cuentas por cobrar: $e'));
    }
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
      final dynamic repo = _repository;
      try {
        await repo.eliminarCuenta(id);
      } catch (_) {
        await repo.deleteCuenta(id);
      }
      await cargarCuentas();
      return true;
    } catch (_) {
      emit(current);
      return false;
    }
  }

  double _getMontoPendiente(Cuenta c) {
    try {
      final dynamic obj = c;
      if (obj.montoPendiente != null)
        return (obj.montoPendiente as num).toDouble();
    } catch (_) {}
    return (c.montoTotal - c.montoPagado);
  }

  DateTime _getFecha(Cuenta c) {
    try {
      final dynamic obj = c;
      if (obj.createdAt != null) return obj.createdAt as DateTime;
      if (obj.fecha != null) return obj.fecha as DateTime;
    } catch (_) {}
    return DateTime(2020);
  }

  String _getNotas(Cuenta c) {
    try {
      final dynamic obj = c;
      if (obj.notas != null) return obj.notas.toString();
      if (obj.observaciones != null) return obj.observaciones.toString();
    } catch (_) {}
    return '';
  }

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

        return idStr.toLowerCase().contains(q) ||
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
