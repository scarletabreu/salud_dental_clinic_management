import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_state.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/usecases/generar_plan_de_cuotas.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';

import '../../support/senales_de_prueba.dart';

/// MU-2 · La pre-factura abierta se mantiene al día sola: el cobro o la
/// anulación hechos en otra sesión actualizan saldo y estado, y la apertura
/// de la caja habilita el cobro sin salir y volver a entrar.

Cuenta _cuenta({List<Pago> pagos = const []}) => Cuenta(
  id: 'cuenta-1',
  consultaId: 'consulta-1',
  pacienteId: 'pac-1',
  fechaCreacion: DateTime(2026, 8, 4),
  metodoPago: MetodoPago.contado,
  estado: pagos.isEmpty ? EstadoCuenta.abierta : EstadoCuenta.saldada,
  itemCuentas: [
    ItemCuenta(
      cuentaId: 'cuenta-1',
      descripcion: 'Endodoncia',
      precioUnitario: 5000,
      cantidad: 1,
    ),
  ],
  pagos: pagos,
);

Pago _pago() => Pago(
  id: 'pago-1',
  cuentaId: 'cuenta-1',
  monto: 5000,
  metodoPago: pago_enums.MetodoPago.efectivo,
  fecha: DateTime(2026, 8, 4, 10),
  estado: EstadoPago.completado,
);

class _CuentaRepoFalso extends Fake implements CuentaRepository {
  Cuenta actual = _cuenta();

  @override
  Future<Cuenta> getCuentaById(String id) async => actual;
}

class _PagoRepoFalso extends Fake implements PagoRepository {}

class _CuotaRepoFalso extends Fake implements CuotaRepository {
  @override
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId) async => const [];
}

class _ConsultaRepoFalso extends Fake implements ConsultaRepository {
  @override
  Future<Consulta?> getDetalleConsulta(String id) async => null;
}

class _PacienteRepoFalso extends Fake implements IPacienteRepository {
  @override
  Future<Either<Failure, Paciente>> getPacienteById(String id) async =>
      const Left(ServerFailure('sin acceso en este test'));
}

class _CajaRepoFalso extends Fake implements CajaDiariaRepository {
  bool abierta = false;

  @override
  Future<bool> isCajaAbierta() async => abierta;
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late _CuentaRepoFalso cuentas;
  late _CajaRepoFalso caja;
  late FabricaCanalesFalsa fabrica;
  late PreFacturaCubit cubit;

  setUp(() {
    cuentas = _CuentaRepoFalso();
    caja = _CajaRepoFalso();
    fabrica = FabricaCanalesFalsa();
    final cuentaRepo = cuentas;
    cubit = PreFacturaCubit(
      getCuenta: GetCuentaByIdUseCase(repository: cuentaRepo),
      registrarPago: RegistrarPago(_PagoRepoFalso()),
      cuotaRepository: _CuotaRepoFalso(),
      generarPlan: GenerarPlanDeCuotas(_CuotaRepoFalso()),
      consultaRepository: _ConsultaRepoFalso(),
      pacienteRepository: _PacienteRepoFalso(),
      cuentaRepository: cuentaRepo,
      cajaRepository: caja,
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );
  });

  tearDown(() => cubit.close());

  test('el cobro ajeno actualiza saldo y estado sin refrescar', () async {
    await cubit.cargar('cuenta-1');
    var estado = cubit.state as PreFacturaCargada;
    expect(estado.cuenta.estado, EstadoCuenta.abierta);

    final emitidos = <PreFacturaState>[];
    final sub = cubit.stream.listen(emitidos.add);

    cuentas.actual = _cuenta(pagos: [_pago()]);
    fabrica.cambios['cuentas']!();
    await _asentar();

    estado = cubit.state as PreFacturaCargada;
    expect(estado.cuenta.estado, EstadoCuenta.saldada);
    expect(estado.cuenta.pagos, hasLength(1));
    expect(
      emitidos.whereType<PreFacturaCargando>(),
      isEmpty,
      reason: 'el refresh por señal no debe hacer parpadear la pantalla',
    );
    await sub.cancel();
  });

  test('abrir la caja en otra sesión habilita el cobro solo', () async {
    await cubit.cargar('cuenta-1');
    expect((cubit.state as PreFacturaCargada).cajaAbierta, isFalse);

    caja.abierta = true;
    fabrica.cambios['cajas']!();
    await _asentar();

    expect((cubit.state as PreFacturaCargada).cajaAbierta, isTrue);
  });
}
