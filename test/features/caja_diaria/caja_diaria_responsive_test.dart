import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/arqueo_pendiente.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/pages/caja_diaria_page.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

class _MovimientoRepositoryFake implements MovimientoCajaRepository {
  @override
  Future<void> crearMovimiento(MovimientoCaja movimiento) async {}

  @override
  Future<List<MovimientoCaja>> getMovimientosDeHoy(String cajaDiariaId) async =>
      [];
}

class _CajaRepositoryFake implements CajaDiariaRepository {
  _CajaRepositoryFake({this.caja, List<ArqueoPendiente>? pendientes})
    : pendientes = pendientes ?? [];

  CajaDiaria? caja;
  final List<ArqueoPendiente> pendientes;
  final List<Map<String, Object?>> arqueosCerrados = [];
  final movimientos = StreamController<List<MovimientoCaja>>.broadcast();

  @override
  Future<List<ArqueoPendiente>> getArqueosPendientes() async =>
      List.of(pendientes);

  @override
  Future<void> cerrarArqueoPendiente({
    required String cajaId,
    required double montoReal,
    String? observaciones,
  }) async {
    arqueosCerrados.add({
      'cajaId': cajaId,
      'montoReal': montoReal,
      'observaciones': observaciones,
    });
    pendientes.removeWhere((arqueo) => arqueo.id == cajaId);
  }

  @override
  Future<void> abrirCaja(double montoApertura) async {
    caja = CajaDiaria(
      id: 'caja-1',
      fecha: DateTime(2026, 7, 21),
      montoApertura: montoApertura,
      montoCierre: 0,
      montoEsperado: montoApertura,
      montoReal: 0,
    );
  }

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) async {}

  @override
  Future<CajaDiaria?> getCajaActual() async => caja;

  @override
  Future<double> getMontoEsperado() async => caja?.montoApertura ?? 0;

  @override
  Future<bool> isCajaAbierta() async => caja != null;

  @override
  Stream<List<MovimientoCaja>> watchMovimientos(String cajaDiariaId) =>
      movimientos.stream;
}

Widget _app(CajaDiariaRepository repositorio, {double textScale = 1}) =>
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, inner) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: inner!,
      ),
      home: BlocProvider<CajaDiariaCubit>(
        create: (_) => CajaDiariaCubit(repositorio, _MovimientoRepositoryFake()),
        child: const CajaDiariaPage(),
      ),
    );

void _viewport(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _viewports = <String, Size>{
  '320 px': const Size(320, 640),
  '360 px': const Size(360, 740),
  '390 px': const Size(390, 844),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 800),
};

