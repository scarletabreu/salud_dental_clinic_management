import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
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
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/recibo_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/estado_pago.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/enums/metodo_pago.dart'
    as pago_enums;
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

/// Quien cobra tiene que poder imprimir lo que cobró.
///
/// La pre-factura exigía leer la consulta para armar el recibo, y la consulta
/// es del doctor firmante y del admin: recepción —que es quien cobra— recibía
/// «No se pudieron cargar los datos del paciente para el recibo» y el botón de
/// ver el recibo salía deshabilitado. De la consulta sólo se usaba el número,
/// que la cuenta ya trae.
void main() {
  test('sin acceso a la consulta, el recibo se emite igual', () async {
    final cubit = _cubit(consulta: _ConsultaProhibida());

    await cubit.cargar('cuenta-1');

    final estado = cubit.state as PreFacturaCargada;
    expect(estado.consulta, isNull);
    expect(estado.paciente, isNotNull);
    expect(estado.errorDatosRecibo, isNull);
    expect(estado.puedeEmitirRecibo, isTrue);
    await cubit.close();
  });

  test('sin paciente en la cuenta se dice qué falta', () async {
    final cubit = _cubit(consulta: _ConsultaProhibida(), pacienteId: null);

    await cubit.cargar('cuenta-1');

    final estado = cubit.state as PreFacturaCargada;
    expect(estado.puedeEmitirRecibo, isFalse);
    expect(estado.errorDatosRecibo, contains('no tiene paciente asociado'));
    await cubit.close();
  });

  test('el número de consulta del recibo sale de la cuenta', () {
    final recibo = ReciboPago(
      cuenta: _cuenta(),
      pago: _pago(),
      paciente: _paciente,
    );

    expect(recibo.consultaNumero, 'C16563B9');
  });
}

PreFacturaCubit _cubit({
  required ConsultaRepository consulta,
  String? pacienteId = 'pac-1',
}) {
  final cuenta = _cuenta(pacienteId: pacienteId);
  return PreFacturaCubit(
    getCuenta: GetCuentaByIdUseCase(repository: _CuentaDoble(cuenta)),
    registrarPago: RegistrarPago(_PagoDoble()),
    cuotaRepository: _CuotaDoble(),
    generarPlan: GenerarPlanDeCuotas(_CuotaDoble()),
    consultaRepository: consulta,
    pacienteRepository: _PacienteDoble(),
    cuentaRepository: _CuentaDoble(cuenta),
  );
}

Cuenta _cuenta({String? pacienteId = 'pac-1'}) => Cuenta(
  id: 'cuenta-1',
  consultaId: 'c16563b9-0000-4000-8000-000000000001',
  pacienteId: pacienteId,
  fechaCreacion: DateTime(2026, 8, 4),
  metodoPago: MetodoPago.contado,
  itemCuentas: [
    ItemCuenta(
      cuentaId: 'cuenta-1',
      descripcion: 'Endodoncia',
      precioUnitario: 4300,
      cantidad: 1,
    ),
  ],
  pagos: [_pago()],
);

Pago _pago() => Pago(
  id: '474729d7-0000-4000-8000-000000000001',
  cuentaId: 'cuenta-1',
  monto: 4300,
  fecha: DateTime(2026, 8, 4),
  metodoPago: pago_enums.MetodoPago.efectivo,
  estado: EstadoPago.completado,
);

final _paciente = Paciente(
  id: 'pac-1',
  nombre: 'Elías',
  apellido: 'De la Cruz',
  birthDate: DateTime(1995, 5, 5),
  govID: '001-1111111-1',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  genero: Genero.masculino,
  tipoPaciente: TipoPaciente.integrado,
  trabajo: '',
  referencia: '',
  citas: const [],
  record: Record(
    pacienteId: 'pac-1',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

/// Lo que ve recepción al pedir una consulta: la RLS no le devuelve nada.
class _ConsultaProhibida implements ConsultaRepository {
  @override
  Future<Consulta?> getDetalleConsulta(String id) async =>
      throw const PermisoDenegadoFailure();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CuentaDoble implements CuentaRepository {
  _CuentaDoble(this._cuenta);
  final Cuenta _cuenta;

  @override
  Future<Cuenta> getCuentaById(String id) async => _cuenta;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _CuotaDoble implements CuotaRepository {
  @override
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PagoDoble implements PagoRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PacienteDoble implements IPacienteRepository {
  @override
  Future<Either<Failure, Paciente>> getPacienteById(String id) async =>
      Right(_paciente);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
