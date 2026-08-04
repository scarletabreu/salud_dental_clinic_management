import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_state.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';

import '../../support/senales_de_prueba.dart';

/// MU-2 · La consulta finalizada en otra sesión crea su pre-factura y la
/// cuenta aparece en el mostrador sin refrescar; el cobro ajeno actualiza el
/// saldo. La búsqueda activa se preserva y los nombres nuevos se resuelven
/// solos, sin volver a pedir todo el directorio.

Cuenta _cuenta(String id, String pacienteId) => Cuenta(
  id: id,
  consultaId: 'consulta-$id',
  pacienteId: pacienteId,
  fechaCreacion: DateTime(2026, 8, 4),
  metodoPago: MetodoPago.contado,
  estado: EstadoCuenta.abierta,
  itemCuentas: [
    ItemCuenta(
      cuentaId: id,
      descripcion: 'Endodoncia',
      precioUnitario: 35000,
      cantidad: 1,
    ),
  ],
  pagos: const [],
);

class _CuentaRepoFalso extends Fake implements CuentaRepository {
  List<Cuenta> cuentas = [];

  @override
  Future<List<Cuenta>> getCuentasPorCobrar() async => cuentas;
}

class _PacienteRepoFalso extends Fake implements IPacienteRepository {
  final consultados = <List<String>>[];
  Map<String, String> nombres = {};

  @override
  Future<Either<Failure, Map<String, String>>> getNombresPacientes(
    List<String> ids,
  ) async {
    consultados.add(ids);
    return Right({
      for (final id in ids)
        if (nombres.containsKey(id)) id: nombres[id]!,
    });
  }
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late _CuentaRepoFalso repo;
  late _PacienteRepoFalso pacientes;
  late FabricaCanalesFalsa fabrica;
  late CuentasPorCobrarCubit cubit;

  setUp(() {
    repo = _CuentaRepoFalso()..cuentas = [_cuenta('c1', 'pac-1')];
    pacientes = _PacienteRepoFalso()
      ..nombres = {'pac-1': 'Elías De la Cruz', 'pac-2': 'Alberto García'};
    fabrica = FabricaCanalesFalsa();
    cubit = CuentasPorCobrarCubit(
      repo,
      pacientes,
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );
  });

  tearDown(() => cubit.close());

  test('la cuenta recién creada en otra sesión aparece sola', () async {
    await cubit.cargarCuentas();
    expect((cubit.state as CuentasPorCobrarLoaded).todas, hasLength(1));

    repo.cuentas = [_cuenta('c1', 'pac-1'), _cuenta('c2', 'pac-2')];
    fabrica.cambios['cuentas']!();
    await _asentar();

    final estado = cubit.state as CuentasPorCobrarLoaded;
    expect(estado.todas, hasLength(2));
    expect(
      estado.nombrePaciente(estado.todas.last),
      'Alberto García',
      reason: 'el nombre del paciente nuevo se resuelve al llegar la cuenta',
    );
  });

  test('sólo se piden los nombres que faltan, no todo el directorio',
      () async {
    await cubit.cargarCuentas();
    pacientes.consultados.clear();

    repo.cuentas = [_cuenta('c1', 'pac-1'), _cuenta('c2', 'pac-2')];
    fabrica.cambios['cuentas']!();
    await _asentar();

    expect(pacientes.consultados, [
      ['pac-2'],
    ]);
  });

  test('la búsqueda activa sobrevive a la recarga por señal', () async {
    repo.cuentas = [_cuenta('c1', 'pac-1'), _cuenta('c2', 'pac-2')];
    await cubit.cargarCuentas();
    cubit.aplicarFiltros(query: 'alberto');
    expect((cubit.state as CuentasPorCobrarLoaded).filtradas, hasLength(1));

    repo.cuentas = [
      _cuenta('c1', 'pac-1'),
      _cuenta('c2', 'pac-2'),
      _cuenta('c3', 'pac-1'),
    ];
    fabrica.cambios['cuentas']!();
    await _asentar();

    final estado = cubit.state as CuentasPorCobrarLoaded;
    expect(estado.searchQuery, 'alberto');
    expect(
      estado.filtradas.map((c) => c.id),
      ['c2'],
      reason: 'la lista fresca se re-filtra con lo que el usuario tecleó',
    );
    expect(estado.todas, hasLength(3));
  });

  test('sin lista cargada la señal no hace nada', () async {
    fabrica.cambios['cuentas']!();
    await _asentar();

    expect(cubit.state, isA<CuentasPorCobrarInitial>());
  });
}
