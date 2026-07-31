// E2E de navegador sobre la aplicación real.
//
// Cubre la limitación #1 del informe de certificación HFX-CLIN-006: las
// jornadas ejercen la frontera REST con los tokens de cada rol, pero nadie
// había pulsado los botones. Aquí se arranca `main()` de verdad —Supabase
// inicializado, inyección de dependencias, red real contra el stack local— y
// se conduce la interfaz como lo haría una persona.
//
// Requisitos previos (los prepara tool/e2e/jornada_ui.sh):
//   · stack local levantado,
//   · seed de certificación aplicado,
//   · overlay `supabase/tests/e2e_ui_login_overlay.sql`, que hace alcanzables
//     a los actores desde una pantalla que compone el correo como
//     `<usuario>@saluddental.com`.
//
// Se ejecuta headless, sin abrir ninguna ventana:
//   tool/e2e/jornada_ui.sh

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:salud_dental_clinic_management/main.dart' as app;

/// Excepciones de framework capturadas durante todo el recorrido.
///
/// Un `RenderFlex overflowed` o un cast fallido pintan un recuadro rojo pero no
/// tumban la prueba: sin este colector, un E2E puede pasar sobre una pantalla
/// visiblemente rota.
final List<FlutterErrorDetails> _erroresDeUi = <FlutterErrorDetails>[];

const _usuario = 'cert_admin';
const _clave = 'Cert-2026!';

/// Bombea hasta que `finder` aparezca, en vez de `pumpAndSettle`.
///
/// `pumpAndSettle` espera a que no queden frames pendientes, y con peticiones
/// de red en vuelo eso o bien se agota o bien devuelve antes de que llegue la
/// respuesta. Aquí se bombea a intervalos fijos y se comprueba en cada uno.
Future<void> esperarPor(
  WidgetTester tester,
  Finder finder, {
  Duration limite = const Duration(seconds: 30),
  String? descripcion,
}) async {
  final fin = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail(
    'No apareció ${descripcion ?? finder.toString()} tras '
    '${limite.inSeconds}s.',
  );
}

/// Escribe en el campo cuyo `hintText` es [pista].
///
/// Los campos del formulario de paciente no llevan `Key`, y buscarlos por
/// posición se rompe en cuanto alguien reordena la ficha. El texto de ayuda es
/// lo único estable y visible que los distingue.
Future<void> escribirEnCampo(
  WidgetTester tester,
  String pista,
  String texto,
) async {
  final campo = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == pista,
  );
  expect(campo, findsWidgets, reason: 'no hay ningún campo con la pista «$pista»');

  await tester.ensureVisible(campo.first);
  await tester.pump(const Duration(milliseconds: 150));
  // Enfocar antes de escribir: sin foco, `enterText` no siempre fija el valor
  // y el campo se queda vacío sin dar el menor aviso, que fue justo lo que
  // hacía que el alta llegase al final con la ficha en blanco.
  await tester.tap(campo.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(campo.first, texto);
  await tester.pump(const Duration(milliseconds: 250));

  // Comprobar que se quedó escrito, para fallar aquí y no tres pasos después.
  //
  // Se comparan sólo los caracteres alfanuméricos porque algunos campos llevan
  // formateador: la cédula entra como «00100000001» y queda «001-0000000-1».
  String soloUtil(String s) =>
      s.replaceAll(RegExp('[^0-9a-zA-ZáéíóúÁÉÍÓÚñÑ]'), '').toLowerCase();

  final buscado = soloUtil(texto);
  final escrito = tester
      .widgetList<EditableText>(find.byType(EditableText))
      .any((e) => soloUtil(e.controller.text) == buscado);
  expect(
    escrito,
    isTrue,
    reason: 'el campo «$pista» no retuvo el texto «$texto»',
  );
}

