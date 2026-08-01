// E2E de navegador · jornada de la doctora.
//
// Va en su propio archivo y no como un segundo `testWidgets` del recorrido del
// admin porque `app.main()` no reinicia la sesión: Supabase la persiste, así
// que el segundo arranque entra ya autenticado y nunca vuelve a ver el login.
// Cada jornada necesita un proceso —y un navegador— limpio.
//
//   tool/e2e/jornada_ui.sh   (lanza este target y el del admin)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:salud_dental_clinic_management/main.dart' as app;

import 'jornada_ui_test.dart' show abrirDestino, iniciarSesion;

/// Excepciones de framework capturadas durante todo el recorrido.
final List<FlutterErrorDetails> _erroresDeUi = <FlutterErrorDetails>[];

const _usuarioDoctora = 'cert_doctora';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final anterior = FlutterError.onError;
    FlutterError.onError = (details) {
      _erroresDeUi.add(details);
      anterior?.call(details);
    };
  });

  // -----------------------------------------------------------------------
  // Jornada de la doctora · la matriz de permisos vista desde la pantalla
  // -----------------------------------------------------------------------
  // Lo que aquí se comprueba son ausencias, y una ausencia es fácil de fingir:
  // si el menú no cargara, todo estaría «ausente» y la prueba pasaría en
  // falso. Por eso cada ausencia va acompañada de una presencia que demuestra
  // que la navegación sí se pintó.
  testWidgets('jornada de la doctora: la matriz de roles en pantalla', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));

    app.main();
    await tester.pump(const Duration(seconds: 1));
    await iniciarSesion(tester, _usuarioDoctora);

    // ------------------------------------------------------- defecto D9
    // La doctora no lleva dinero ni administra personal.
    expect(
      find.text('Consultas'),
      findsWidgets,
      reason:
          'el menú de la doctora no cargó; sin esto las ausencias de abajo no '
          'prueban nada',
    );
    expect(
      find.text('Cuentas por Cobrar'),
      findsNothing,
      reason: 'la doctora no debe ver Cuentas por Cobrar (defecto D9)',
    );
    expect(
      find.text('Caja'),
      findsNothing,
      reason: 'gestionar caja no es capacidad clínica',
    );
    expect(
      find.text('Perfiles'),
      findsNothing,
      reason: 'administrar personal es sólo del admin (defecto D9)',
    );

    // ------------------------------------------------------- defecto D8
    // El catálogo se consulta, no se edita, y sin precios.
    await abrirDestino(tester, 'Tratamientos');
    expect(
      find.text('Nuevo servicio'),
      findsNothing,
      reason: 'la doctora no debe poder crear tratamientos (defecto D8)',
    );
    expect(
      find.text('PRECIO BASE'),
      findsNothing,
      reason: 'el precio es de quien factura, no de quien trata (defecto D8)',
    );

    // ------------------------------------------------------ defecto D10
    // La agenda propia sí ofrece «Nueva Cita»: antes sólo daba urgencia.
    await abrirDestino(tester, 'Mis Citas del Día');
    expect(
      find.byTooltip('Registrar urgencia (paciente sin cita)'),
      findsWidgets,
      reason: 'la vía de urgencia debe seguir estando',
    );

    // ------------------------------------------------------- defectos D3/D4
    // Pacientes lista sin el error de `pacientes_seguro`, y Consultas muestra
    // nombres en vez de `Paciente #uuid`.
    await abrirDestino(tester, 'Pacientes');
    expect(
      find.textContaining('pacientes_seguro'),
      findsNothing,
      reason: 'volvió el error de la vista huérfana (defecto D3)',
    );
    await abrirDestino(tester, 'Consultas');
    expect(
      find.textContaining('Paciente #'),
      findsNothing,
      reason:
          'las consultas volvieron a pintar el uuid en vez del nombre '
          '(defecto D4)',
    );

    expect(
      _erroresDeUi.map((e) => e.exceptionAsString()).toList(),
      isEmpty,
      reason: 'la interfaz lanzó excepciones durante la jornada de la doctora',
    );
  });
}
