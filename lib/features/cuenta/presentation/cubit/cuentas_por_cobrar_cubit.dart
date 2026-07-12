import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuentas_por_cobrar_usecase.dart';
import 'cuentas_por_cobrar_state.dart';

class CuentasPorCobrarCubit extends Cubit<CuentasPorCobrarState> {
  final GetCuentasPorCobrarUseCase _getCuentas;
  final CuentaRepository _repository;

  CuentasPorCobrarCubit({
    required GetCuentasPorCobrarUseCase getCuentas,
    required CuentaRepository repository,
  }) : _getCuentas = getCuentas,
       _repository = repository,
       super(const CuentasPorCobrarInitial());

  Future<void> cargarCuentas() async {
    emit(const CuentasPorCobrarLoading());
    try {
      final cuentas = await _getCuentas();
      emit(_buildLoaded(cuentas));
    } catch (e) {
      emit(CuentasPorCobrarError('No se pudieron cargar las cuentas.\n$e'));
    }
  }

  void aplicarFiltros({String? query, EstadoCuenta? Function()? estado}) {
    final current = state;
    if (current is! CuentasPorCobrarLoaded) return;

    final q = (query ?? current.searchQuery).toLowerCase().trim();
    final nuevoEstado = estado != null ? estado() : current.filtroEstado;

    final filtradas = current.todas.where((c) {
      final matchQuery =
          q.isEmpty ||
          (c.consultaId.toLowerCase().contains(q)) ||
          (c.nota?.toLowerCase().contains(q) ?? false);

      final matchEstado =
          nuevoEstado == null || _estadoDeCuenta(c) == nuevoEstado;

      return matchQuery && matchEstado;
    }).toList();

    emit(
      current.copyWith(
        filtradas: filtradas,
        searchQuery: q,
        filtroEstado: () => nuevoEstado,
      ),
    );
  }

  Future<bool> eliminarCuenta(String id) async {
    final current = state;
    if (current is! CuentasPorCobrarLoaded) return false;

    emit(
      CuentasPorCobrarOperating(
        todas: current.todas,
        filtradas: current.filtradas,
        searchQuery: current.searchQuery,
        filtroEstado: current.filtroEstado,
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

  CuentasPorCobrarLoaded _buildLoaded(List<Cuenta> cuentas) {
    final totalPorCobrar = cuentas
        .where((c) => !c.estaPagada)
        .fold(0.0, (sum, c) => sum + c.balancePendiente);
    final totalCobrado = cuentas.fold(0.0, (sum, c) => sum + c.montoPagado);

    return CuentasPorCobrarLoaded(
      todas: cuentas,
      filtradas: cuentas,
      totalPorCobrar: totalPorCobrar,
      totalCobrado: totalCobrado,
    );
  }

  static EstadoCuenta _estadoDeCuenta(Cuenta c) {
    if (c.estaPagada) return EstadoCuenta.saldada;
    if (c.montoPagado > 0) return EstadoCuenta.pendiente;
    return EstadoCuenta.abierta;
  }
}