/// Navega por el destino `etiqueta` del shell y comprueba que pinta algo.
Future<void> abrirDestino(WidgetTester tester, String etiqueta) async {
  final destino = find.text(etiqueta);
  expect(
    destino,
    findsWidgets,
    reason: 'el destino «$etiqueta» no está en la navegación',
  );

  await tester.tap(destino.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
  // Margen para que el cubit del destino resuelva su carga contra la red.
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }

  expect(
    find.byType(ErrorWidget),
    findsNothing,
    reason: 'el destino «$etiqueta» pintó un ErrorWidget',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final anterior = FlutterError.onError;
    FlutterError.onError = (details) {
      _erroresDeUi.add(details);
      anterior?.call(details);
    };
  });

  // Se entra como `cert_admin` y no como la doctora a propósito: dar de alta un
  // paciente es capacidad de admin o asistente (SD-149 — el doctor trabaja el
  // expediente clínico, no la ficha administrativa), así que a la doctora la
  // pantalla ni siquiera le ofrece el botón. El admin, además, es doctor en
  // todas las capas desde HFX-CLIN-000, de modo que el resto del recorrido
  // clínico sigue siendo el mismo.
  testWidgets('jornada del admin-doctor por la interfaz real', (tester) async {
    // Escritorio: con el sidebar desplegado se recorren los destinos por su
    // etiqueta, que es como los ve quien usa la clínica.
    await tester.binding.setSurfaceSize(const Size(1440, 900));

    app.main();
    await tester.pump(const Duration(seconds: 1));

    // -------------------------------------------------------------------
    // 1 · La app arranca en el login, no en la pantalla de fallo de arranque
    // -------------------------------------------------------------------
    await esperarPor(
      tester,
      find.text('Clínica Salud Dental Integral'),
      descripcion: 'la pantalla de login',
    );
    expect(
      find.textContaining('Revise la configuración'),
      findsNothing,
      reason: 'la app arrancó en la pantalla de fallo de configuración',
    );

    // -------------------------------------------------------------------
    // 2 · Inicio de sesión con las credenciales del seed
    // -------------------------------------------------------------------
    final campos = find.byType(TextFormField);
    expect(campos, findsNWidgets(2));
    await tester.enterText(campos.at(0), _usuario);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(campos.at(1), _clave);
    await tester.pump(const Duration(milliseconds: 100));

    // El botón de acceso no es un `ElevatedButton`: es un `InkWell` dentro de
    // un `AnimatedContainer` pintado a mano, así que se busca por su texto.
    await tester.tap(find.text('Iniciar sesión'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 500));

    await esperarPor(
      tester,
      find.text('Inicio'),
      limite: const Duration(seconds: 45),
      descripcion: 'el dashboard tras iniciar sesión',
    );

    // -------------------------------------------------------------------
    // 3 · Recorrido por los destinos que el actor tiene a su alcance
    // -------------------------------------------------------------------
    for (final destino in const ['Consultas', 'Pacientes', 'Inicio']) {
      await abrirDestino(tester, destino);
    }

    // -------------------------------------------------------------------
    // 4 · Alta de un paciente, entera por la interfaz
    // -------------------------------------------------------------------
    // Este es el paso que faltaba. Las jornadas de certificación escriben el
    // payload REST a mano, ya en snake_case, así que nunca ejercitan el
    // datasource de Dart: por ahí se coló que el tipo de sangre viajara como
    // `TipoSangre.name` («oPositivo»), que Postgres rechaza con 22P02 tumbando
    // la transacción entera. El alta fallaba siempre y los 14 gates seguían
    // verdes.
    await abrirDestino(tester, 'Pacientes');

    final nuevoPaciente = find.text('Nuevo Paciente');
    expect(
      nuevoPaciente,
      findsWidgets,
      reason: 'no hay botón de alta en el listado de pacientes',
    );
    await tester.ensureVisible(nuevoPaciente.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(nuevoPaciente.first);
    await tester.pump(const Duration(milliseconds: 600));
    // `_FormField` pinta su etiqueta con `toUpperCase()`, así que en pantalla
    // pone «NOMBRE *» y no «Nombre *».
    await esperarPor(
      tester,
      find.text('NOMBRE *'),
      descripcion: 'el formulario de paciente',
    );

    await escribirEnCampo(tester, 'Ana', 'Elena');
    await escribirEnCampo(tester, 'García', 'Encarnación E2E');
    await escribirEnCampo(tester, '000-0000000-0', '00100000001');

    // La fecha de nacimiento suele llegar ya puesta: el borrador de alta nace
    // con `DateTime.now()` y el formulario la copia, así que el campo muestra
    // la fecha de hoy en vez de «Seleccionar fecha». Sólo hay que abrir el
    // selector cuando de verdad está vacío.
    final seleccionarFecha = find.text('Seleccionar fecha');
    if (seleccionarFecha.evaluate().isNotEmpty) {
      await tester.tap(seleccionarFecha.first);
      await tester.pump(const Duration(milliseconds: 600));
      await esperarPor(
        tester,
        find.text('OK'),
        descripcion: 'el selector de fecha',
      );
      await tester.tap(find.text('OK'));
      await tester.pump(const Duration(milliseconds: 600));
    }

    // Sin teléfono la RPC responde CL018: es un dato obligatorio del alta.
    await escribirEnCampo(tester, '809-000-0000', '8095550123');

    final guardar = find.text('Guardar');
    expect(guardar, findsWidgets, reason: 'no hay botón de guardar en la ficha');
    await tester.ensureVisible(guardar.first);
    await tester.pump(const Duration(milliseconds: 200));
    // Sin `warnIfMissed: false`: si la pulsación no aterriza en el botón, se
    // quiere saber. Silenciarlo fue lo que dejó pasar un alta que en pantalla
    // parecía correcta y no escribía nada.
    await tester.tap(guardar.first);

    // El alta es una RPC: hay que darle tiempo de ida y vuelta. La señal de
    // éxito es que la ficha se cierra y se vuelve al listado; quedarse en el
    // formulario significa que la validación o el servidor la rechazaron.
    final fin = DateTime.now().add(const Duration(seconds: 30));
    var cerrado = false;
    while (DateTime.now().isBefore(fin)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('NOMBRE *').evaluate().isEmpty) {
        cerrado = true;
        break;
      }
    }

    if (!cerrado) {
      // Lo que haya dicho la pantalla explica por qué no se guardó: el aviso de
      // validación y el de fallo del servidor se muestran ambos como SnackBar.
      // Los errores de validación de `TextFormField` se pintan bajo el campo,
      // no como SnackBar, así que hay que mirar todo el texto visible.
      final enPantalla = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      fail('la ficha no se cerró tras guardar. Texto en pantalla: $enPantalla');
    }

    // -------------------------------------------------------------------
    // 5 · Ninguna pantalla dejó una excepción por el camino
    // -------------------------------------------------------------------
    expect(
      _erroresDeUi.map((e) => e.exceptionAsString()).toList(),
      isEmpty,
      reason: 'la interfaz lanzó excepciones durante el recorrido',
    );
  });
}