void main() {
  _viewports.forEach((nombre, tamano) {
    testWidgets('la apertura de caja se puede completar en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(_app(_CajaRepositoryFake()));
      await tester.pumpAndSettle();

      final monto = find.byType(TextFormField);
      expect(monto, findsOneWidget);
      await tester.enterText(monto, '5000');
      await tester.pump();

      expect(find.text('5000'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'la apertura de caja no debe desbordar en $nombre',
      );
    });
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('la caja abierta con movimientos se muestra en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      final repositorio = _CajaRepositoryFake(
        caja: CajaDiaria(
          id: 'caja-1',
          fecha: DateTime(2026, 7, 21),
          montoApertura: 5000,
          montoCierre: 0,
          montoEsperado: 5000,
          montoReal: 0,
        ),
      );

      await tester.pumpWidget(_app(repositorio));
      await tester.pumpAndSettle();

      repositorio.movimientos.add([
        MovimientoCaja(
          cajaDiariaId: 'caja-1',
          tipo: TipoMovimiento.ingreso,
          monto: 18500,
          descripcion: 'Cobro de endodoncia multirradicular con corona',
          fecha: DateTime(2026, 7, 21, 9),
          referenciaId: 'pago-1',
        ),
        MovimientoCaja(
          cajaDiariaId: 'caja-1',
          tipo: TipoMovimiento.egreso,
          monto: 1250,
          descripcion: 'Compra de insumos de esterilización',
          fecha: DateTime(2026, 7, 21, 11),
          referenciaId: 'compra-1',
        ),
      ]);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'el detalle de caja no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('la apertura resiste el teclado abierto en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 640));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);

    await tester.pumpWidget(_app(_CajaRepositoryFake()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('la apertura resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 900));
    await tester.pumpWidget(_app(_CajaRepositoryFake(), textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  group('arqueo pendiente de días anteriores', () {
    ArqueoPendiente arqueoDeAnteayer() => ArqueoPendiente(
      id: 'caja-anteayer',
      caja: CajaDiaria(
        id: 'caja-anteayer',
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        montoApertura: 3000,
        montoCierre: 0,
        montoEsperado: 3000,
        montoReal: 0,
      ),
      movimientos: [
        MovimientoCaja(
          cajaDiariaId: 'caja-anteayer',
          tipo: TipoMovimiento.ingreso,
          monto: 7200,
          descripcion: 'Cobro de dos resinas',
          fecha: DateTime.now().subtract(const Duration(days: 2)),
        ),
        MovimientoCaja(
          cajaDiariaId: 'caja-anteayer',
          tipo: TipoMovimiento.egreso,
          monto: 900,
          descripcion: 'Compra de guantes y gasas',
          fecha: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
    );

    testWidgets('el aviso ofrece cerrarlo y muestra lo que debería tener', (
      tester,
    ) async {
      _viewport(tester, const Size(1280, 800));
      final repositorio = _CajaRepositoryFake(
        pendientes: [arqueoDeAnteayer()],
      );

      await tester.pumpWidget(_app(repositorio));
      await tester.pumpAndSettle();

      // 3000 + 7200 - 900 = 9300. El aviso ya no es sólo una fecha.
      expect(find.textContaining('9,300.00'), findsOneWidget);
      expect(find.text('Cerrar arqueo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('la hoja muestra el desglose antes de pedir el conteo', (
      tester,
    ) async {
      _viewport(tester, const Size(1280, 800));
      final repositorio = _CajaRepositoryFake(
        pendientes: [arqueoDeAnteayer()],
      );

      await tester.pumpWidget(_app(repositorio));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar arqueo'));
      await tester.pumpAndSettle();

      expect(find.text('Fondo de apertura'), findsOneWidget);
      expect(find.text('Debería haber en caja'), findsOneWidget);
      expect(find.text('Ver los 2 movimientos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un conteo que no cuadra no se cierra sin nota', (
      tester,
    ) async {
      _viewport(tester, const Size(1280, 900));
      final repositorio = _CajaRepositoryFake(
        pendientes: [arqueoDeAnteayer()],
      );

      await tester.pumpWidget(_app(repositorio));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar arqueo'));
      await tester.pumpAndSettle();

      // La página de fondo (caja sin abrir) también tiene un campo de monto:
      // el conteo hay que escribirlo en el de la hoja, no en el de la apertura.
      final monto = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .first;
      await tester.enterText(monto, '8900');
      await tester.pumpAndSettle();

      expect(find.textContaining('Faltan'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar cierre'));
      await tester.pumpAndSettle();

      expect(
        repositorio.arqueosCerrados,
        isEmpty,
        reason: 'sin nota, un arqueo descuadrado no se puede cerrar',
      );
      expect(find.textContaining('Explica la diferencia'), findsOneWidget);
    });

    testWidgets('con el conteo cuadrado el arqueo se cierra', (tester) async {
      _viewport(tester, const Size(1280, 900));
      final repositorio = _CajaRepositoryFake(
        pendientes: [arqueoDeAnteayer()],
      );

      await tester.pumpWidget(_app(repositorio));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cerrar arqueo'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar cierre'));
      // Sin `pumpAndSettle`: al cerrar se abre el reporte, cuya vista previa de
      // PDF se repinta sin parar y nunca deja quieto el árbol.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(repositorio.arqueosCerrados, hasLength(1));
      expect(repositorio.arqueosCerrados.single['cajaId'], 'caja-anteayer');
      expect(repositorio.arqueosCerrados.single['montoReal'], 9300.0);
    });
  });
}
