// E2E de navegador · la agenda de un doctor no muestra la de los demás.
//
// Reproduce el escenario del que se quejó la clínica el 3 ago 2026: «los
// doctores siguen viendo las citas de los demás y el filtro por doctores sigue
// ahí». Para que la prueba tenga sentido, la base debe tener citas de DOS
// doctores el mismo día — si sólo hay uno, no ver al otro no demuestra nada.
// De eso se encarga `tool/e2e/alcance_doctor.sh` antes de conducir el navegador.
//
//   tool/e2e/alcance_doctor.sh
//
// Se comprueban las dos mitades del contrato:
//   · el dato: ninguna cita de la agenda pertenece a otro doctor;
//   · la interfaz: el filtro por doctores no se pinta, porque en el alcance de
//     un doctor sólo hay un odontólogo y ese filtro es del admin (D15).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:salud_dental_clinic_management/main.dart' as app;

import 'jornada_ui_test.dart' show abrirDestino, iniciarSesion;

final List<FlutterErrorDetails> _erroresDeUi = <FlutterErrorDetails>[];

const _usuarioDoctora = 'cert_doctora';

/// El otro doctor del escenario: el admin, que también ejerce
/// (HFX-CLIN-000). Sus citas están en la misma agenda del mismo día.
const _nombreDelOtroDoctor = 'Alma';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final anterior = FlutterError.onError;
    FlutterError.onError = (details) {
      _erroresDeUi.add(details);
      anterior?.call(details);
    };
  });

  testWidgets('la doctora no ve la agenda de otro doctor ni su filtro', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));

    app.main();
    await tester.pump(const Duration(seconds: 1));
    await iniciarSesion(tester, _usuarioDoctora);

    await abrirDestino(tester, 'Mis Citas del Día');

    // Presencia que sostiene las ausencias: si la agenda no hubiera cargado,
    // todo lo de abajo faltaría y la prueba pasaría en falso.
    expect(
      find.byTooltip('Registrar urgencia (paciente sin cita)'),
      findsWidgets,
      reason: 'la agenda no llegó a pintarse',
    );

    // ------------------------------------------------------------ el dato
    expect(
      find.textContaining(_nombreDelOtroDoctor),
      findsNothing,
      reason:
          'la agenda de la doctora muestra una cita del otro doctor: el '
          'alcance por doctor no se está aplicando',
    );

    // -------------------------------------------------------- la interfaz
    expect(
      find.byKey(const Key('filtro_doctor_todos')),
      findsNothing,
      reason:
          'el filtro por doctores se pinta en la sesión de un doctor; sólo '
          'debe existir para quien gestiona la agenda completa (D15)',
    );

    // ------------------------------------------------- el listado de consultas
    // Misma regla en la otra pantalla que lista trabajo clínico: al doctor no
    // se le ofrece elegir doctor, porque sólo existe el suyo.
    await abrirDestino(tester, 'Consultas');
    expect(
      find.text('Todos los doctores'),
      findsNothing,
      reason:
          'el filtro por doctores aparece en el listado de consultas de un '
          'doctor; es de quien gestiona la agenda completa',
    );

    expect(
      _erroresDeUi.map((e) => e.exceptionAsString()).toList(),
      isEmpty,
      reason: 'la interfaz lanzó excepciones durante el recorrido',
    );
  });
}
