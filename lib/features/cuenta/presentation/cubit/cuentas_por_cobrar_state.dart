import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';

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

  final double totalPorCobrar;
  final double totalCobrado;

  const CuentasPorCobrarLoaded({
    required this.todas,
    required this.filtradas,
    this.searchQuery = '',
    this.filtroEstado,
    required this.totalPorCobrar,
    required this.totalCobrado,
  });

  CuentasPorCobrarLoaded copyWith({
    List<Cuenta>? todas,
    List<Cuenta>? filtradas,
    String? searchQuery,
    EstadoCuenta? Function()? filtroEstado,
    double? totalPorCobrar,
    double? totalCobrado,
  }) {
    return CuentasPorCobrarLoaded(
      todas: todas ?? this.todas,
      filtradas: filtradas ?? this.filtradas,
      searchQuery: searchQuery ?? this.searchQuery,
      filtroEstado: filtroEstado != null ? filtroEstado() : this.filtroEstado,
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
    required super.totalPorCobrar,
    required super.totalCobrado,
  });
}
