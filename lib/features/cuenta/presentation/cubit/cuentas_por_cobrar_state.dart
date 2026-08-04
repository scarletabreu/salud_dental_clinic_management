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

  /// Nombre por `paciente_id`, resuelto contra el directorio de pacientes. Las
  /// cuentas viajan con el id y sin él la lista sólo sabía decir «Consulta
  /// #c16563b9», que no le sirve a quien cobra.
  final Map<String, String> nombresPacientes;

  const CuentasPorCobrarLoaded({
    required this.todas,
    required this.filtradas,
    this.nombresPacientes = const {},
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

  /// Nombre del paciente de una cuenta, o `null` si no se pudo resolver.
  String? nombrePaciente(Cuenta cuenta) {
    final id = cuenta.pacienteId;
    if (id == null) return null;
    return nombresPacientes[id];
  }

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
    Map<String, String>? nombresPacientes,
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
      nombresPacientes: nombresPacientes ?? this.nombresPacientes,
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
    super.nombresPacientes,
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
