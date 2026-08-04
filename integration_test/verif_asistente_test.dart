// Verificación post-audit · jornada de la asistente de recepción.
//
// Recorre lo que hace una asistente en un día normal: abrir la agenda de los
// doctores que apoya, dar por presente a un paciente, dar de alta a alguien
// nuevo, agendarle cita y mirar el dinero del día. Y comprueba las dos
// ausencias que la separan de la clínica: no ejerce (no hay «Iniciar
// consulta») y no tiene el módulo de Consultas.
//
// Requiere: stack local + seed de certificación + overlay de login + overlay
// `e2e_agenda_hoy_overlay.sql` (la asistente sólo ve las citas de los doctores
// con los que tiene fila en `doctor_asistentes`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:salud_dental_clinic_management/main.dart' as app;

import 'jornada_ui_test.dart'
    show abrirDestino, escribirEnCampo, esperarPor, iniciarSesion;

final List<FlutterErrorDetails> _erroresDeUi = <FlutterErrorDetails>[];

/// Texto visible en pantalla: sin esto, un fallo de la jornada sólo dice qué
/// no apareció, nunca qué había en su lugar.
String _textoVisible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .where((s) => s.trim().isNotEmpty)
    .toSet()
    .join(' ~ ');

Future<void> _bombear(WidgetTester tester, [int veces = 10]) async {
  for (var i = 0; i < veces; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// `pumpAndSettle` sin tope se cuelga diez minutos en cuanto hay un indicador
/// de progreso girando. Aquí se le pone límite y, si no asienta, se sigue
/// bombeando.
Future<void> _asentar(WidgetTester tester) async {
  // Nada de `pumpAndSettle`: en esta pantalla siempre hay una animación o una
  // petición en vuelo, así que agota su plazo y —aunque se capture el throw—
  // la binding ya anotó la excepción. El resultado era una jornada que hacía
  // todo bien y terminaba en «Multiple exceptions (3) were detected», que
  // parece un defecto de la aplicación y es del arnés.
  await _bombear(tester, 8);
}

bool _subarbolContieneTexto(Element raiz, String texto) {
  var encontrado = false;
  void visitar(Element elemento) {
    if (encontrado) return;
    final widget = elemento.widget;
    if (widget is Text && (widget.data ?? '').contains(texto)) {
      encontrado = true;
      return;
    }
    elemento.visitChildElements(visitar);
  }

  visitar(raiz);
  return encontrado;
}

/// La tarjeta accionable de una cita: el único `InkWell` que contiene a la vez
/// el nombre del paciente y sus botones.
Finder _tarjetaDeCita(String nombre) => find.byElementPredicate(
  (element) =>
      element.widget is InkWell && _subarbolContieneTexto(element, nombre),
  description: 'tarjeta de la cita de $nombre',
);

Future<void> _escribirHint(
  WidgetTester tester,
  String hint,
  String texto,
) async {
  final campo = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == hint,
  );
  await esperarPor(tester, campo, descripcion: 'el campo «$hint»');
  await tester.ensureVisible(campo.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(campo.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(campo.first, texto);
  await _bombear(tester, 3);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jornada de la asistente por la interfaz real', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    // El manejador se instala DENTRO de la prueba: la binding pone el suyo
    // al arrancar `runTest`, así que hacerlo en `setUpAll` no captura nada y
    // el fallo llega como «Multiple exceptions (N) were detected», sin decir
    // cuáles. No se reenvía al anterior: se afirman al final, con su texto.
    final anterior = FlutterError.onError;
    FlutterError.onError = (d) => _erroresDeUi.add(d);
    addTearDown(() => FlutterError.onError = anterior);
    app.main();
    await tester.pump(const Duration(seconds: 1));

    await iniciarSesion(tester, 'cert_asistente');

    // -------------------------------------------------------------------
    // 1 · La navegación que le corresponde
    // -------------------------------------------------------------------
    // Presencias primero: si el menú no cargara, las ausencias de abajo
    // pasarían en falso.
    for (final destino in const [
      'Mis Citas del Día',
      'Pacientes',
      'Cuentas por Cobrar',
      'Caja',
    ]) {
      expect(
        find.text(destino),
        findsWidgets,
        reason: 'la asistente debe tener «$destino» en la navegación',
      );
    }
    expect(
      find.text('Consultas'),
      findsNothing,
      reason: 'la asistente no ejerce clínica: no debe ver Consultas',
    );
    expect(
      find.text('Perfiles'),
      findsNothing,
      reason: 'administrar personal es sólo del admin',
    );
    expect(
      find.text('Inventario'),
      findsNothing,
      reason: 'los catálogos clínicos no son de recepción',
    );

    // -------------------------------------------------------------------
    // 2 · La agenda de los doctores que apoya
    // -------------------------------------------------------------------
    await abrirDestino(tester, 'Mis Citas del Día');
    await esperarPor(
      tester,
      find.textContaining('Elena Espinal'),
      limite: const Duration(seconds: 60),
      descripcion: 'la cita de Elena en la agenda de la asistente',
    );
    // La agenda es la de los doctores asignados: también ve las del admin.
    expect(
      find.textContaining('Pablo Peña'),
      findsWidgets,
      reason: 'la asistente no ve la agenda del admin-doctor al que apoya',
    );

    // -------------------------------------------------------------------
    // 3 · Registrar la llegada — y NO poder iniciar la consulta
    // -------------------------------------------------------------------
    final llegadaElena = find.descendant(
      of: _tarjetaDeCita('Elena Espinal'),
      matching: find.text('Registrar llegada'),
    );
    await esperarPor(
      tester,
      llegadaElena,
      descripcion: '«Registrar llegada» en la cita de Elena',
    );
    await tester.ensureVisible(llegadaElena.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(llegadaElena.first, warnIfMissed: false);
    await _bombear(tester, 16);

    // Se recarga el destino y se comprueba el resumen del día, no la tarjeta:
    // la lista se autodesplaza a la hora en curso, así que la de Elena (08:30)
    // queda por encima del viewport construido y buscarla ahí es frágil.
    await abrirDestino(tester, 'Mis Citas del Día');
    await esperarPor(
      tester,
      find.textContaining('en espera'),
      limite: const Duration(seconds: 60),
      descripcion:
          'el resumen del día con la llegada registrada '
          '(pantalla: ${_textoVisible(tester)})',
    );

    // Ninguna cita del día debe ofrecerle iniciar consulta: recepción no
    // ejerce clínica.
    expect(
      find.text('Iniciar consulta'),
      findsNothing,
      reason: 'la asistente no ejerce: ninguna cita debe ofrecer iniciarla',
    );

    // -------------------------------------------------------------------
    // 4 · Alta de paciente entera por la ficha
    // -------------------------------------------------------------------
    await abrirDestino(tester, 'Pacientes');
    final nuevoPaciente = find.text('Nuevo Paciente');
    expect(
      nuevoPaciente,
      findsWidgets,
      reason: 'recepción debe poder dar de alta pacientes',
    );
    await tester.ensureVisible(nuevoPaciente.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(nuevoPaciente.first);
    await esperarPor(
      tester,
      find.text('NOMBRE *'),
      descripcion: 'el formulario de paciente',
    );

    await escribirEnCampo(tester, 'Ana', 'Rosa');
    await escribirEnCampo(tester, 'García', 'Recepción E2E');
    await escribirEnCampo(tester, '000-0000000-0', '00200000002');
    final seleccionarFecha = find.text('Seleccionar fecha');
    if (seleccionarFecha.evaluate().isNotEmpty) {
      await tester.tap(seleccionarFecha.first);
      await esperarPor(tester, find.text('OK'), descripcion: 'selector fecha');
      await tester.tap(find.text('OK'));
      await _bombear(tester, 4);
    }
    await escribirEnCampo(tester, '809-000-0000', '8095550199');

    final guardar = find.text('Guardar');
    await tester.ensureVisible(guardar.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(guardar.first);

    final finAlta = DateTime.now().add(const Duration(seconds: 30));
    var cerrado = false;
    while (DateTime.now().isBefore(finAlta)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('NOMBRE *').evaluate().isEmpty) {
        cerrado = true;
        break;
      }
    }
    if (!cerrado) {
      final enPantalla = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      fail('la ficha no se cerró tras guardar. Texto en pantalla: $enPantalla');
    }

    // -------------------------------------------------------------------
    // 5 · Agendarle cita al paciente recién creado
    // -------------------------------------------------------------------
    await abrirDestino(tester, 'Mis Citas del Día');
    final nuevaCita = find.text('Nueva Cita');
    expect(
      nuevaCita,
      findsWidgets,
      reason: 'recepción debe poder agendar citas',
    );
    await tester.tap(nuevaCita.first, warnIfMissed: false);
    await esperarPor(
      tester,
      find.text('Agendar Nueva Cita'),
      descripcion: 'el diálogo de nueva cita',
    );
    await _escribirHint(tester, 'Nombre, apellido o cédula...', 'Rosa');
    final resultado = find.widgetWithText(ListTile, 'Rosa Recepción E2E');
    await esperarPor(
      tester,
      resultado,
      limite: const Duration(seconds: 30),
      descripcion: 'el paciente recién creado en la búsqueda',
    );
    await tester.tap(resultado.first);
    await esperarPor(
      tester,
      find.text('Detalles de la Cita'),
      descripcion: 'el paso de detalles de la cita',
    );

    // La asistente no ejerce: tiene que elegir odontólogo explícitamente.
    final desplegableDoctor = find.byWidgetPredicate(
      (w) => w.runtimeType.toString().startsWith('DropdownButtonFormField'),
    );
    expect(
      desplegableDoctor,
      findsWidgets,
      reason:
          'la asistente no puede agendar sin escoger odontólogo; el selector '
          'debe estar disponible (no fijo)',
    );
    await tester.ensureVisible(desplegableDoctor.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(desplegableDoctor.first);
    await _asentar(tester);
    final opcionDoctora = find.text('Dr. Delia Clínica').last;
    await tester.tap(opcionDoctora);
    await _asentar(tester);

    // Mañana, no hoy: el diálogo rechaza —con razón— cualquier fecha/hora ya
    // pasada, y el selector de hora se abre en la hora actual.
    await tester.tap(find.text('Seleccionar fecha').first);
    await esperarPor(
      tester,
      find.byType(DatePickerDialog),
      descripcion: 'el selector de fecha',
    );
    final manana = DateTime.now().add(const Duration(days: 1)).day.toString();
    final diaManana = find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.text(manana),
    );
    await esperarPor(tester, diaManana, descripcion: 'el día $manana');
    await tester.tap(diaManana.last);
    await _bombear(tester, 2);
    await tester.tap(find.text('OK').last);
    await _bombear(tester, 4);
    await tester.tap(find.text('Seleccionar hora').first);
    await esperarPor(tester, find.text('OK'), descripcion: 'selector de hora');
    await tester.tap(find.text('OK').last);
    await _bombear(tester, 4);

    await _escribirHint(
      tester,
      'Ej. Evaluación por dolor en molar superior...',
      'VERIF recepción: primera evaluación',
    );
    final confirmar = find.text('Confirmar Cita');
    await tester.ensureVisible(confirmar.first);
    await _bombear(tester, 2);
    final confirmarAlcanzable = confirmar.hitTestable();
    expect(
      confirmarAlcanzable,
      findsWidgets,
      reason: '«Confirmar Cita» no es alcanzable por hit-test',
    );
    await tester.tap(confirmarAlcanzable.first);

    final traza = <String>['t0: ${_textoVisible(tester)}'];
    final fin = DateTime.now().add(const Duration(seconds: 45));
    var agendada = false;
    var siguiente = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(fin)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('Cita agendada correctamente.').evaluate().isNotEmpty) {
        agendada = true;
        break;
      }
      if (DateTime.now().isAfter(siguiente)) {
        traza.add('t+: ${_textoVisible(tester)}');
        siguiente = DateTime.now().add(const Duration(seconds: 8));
      }
    }
    if (!agendada) {
      fail('La cita no se agendó tras 45 s. Traza: ${traza.join(" ||| ")}');
    }
    await _bombear(tester, 10);

    // -------------------------------------------------------------------
    // 6 · El dinero del día: cuentas y caja se pintan sin error
    // -------------------------------------------------------------------
    await abrirDestino(tester, 'Cuentas por Cobrar');
    expect(
      find.textContaining('Error'),
      findsNothing,
      reason: 'Cuentas por Cobrar pintó un error para la asistente',
    );
    await abrirDestino(tester, 'Caja');
    expect(
      find.textContaining('Error'),
      findsNothing,
      reason: 'Caja pintó un error para la asistente',
    );

    expect(
      _erroresDeUi.map((e) => e.exceptionAsString()).toList(),
      isEmpty,
      reason: 'la interfaz lanzó excepciones durante la jornada de recepción',
    );
  });
}
