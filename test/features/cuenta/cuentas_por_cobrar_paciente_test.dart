import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/repositories/cuenta_repository.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/widgets/cuenta_card.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';

/// Cuentas por Cobrar titulaba cada deuda con «Consulta #c16563b9».
///
/// Quien cobra busca a la persona, no un uuid recortado: sin el nombre la
/// pantalla obligaba a abrir cuenta por cuenta para saber a quién llamar. El
/// buscador, además, prometía «por paciente» y sólo miraba identificadores.
void main() {
  test(
    'la cuenta se identifica por el paciente y se puede buscar por él',
    () async {
      final cubit = CuentasPorCobrarCubit(
        _CuentaRepositorioDoble(),
        _PacienteRepositorioDoble(),
      );

      await cubit.cargarCuentas();

      final cargado = cubit.state as CuentasPorCobrarLoaded;
      expect(cargado.filtradas, hasLength(2));
      expect(cargado.nombrePaciente(cargado.todas.first), 'Elías De la Cruz');

      cubit.aplicarFiltros(query: 'alberto');
      final filtrado = cubit.state as CuentasPorCobrarLoaded;
      expect(filtrado.filtradas, hasLength(1));
      expect(
        filtrado.nombrePaciente(filtrado.filtradas.single),
        'Alberto García',
      );
    },
  );

  test('sin nombre resuelto la lista sigue en pie', () async {
    final cubit = CuentasPorCobrarCubit(
      _CuentaRepositorioDoble(),
      _PacienteRepositorioFallido(),
    );

    await cubit.cargarCuentas();

    final cargado = cubit.state as CuentasPorCobrarLoaded;
    expect(cargado.filtradas, hasLength(2));
    expect(cargado.nombrePaciente(cargado.todas.first), isNull);
  });

  testWidgets('la tarjeta sin nombre cae en la referencia de la consulta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: CuentaCard(cuenta: _cuenta('c1', 'pac-1'))),
      ),
    );

    expect(find.textContaining('Consulta #'), findsOneWidget);
  });

  testWidgets('con nombre, la tarjeta lo titula y ofrece abrirse', (
    tester,
  ) async {
    var abierta = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CuentaCard(
            cuenta: _cuenta('c1', 'pac-1'),
            nombrePaciente: 'Elías De la Cruz',
            onAbrir: () => abierta = true,
          ),
        ),
      ),
    );

    expect(find.text('Elías De la Cruz'), findsOneWidget);
    await tester.tap(find.text('Elías De la Cruz'));
    await tester.pump();
    expect(abierta, isTrue, reason: 'la tarjeta debe abrir el detalle');
  });
}

Cuenta _cuenta(String id, String pacienteId) => Cuenta(
  id: id,
  consultaId: 'c16563b9-0000-4000-8000-000000000001',
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

class _CuentaRepositorioDoble implements CuentaRepository {
  @override
  Future<List<Cuenta>> getCuentasPorCobrar() async => [
    _cuenta('cuenta-1', 'pac-1'),
    _cuenta('cuenta-2', 'pac-2'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PacienteRepositorioDoble implements IPacienteRepository {
  @override
  Future<Either<Failure, Map<String, String>>> getNombresPacientes(
    List<String> ids,
  ) async => Right({'pac-1': 'Elías De la Cruz', 'pac-2': 'Alberto García'});

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PacienteRepositorioFallido implements IPacienteRepository {
  @override
  Future<Either<Failure, Map<String, String>>> getNombresPacientes(
    List<String> ids,
  ) async => const Left(ServerFailure('sin directorio'));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
