import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/widgets/plan_cuotas_panel.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('muestra estado vacío y permite configurar el plan', (
    tester,
  ) async {
    var configurarInvocado = false;
    await tester.pumpWidget(
      _app(
        PlanCuotasPanel(
          cuotas: const [],
          onConfigurar: () => configurarInvocado = true,
          onPagar: (_) {},
        ),
      ),
    );

    expect(find.text('Aún no hay fechas programadas'), findsOneWidget);
    await tester.tap(find.text('Configurar plan'));
    expect(configurarInvocado, isTrue);
  });

  testWidgets('calendario cabe en móvil y expone Pagar cuota', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Cuota? cuotaPagada;
    final cuotas = [
      Cuota(
        id: 'q1',
        cuentaId: 'c1',
        monto: 333.33,
        fechaVencimiento: DateTime(2026, 8, 20),
        estado: EstadoCuota.pendiente,
      ),
      Cuota(
        id: 'q2',
        cuentaId: 'c1',
        monto: 333.33,
        montoPagado: 100,
        fechaVencimiento: DateTime(2026, 9, 20),
        estado: EstadoCuota.vencida,
      ),
      Cuota(
        id: 'q3',
        cuentaId: 'c1',
        monto: 333.34,
        montoPagado: 333.34,
        fechaVencimiento: DateTime(2026, 10, 20),
        estado: EstadoCuota.pagada,
      ),
    ];

    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: PlanCuotasPanel(
            cuotas: cuotas,
            onConfigurar: () {},
            onPagar: (cuota) => cuotaPagada = cuota,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('VENCIDA'), findsOneWidget);
    expect(find.text('PAGADA'), findsOneWidget);
    await tester.tap(find.text('Pagar cuota'));
    expect(cuotaPagada?.id, 'q1');
  });

  // El calendario de cuotas es una de las vistas más densas: números, fechas y
  // montos compiten por el mismo ancho.
  final viewports = <String, Size>{
    '320 px': const Size(320, 900),
    '360 px': const Size(360, 900),
    '390 px': const Size(390, 900),
    'tablet': const Size(768, 1024),
    'escritorio': const Size(1280, 900),
  };

  viewports.forEach((nombre, tamano) {
    testWidgets('el calendario de cuotas no desborda en $nombre', (
      tester,
    ) async {
      tester.view.physicalSize = tamano;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cuotas = [
        for (var i = 0; i < 6; i++)
          Cuota(
            id: 'q$i',
            cuentaId: 'c1',
            monto: 18500.55,
            montoPagado: i.isEven ? 18500.55 : 0,
            fechaVencimiento: DateTime(2026, 8 + i, 20),
            estado: i.isEven ? EstadoCuota.pagada : EstadoCuota.pendiente,
          ),
      ];

      await tester.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(12),
            child: PlanCuotasPanel(
              cuotas: cuotas,
              onConfigurar: () {},
              onPagar: (_) {},
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'el plan de cuotas no debe desbordar en $nombre',
      );
    });
  });
}
