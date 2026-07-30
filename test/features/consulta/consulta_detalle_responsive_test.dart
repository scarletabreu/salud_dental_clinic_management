import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consulta_detalle_page.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class _ConsultaDetalleCubitDoble extends Cubit<ConsultaDetalleState>
    implements ConsultaDetalleCubit {
  _ConsultaDetalleCubitDoble(super.initialState);

  @override
  Future<void> cargar(Consulta consulta) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Consulta _consulta() => Consulta(
  id: '55555555-5555-5555-5555-555555555555',
  pacienteId: '11111111-1111-1111-1111-111111111111',
  doctorId: '22222222-2222-2222-2222-222222222222',
  fecha: DateTime(2026, 7, 21, 10, 30),
  finalizada: true,
  tienePreFactura: true,
  motivoConsulta:
      'Dolor punzante en el segundo molar inferior derecho al masticar, '
      'con sensibilidad prolongada al frío desde hace dos semanas.',
  notas:
      'Se realiza apertura cameral y se confirma pulpitis irreversible. '
      'Se instrumenta y se deja medicación intraconducto.',
  signosVitales: const SignosVitales(
    presionSistolica: 128,
    presionDiastolica: 84,
    pulso: 76,
    temperatura: 36.8,
    saturacionO2: 98,
  ),
  recetas: [
    Receta(
      codigoReceta: 'RX-2026-00002',
      consultaId: 'consulta-1',
      pacienteId: 'paciente-1',
      fechaEmision: DateTime(2026, 7, 21),
      items: const [
        ItemReceta(
          nombreMedicamento: 'Amoxicilina con ácido clavulánico',
          medicamentoId: 'med-1',
          dosis: '875/125 mg',
          frecuencia: 'Cada 12 horas',
          duracion: '7 días',
          indicacionesEspecificas:
              'Tomar con alimentos para reducir molestias gástricas',
        ),
      ],
    ),
  ],
);

Widget _app({double textScale = 1}) {
  if (sl.isRegistered<ConsultaDetalleCubit>()) {
    sl.unregister<ConsultaDetalleCubit>();
  }
  sl.registerFactory<ConsultaDetalleCubit>(
    () => _ConsultaDetalleCubitDoble(
      const ConsultaDetalleListo(
        nombresMedicinas: {'med-1': 'Amoxicilina con ácido clavulánico'},
      ),
    ),
  );

  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: inner!,
    ),
    home: ConsultaDetallePage(
      consulta: _consulta(),
      nombrePaciente: 'Ana Rodríguez Montás',
      nombreDoctor: 'Bartolomé Santana Villalona',
    ),
  );
}

void _viewport(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _viewports = <String, Size>{
  '320 px': const Size(320, 900),
  '360 px': const Size(360, 900),
  '390 px': const Size(390, 900),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 900),
};

void main() {
  tearDown(() {
    if (sl.isRegistered<ConsultaDetalleCubit>()) {
      sl.unregister<ConsultaDetalleCubit>();
    }
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('el detalle clínico se lee completo en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Ana Rodríguez Montás'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'el detalle de consulta no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('el detalle clínico resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 2400));
    await tester.pumpWidget(_app(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
