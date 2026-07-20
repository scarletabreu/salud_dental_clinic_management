import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/frecuencia_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/usecases/generar_plan_de_cuotas.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';
import 'pre_factura_state.dart';

class PreFacturaCubit extends Cubit<PreFacturaState> {
  final GetCuentaByIdUseCase _getCuenta;
  final RegistrarPago _registrarPago;
  final CuotaRepository _cuotaRepository;
  final GenerarPlanDeCuotas _generarPlan;

  PreFacturaCubit({
    required GetCuentaByIdUseCase getCuenta,
    required RegistrarPago registrarPago,
    required CuotaRepository cuotaRepository,
    required GenerarPlanDeCuotas generarPlan,
  }) : _getCuenta = getCuenta,
       _registrarPago = registrarPago,
       _cuotaRepository = cuotaRepository,
       _generarPlan = generarPlan,
       super(const PreFacturaInicial());

  Future<void> cargar(String cuentaId) async {
    emit(const PreFacturaCargando());
    try {
      final cuenta = await _getCuenta(cuentaId);
      final cuotas = await _cuotaRepository.getCuotasDeCuenta(cuentaId);
      emit(PreFacturaCargada(cuenta, cuotas: cuotas));
    } catch (e) {
      emit(PreFacturaError('No se pudo cargar la cuenta.\n$e'));
    }
  }

  Future<void> recargar(String cuentaId) => cargar(cuentaId);

  /// Registra un cobro sobre la cuenta actualmente cargada y la recarga para
  /// reflejar el nuevo saldo y estado. Devuelve `null` si el cobro fue exitoso o
  /// un mensaje de error mostrable si falló (validación, red o servidor). No
  /// emite estados de error para no tumbar la pantalla: el diálogo de cobro
  /// gestiona su propio feedback con el mensaje devuelto.
  Future<String?> registrarPago({
    required double monto,
    required MetodoPago metodo,
    Cuota? cuota,
  }) async {
    final actual = state;
    if (actual is! PreFacturaCargada) {
      return 'La cuenta aún no está cargada.';
    }

    try {
      await _registrarPago(
        cuenta: actual.cuenta,
        monto: monto,
        metodo: metodo,
        cuota: cuota,
      );
      await cargar(actual.cuenta.id!);
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudo registrar el pago. Inténtalo de nuevo.';
    }
  }

  List<Cuota> previsualizarPlan({
    required int numCuotas,
    required DateTime fechaPrimera,
    required FrecuenciaCuota frecuencia,
  }) {
    final actual = state;
    if (actual is! PreFacturaCargada) return const [];
    return _generarPlan.previsualizar(
      cuenta: actual.cuenta,
      numCuotas: numCuotas,
      fechaPrimera: fechaPrimera,
      frecuencia: frecuencia,
    );
  }

  Future<String?> generarPlan({
    required int numCuotas,
    required DateTime fechaPrimera,
    required FrecuenciaCuota frecuencia,
  }) async {
    final actual = state;
    if (actual is! PreFacturaCargada) {
      return 'La cuenta aún no está cargada.';
    }
    if (actual.cuotas.isNotEmpty) {
      return 'La cuenta ya tiene un plan de cuotas.';
    }

    try {
      await _generarPlan(
        cuenta: actual.cuenta,
        numCuotas: numCuotas,
        fechaPrimera: fechaPrimera,
        frecuencia: frecuencia,
      );
      await cargar(actual.cuenta.id!);
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (_) {
      return 'No se pudo crear el plan de cuotas. Inténtalo de nuevo.';
    }
  }
}
