import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/frecuencia_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/usecases/generar_plan_de_cuotas.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'pre_factura_state.dart';

class PreFacturaCubit extends Cubit<PreFacturaState> {
  final GetCuentaByIdUseCase _getCuenta;
  final RegistrarPago _registrarPago;
  final CuotaRepository _cuotaRepository;
  final GenerarPlanDeCuotas _generarPlan;
  final ConsultaRepository _consultaRepository;
  final IPacienteRepository _pacienteRepository;
  String? _ultimoPagoId;

  PreFacturaCubit({
    required GetCuentaByIdUseCase getCuenta,
    required RegistrarPago registrarPago,
    required CuotaRepository cuotaRepository,
    required GenerarPlanDeCuotas generarPlan,
    required ConsultaRepository consultaRepository,
    required IPacienteRepository pacienteRepository,
  }) : _getCuenta = getCuenta,
       _registrarPago = registrarPago,
       _cuotaRepository = cuotaRepository,
       _generarPlan = generarPlan,
       _consultaRepository = consultaRepository,
       _pacienteRepository = pacienteRepository,
       super(const PreFacturaInicial());

  Pago? get ultimoPagoRegistrado {
    final actual = state;
    if (actual is! PreFacturaCargada || _ultimoPagoId == null) return null;
    for (final pago in actual.cuenta.pagos) {
      if (pago.id == _ultimoPagoId) return pago;
    }
    return null;
  }

  Future<void> cargar(String cuentaId) async {
    emit(const PreFacturaCargando());
    try {
      final cuenta = await _getCuenta(cuentaId);
      final cuotas = await _cuotaRepository.getCuotasDeCuenta(cuentaId);
      Consulta? consulta;
      Paciente? paciente;
      String? errorDatosRecibo;

      try {
        consulta = await _consultaRepository.getDetalleConsulta(
          cuenta.consultaId,
        );
        if (consulta == null) {
          throw Exception('No se encontró la consulta asociada.');
        }
        final resultadoPaciente = await _pacienteRepository.getPacienteById(
          consulta.pacienteId,
        );
        paciente = resultadoPaciente.fold(
          (failure) => throw failure,
          (value) => value,
        );
      } catch (_) {
        errorDatosRecibo =
            'No se pudieron cargar los datos del paciente para el recibo.';
      }

      emit(
        PreFacturaCargada(
          cuenta,
          cuotas: cuotas,
          consulta: consulta,
          paciente: paciente,
          errorDatosRecibo: errorDatosRecibo,
        ),
      );
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
      _ultimoPagoId = null;
      _ultimoPagoId = await _registrarPago(
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
