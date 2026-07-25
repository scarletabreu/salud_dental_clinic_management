import 'package:flutter/material.dart' show DateTimeRange;
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';

enum OrdenCuenta {
  mayorBalance,
  deudaMasAntigua,
  proximoVencimiento,
  actualizacionReciente,
}

sealed class CuentasPorCobrarState {
  const CuentasPorCobrarState();
}

class CuentasPorCobrarInitial extends CuentasPorCobrarState {
  const CuentasPorCobrarInitial();
}

class CuentasPorCobrarLoading extends CuentasPorCobrarState {
  const CuentasPorCobrarLoading();
}

class CuentasPorCobrarLoaded extends CuentasPorCobrarState {
  final List<Cuenta> todas;
  final List<Cuenta> filtradas;
  final String searchQuery;
  final EstadoCuenta? filtroEstado;
  final OrdenCuenta orden;
  final DateTimeRange? rangoCreacion;
  final DateTimeRange? rangoVencimiento;
  final bool soloCuotasVencidas;
  final double? montoPendienteMin;

  final double totalPorCobrar;
  final double totalCobrado;

  const CuentasPorCobrarLoaded({
    required this.todas,
    required this.filtradas,
    this.searchQuery = '',
    this.filtroEstado,
    this.orden = OrdenCuenta.mayorBalance,
    this.rangoCreacion,
    this.rangoVencimiento,
    this.soloCuotasVencidas = false,
    this.montoPendienteMin,
    required this.totalPorCobrar,
    required this.totalCobrado,
  });

  bool get hayFiltrosActivos =>
      searchQuery.isNotEmpty ||
      filtroEstado != null ||
      rangoCreacion != null ||
      rangoVencimiento != null ||
      soloCuotasVencidas ||
      montoPendienteMin != null;

  CuentasPorCobrarLoaded copyWith({
    List<Cuenta>? todas,
    List<Cuenta>? filtradas,
    String? searchQuery,
    EstadoCuenta? Function()? filtroEstado,
    OrdenCuenta? orden,
    DateTimeRange? Function()? rangoCreacion,
    DateTimeRange? Function()? rangoVencimiento,
    bool? soloCuotasVencidas,
    double? Function()? montoPendienteMin,
    double? totalPorCobrar,
    double? totalCobrado,
  }) {
    return CuentasPorCobrarLoaded(
      todas: todas ?? this.todas,
      filtradas: filtradas ?? this.filtradas,
      searchQuery: searchQuery ?? this.searchQuery,
      filtroEstado: filtroEstado != null ? filtroEstado() : this.filtroEstado,
      orden: orden ?? this.orden,
      rangoCreacion: rangoCreacion != null
          ? rangoCreacion()
          : this.rangoCreacion,
      rangoVencimiento: rangoVencimiento != null
          ? rangoVencimiento()
          : this.rangoVencimiento,
      soloCuotasVencidas: soloCuotasVencidas ?? this.soloCuotasVencidas,
      montoPendienteMin: montoPendienteMin != null
          ? montoPendienteMin()
          : this.montoPendienteMin,
      totalPorCobrar: totalPorCobrar ?? this.totalPorCobrar,
      totalCobrado: totalCobrado ?? this.totalCobrado,
    );
  }
}

class CuentasPorCobrarError extends CuentasPorCobrarState {
  final String message;
  const CuentasPorCobrarError(this.message);
}

class CuentasPorCobrarOperating extends CuentasPorCobrarLoaded {
  const CuentasPorCobrarOperating({
    required super.todas,
    required super.filtradas,
    super.searchQuery,
    super.filtroEstado,
    super.orden,
    super.rangoCreacion,
    super.rangoVencimiento,
    super.soloCuotasVencidas,
    super.montoPendienteMin,
    required super.totalPorCobrar,
    required super.totalCobrado,
  });
}
