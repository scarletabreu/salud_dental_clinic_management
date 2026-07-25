import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/pdf/odontodiagrama_pdf.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_expediente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

EvaluacionOdontologica _evaluacion() => EvaluacionOdontologica.vacia
    .alternar(
      16,
      EstadoClinicoDental.cariada,
      superficie: TipoSuperficie.oclusal,
    )
    .alternar(46, EstadoClinicoDental.perdida)
    .conTejido(TejidoBlando.lengua, 'Úlcera en borde lateral');

void main() {
  testWidgets('el expediente expone un lienzo capturable a PNG', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OdontodiagramaExpediente(
              evaluacion: _evaluacion(),
              nombrePaciente: 'Ana Mercedes Rodríguez',
              fecha: DateTime(2026, 7, 24),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imprimir'), findsOneWidget);

    final lienzo = tester.renderObject<RenderRepaintBoundary>(
      find
          .ancestor(
            of: find.byKey(OdontodiagramaExpediente.lienzoKey),
            matching: find.byType(RepaintBoundary),
          )
          .first,
    );

    final imagen = await lienzo.toImage(pixelRatio: 2);
    addTearDown(imagen.dispose);

    // El lienzo tiene el diagrama entero, no una franja recortada.
    expect(imagen.width, greaterThan(600));
    expect(imagen.height, greaterThan(600));
  });

  test('el PDF se arma con la captura y la cabecera del paciente', () async {
    // Un PNG mínimo válido (1x1 transparente) basta para ejercitar el armado.
    final png = Uint8List.fromList(<int>[
      137, 80, 78, 71, 13, 10, 26, 10, //
      0, 0, 0, 13, 73, 72, 68, 82,
      0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
      0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1,
      13, 10, 45, 180,
      0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
    ]);

    final bytes = await generarOdontodiagramaPdf(
      diagramaPng: png,
      nombrePaciente: 'Ana Mercedes Rodríguez',
      fecha: DateTime(2026, 7, 24),
      // Tema explícito: el de producción descarga Open Sans y el test no debe
      // depender de la red.
      tema: pw.ThemeData(),
    );

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(
      nombreArchivoOdontodiagrama(DateTime(2026, 7, 24)),
      'odontodiagrama_20260724.pdf',
    );
  });
}
