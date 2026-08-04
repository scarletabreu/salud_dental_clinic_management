@Tags(['capturas'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Arnés de capturas: renderiza los widgets reales, con los temas reales, y
/// escribe PNG a disco para revisarlos a ojo. No lanza la aplicación ni abre
/// ninguna ventana, así que se puede ejecutar mientras se trabaja en otra cosa.
///
///   flutter test test/features/odontograma/capturas_odontograma_test.dart \
///     --dart-define=CAPTURAS_DIR=/ruta/donde/dejarlas
///
/// Sin `CAPTURAS_DIR` el test se salta la escritura y solo comprueba que la
/// vista se dibuja sin excepciones.
const _directorio = String.fromEnvironment('CAPTURAS_DIR');

Future<void> _capturar(WidgetTester tester, String nombre) async {
  expect(tester.takeException(), isNull, reason: '$nombre lanzó una excepción');
  if (_directorio.isEmpty) return;

  final objeto =
      tester.renderObject(find.byKey(const ValueKey('lienzo-captura')))
          as RenderRepaintBoundary;

  // La codificación a PNG ocurre fuera del isolate del test: bajo el reloj
  // falso de `pumpWidget`, el futuro de `toByteData` nunca se completa y la
  // suite se cuelga después de la primera captura.
  await tester.runAsync(() async {
    final imagen = await objeto.toImage(pixelRatio: 2);
    try {
      final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
      final destino = Directory(_directorio)..createSync(recursive: true);
      File('${destino.path}/$nombre.png')
          .writeAsBytesSync(datos!.buffer.asUint8List(), flush: true);
    } finally {
      imagen.dispose();
    }
  });
}

Future<void> _montar(
  WidgetTester tester, {
  required ThemeData tema,
  required Widget hijo,
  required Size viewport,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: tema,
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: context.appColors.bgPage,
          body: RepaintBoundary(
            key: const ValueKey('lienzo-captura'),
            // El fondo va dentro del lienzo: el Scaffold pinta por encima del
            // RepaintBoundary y la captura saldría transparente, que es
            // justo lo que hay que poder juzgar en modo oscuro.
            child: ColoredBox(
              color: context.appColors.bgPage,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  // Las vistas viven dentro de una tarjeta en la aplicación.
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.appColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: hijo,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Dos bombeos bastan: el diagrama no anima. `pumpAndSettle` se atasca con
  // los 52 tooltips de las piezas.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// Una boca con trabajo suficiente para que se vean las dos capas: hallazgos de
/// hoy en tinta plena y antecedentes en tinta tenue.
EvaluacionOdontologica get _hoy => EvaluacionOdontologica.vacia
    .alternar(16, EstadoClinicoDental.cariada, superficie: TipoSuperficie.oclusal)
    .alternar(16, EstadoClinicoDental.cariada, superficie: TipoSuperficie.mesial)
    .alternar(26, EstadoClinicoDental.restaurada, superficie: TipoSuperficie.distal)
    .alternar(36, EstadoClinicoDental.restaurada, superficie: TipoSuperficie.vestibular)
    .alternar(48, EstadoClinicoDental.extraccionIndicada)
    .alternar(11, EstadoClinicoDental.pulpectomiaPulpotomia)
    .alternar(55, EstadoClinicoDental.perdida)
    .alternar(84, EstadoClinicoDental.restaurada, superficie: TipoSuperficie.distal)
    .conTejido(TejidoBlando.lengua, 'Úlcera en borde lateral izquierdo')
    .conTejido(TejidoBlando.encias, 'Gingivitis marginal generalizada');

EvaluacionOdontologica get _antes => EvaluacionOdontologica.vacia
    .alternar(17, EstadoClinicoDental.restaurada, superficie: TipoSuperficie.oclusal)
    .alternar(27, EstadoClinicoDental.perdida)
    .alternar(46, EstadoClinicoDental.noErupcionado)
    .alternar(31, EstadoClinicoDental.cariada, superficie: TipoSuperficie.incisal)
    .conTejido(TejidoBlando.paladarDuro, 'Torus palatino');

Odontograma get _odontograma => Odontograma(
  consultaId: 'c1',
  evaluacion: _hoy,
  evaluacionHistorica: _antes,
  dientes: [
    for (final fdi in kFdiPermanentes)
      Diente(
        odontogramaId: 'odo-1',
        fdiCode: fdi,
        superficies: superficiesParaFdi(fdi)
            .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
            .toList(),
        tratamientosAplicadosIds: {16, 26, 36}.contains(fdi)
            ? const ['t-1']
            : const [],
        tratamientosHistoricos: {17, 27, 46}.contains(fdi)
            ? [
                TratamientoAplicado(
                  tratamientoId: 't-viejo',
                  esContinuo: false,
                  estaTerminado: true,
                ),
              ]
            : const [],
      ),
  ],
);

/// Tablet en horizontal (la orientación con la que se usa en el sillón) y en
/// vertical, más el escritorio y un teléfono.
const _viewports = <String, Size>{
  'tablet': Size(1180, 1800),
  'tablet-vertical': Size(820, 2200),
  'escritorio': Size(1440, 1800),
  'movil': Size(390, 2200),
};

void main() {
  setUp(() {
    vistaOdontogramaPreferida.value = VistaOdontograma.formulario;
  });

  for (final tema in {'claro': AppTheme.light, 'oscuro': AppTheme.dark}.entries) {
    group('Capturas · tema ${tema.key}', () {
      for (final viewport in _viewports.entries) {
        testWidgets('formulario editable · ${viewport.key}', (tester) async {
          await _montar(
            tester,
            tema: tema.value,
            viewport: viewport.value,
            hijo: OdontodiagramaWidget(
              evaluacion: _hoy,
              historico: _antes,
              editable: true,
              onChanged: (_) {},
            ),
          );
          await _capturar(
            tester,
            'formulario-editable_${tema.key}_${viewport.key}',
          );
        });

        testWidgets('formulario de lectura · ${viewport.key}', (tester) async {
          await _montar(
            tester,
            tema: tema.value,
            viewport: viewport.value,
            hijo: OdontodiagramaWidget(evaluacion: _hoy, historico: _antes),
          );
          await _capturar(
            tester,
            'formulario-lectura_${tema.key}_${viewport.key}',
          );
        });

        testWidgets('arcada · ${viewport.key}', (tester) async {
          vistaOdontogramaPreferida.value = VistaOdontograma.arcada;
          await _montar(
            tester,
            tema: tema.value,
            viewport: viewport.value,
            hijo: VistasOdontograma(odontograma: _odontograma),
          );
          await _capturar(tester, 'arcada_${tema.key}_${viewport.key}');
        });
      }

      testWidgets('selector de vistas · tablet', (tester) async {
        await _montar(
          tester,
          tema: tema.value,
          viewport: _viewports['tablet']!,
          hijo: VistasOdontograma(odontograma: _odontograma, editable: true),
        );
        await _capturar(tester, 'selector_${tema.key}_tablet');
      });

      testWidgets('hoja imprimible · tablet', (tester) async {
        await _montar(
          tester,
          tema: tema.value,
          viewport: _viewports['tablet']!,
          hijo: OdontodiagramaPapel(evaluacion: _hoy, historico: _antes),
        );
        await _capturar(tester, 'hoja-impresion_${tema.key}_tablet');
      });
    });
  }
}
