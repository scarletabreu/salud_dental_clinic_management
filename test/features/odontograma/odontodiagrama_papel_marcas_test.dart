import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/glifo_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// La hoja que se imprime tiene que enseñar lo que se hizo en la consulta,
/// también cuando el catálogo no le asignó una clave del formulario en papel.
///
/// Las claves impresas son un vocabulario cerrado de siete entradas y la mayor
/// parte del catálogo real no cabe en ellas (una reconstrucción, un implante,
/// una prótesis). Para eso existe la capa de superficies teñidas: hace visible
/// el trabajo aunque no haya símbolo que estampar. La hoja de expediente no la
/// recibía, así que esas consultas se imprimían en blanco.
void main() {
  Diente diente(
    int fdi, {
    TipoSuperficie? superficie,
    String? clave,
    String nombre = 'Reconstrucción dental',
  }) => Diente(
    odontogramaId: 'o-1',
    fdiCode: fdi,
    superficies: const [],
    tratamientos: [
      TratamientoAplicado(
        id: 't-1',
        tratamientoId: 'cat-1',
        esContinuo: false,
        estaTerminado: true,
        superficie: superficie,
        claveOdontograma: clave,
        nombreTratamiento: nombre,
      ),
    ],
  );

  Future<void> montar(
    WidgetTester tester,
    List<Diente> dientes, {
    List<String> generales = const [],
  }) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final odontograma = Odontograma(consultaId: 'c-1', dientes: dientes);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OdontodiagramaPapel(
              evaluacion: odontograma.evaluacionProyectada,
              dientes: {for (final d in dientes) d.fdiCode: d},
              generales: generales,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  GlifoPiezaPainter pintor(WidgetTester tester, int fdi) {
    final pintura = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byKey(ValueKey('pieza_$fdi')),
        matching: find.byType(CustomPaint),
      ),
    );
    return pintura.painter! as GlifoPiezaPainter;
  }

  testWidgets('un tratamiento por cara sin clave del papel tiñe su cara en la '
      'hoja de expediente', (tester) async {
    await montar(tester, [
      diente(16, superficie: TipoSuperficie.oclusal),
      diente(26, superficie: TipoSuperficie.mesial, clave: 'restaurada'),
    ]);

    final marca = pintor(tester, 16).superficies[TipoSuperficie.oclusal];
    expect(
      marca,
      isNotNull,
      reason: 'sin esto la hoja sale en blanco pese al tratamiento',
    );
    expect(marca!.titulo, 'Reconstrucción dental');

    // La pieza intacta sigue intacta: no se tiñe la boca entera.
    expect(pintor(tester, 17).superficies, isEmpty);
  });

  testWidgets('un tratamiento de pieza completa sin clave marca la pieza', (
    tester,
  ) async {
    await montar(tester, [diente(36, nombre: 'Implante')]);

    expect(pintor(tester, 36).piezaCompleta?.titulo, 'Implante');
    expect(pintor(tester, 37).piezaCompleta, isNull);
  });

  testWidgets('la hoja impresa nombra por escrito lo anotado en cada pieza', (
    tester,
  ) async {
    await montar(tester, [
      diente(16, superficie: TipoSuperficie.oclusal),
      diente(36, nombre: 'Implante'),
    ]);

    // En pantalla se toca la pieza para saber qué tiene; en papel no se puede
    // tocar nada, así que la hoja lo tiene que decir.
    expect(find.text('Reconstrucción dental'), findsOneWidget);
    expect(find.text('Implante'), findsOneWidget);
    expect(find.textContaining('16'), findsWidgets);
  });

  testWidgets('una consulta sin nada por pieza lo dice en vez de salir en '
      'blanco', (tester) async {
    await montar(tester, [
      Diente(odontogramaId: 'o-1', fdiCode: 16, superficies: const []),
    ]);

    expect(
      find.text('No se anotó nada sobre ninguna pieza en esta consulta.'),
      findsOneWidget,
    );
  });

  testWidgets('lo registrado sin pieza se nombra y se rotula como tal', (
    tester,
  ) async {
    // Una limpieza es de arcada: no cuelga de ningún diente y el dibujo no
    // puede enseñarla. Callarla dejaba la hoja indistinguible de un fallo.
    await montar(tester, const [], generales: ['Profilaxis dental']);

    expect(find.text('Profilaxis dental'), findsOneWidget);
    expect(find.text('Sin pieza'), findsOneWidget);
  });

  testWidgets('sin dientes la hoja se comporta como antes', (tester) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OdontodiagramaPapel(
              evaluacion: EvaluacionOdontologica.vacia,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(pintor(tester, 16).superficies, isEmpty);
    expect(pintor(tester, 16).piezaCompleta, isNull);
  });
}
