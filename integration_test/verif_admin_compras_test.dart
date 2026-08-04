// Verificación post-audit · jornada del admin, segunda mitad: arqueo y compras.
//
// El arqueo del día (F2-01/S10) y la compra registrada + recibida
// (I1/I2/I5/I6), que era literalmente imposible antes de la corrección.
//
// Va aparte de `verif_admin_test.dart` porque juntas superaban los 20 minutos
// que `integration_test` le da al driver para devolver el resultado: la
// jornada terminaba su trabajo y la corrida moría igual, en un
// `DriverError: request_data`.
//
// Depende de que la jornada del admin se haya corrido antes: da por cobrada la
// cuenta de Sara.
//
// Requiere: stack local + seed de certificación + overlay de login + overlay
// `e2e_agenda_hoy_overlay.sql`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:salud_dental_clinic_management/main.dart' as app;

import 'jornada_ui_test.dart' show abrirDestino, esperarPor, iniciarSesion;

final List<FlutterErrorDetails> _erroresDeUi = <FlutterErrorDetails>[];

/// Excepciones que la binding guardó durante los `pump`.
///
/// `flutter drive` sólo informa «Multiple exceptions (N) were detected» sin
/// decir cuáles ni dónde. `takeException()` las vacía una a una, así que se
/// recogen por etapa y se cuentan al final.
final List<String> _excepciones = <String>[];
void _recoger(WidgetTester tester, String etapa) {
  final e = tester.takeException();
  if (e != null) _excepciones.add('[$etapa] $e');
}

Future<void> _bombear(WidgetTester tester, [int veces = 6]) async {
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
  await _bombear(tester, 5);
}


Future<void> _escribirEtiqueta(
  WidgetTester tester,
  String etiqueta,
  String texto,
) async {
  final campo = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == etiqueta,
  );
  await esperarPor(tester, campo, descripcion: 'el campo «$etiqueta»');
  await tester.ensureVisible(campo.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(campo.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(campo.first, texto);
  await _bombear(tester, 3);
}

Future<void> _escribirClave(
  WidgetTester tester,
  Key clave,
  String texto,
) async {
  final campo = find.byKey(clave);
  await esperarPor(tester, campo, descripcion: 'el campo $clave');
  await tester.ensureVisible(campo);
  await _bombear(tester, 2);
  await tester.tap(campo);
  await tester.enterText(campo, texto);
  await _bombear(tester, 3);
}



/// Texto visible en pantalla, para explicar un fallo sin adivinar.
String _pantalla(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .where((s) => s.trim().isNotEmpty)
    .toSet()
    .join(' | ');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jornada del admin · arqueo de caja y compras', (tester) async {
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

    await iniciarSesion(tester, 'cert_admin');

    // ===================================================================
    // 0 · Caja del día · F2-01
    // ===================================================================
    // El seed deja abierta la caja de un día anterior. Antes de la corrección
    // eso bloqueaba todos los cobros de hoy mientras la pantalla decía que la
    // caja estaba abierta; ahora la unicidad es por día civil y esta apertura
    // tiene que ser posible.
    await abrirDestino(tester, 'Caja');
    // El botón de la pantalla es «Abrir caja de hoy»; «Abrir caja» a secas es
    // el del diálogo de confirmación que viene después.
    final abrirCaja = find.text('Abrir caja de hoy');
    if (abrirCaja.evaluate().isNotEmpty) {
      await _escribirClave(tester, const Key('monto-apertura'), '5000');
      await tester.tap(abrirCaja.first);
      await esperarPor(
        tester,
        find.text('Confirmar apertura'),
        descripcion: 'la confirmación de apertura de caja',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Abrir caja'));
      await esperarPor(
        tester,
        find.text('Movimientos'),
        limite: const Duration(seconds: 45),
        descripcion:
            'la caja del día abierta (F2-01: una caja de otro día no debe '
            'impedirlo). Pantalla: ${_pantalla(tester)}',
      );
    } else {
      expect(
        find.text('Movimientos'),
        findsWidgets,
        reason:
            'la caja no está abierta ni ofrece abrirse. '
            'Pantalla: ${_pantalla(tester)}',
      );
    }
    _recoger(tester, 'apertura de caja');

    // ===================================================================
    // 4 · El cobro entró en la caja del día
    // ===================================================================
    await abrirDestino(tester, 'Caja');
    await esperarPor(
      tester,
      find.text('Movimientos'),
      limite: const Duration(seconds: 45),
      descripcion: 'el arqueo del día',
    );
    // El ingreso del cobro lo comprueba `verif_admin_test.dart`, que es quien
    // cobra; aquí basta con que el arqueo del día se pinte.

    _recoger(tester, 'caja del día');

    // ===================================================================
    // 5 · Compra: registrar y recibir (era imposible antes de la corrección)
    // ===================================================================
    await abrirDestino(tester, 'Inventario');
    _recoger(tester, 'abrir Inventario');
    await esperarPor(tester, find.text('Compras'), descripcion: 'pestañas');
    await tester.tap(find.text('Compras').first);
    await _bombear(tester, 10);
    _recoger(tester, 'pestaña Compras');

    final nuevaCompra = find.text('Nueva Compra');
    await esperarPor(tester, nuevaCompra, descripcion: 'el botón Nueva Compra');
    await tester.tap(nuevaCompra.first, warnIfMissed: false);
    await _bombear(tester, 8);
    _recoger(tester, 'abrir Nueva Compra');

    // Proveedor y consumible son desplegables (`DropdownButtonFormField`), no
    // campos de texto: el `hintText` vive en su decoración pero no hay ningún
    // `TextField` que lo lleve.
    Finder desplegable(String tipo) => find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == 'DropdownButtonFormField<$tipo>',
      description: 'desplegable de $tipo',
    );

    final selectorProveedor = desplegable('Suplidor');
    await esperarPor(
      tester,
      selectorProveedor,
      descripcion: 'el selector de proveedor',
    );
    await tester.ensureVisible(selectorProveedor.first);
    await _bombear(tester, 2);
    await tester.tap(selectorProveedor.first);
    await _asentar(tester);
    await esperarPor(
      tester,
      find.text('Depósito Dental E2E'),
      descripcion: 'el proveedor sembrado',
    );
    await tester.tap(find.text('Depósito Dental E2E').last);
    await _asentar(tester);
    _recoger(tester, 'elegir proveedor');

    final selectorConsumible = desplegable('Consumible');
    await esperarPor(
      tester,
      selectorConsumible,
      descripcion: 'el selector de consumible',
    );
    await tester.ensureVisible(selectorConsumible.first);
    await _bombear(tester, 2);
    await tester.tap(selectorConsumible.first);
    await _asentar(tester);
    final opcionConsumible = find.textContaining('Gutapercha punta F2');
    await esperarPor(
      tester,
      opcionConsumible,
      descripcion: 'el consumible sin stock',
    );
    await tester.tap(opcionConsumible.last);
    await _asentar(tester);
    _recoger(tester, 'elegir consumible');

    await _escribirEtiqueta(tester, 'Cantidad *', '10');
    await _escribirEtiqueta(tester, 'Precio Unitario (RD\$) *', '190');

    // El renglón se añade a la orden antes de registrarla.
    final agregarRenglon = find.widgetWithIcon(IconButton, Icons.add_rounded);
    await esperarPor(
      tester,
      agregarRenglon,
      descripcion: 'el botón de añadir el renglón a la compra',
    );
    await tester.tap(agregarRenglon.last);
    await _bombear(tester, 6);
    _recoger(tester, 'añadir renglón');

    _recoger(tester, 'diálogo de nueva compra');

    final registrar = find.text('Registrar Compra');
    await tester.ensureVisible(registrar.first);
    await _bombear(tester, 2);
    await tester.tap(registrar.first);
    await _bombear(tester, 12);
    _recoger(tester, 'registrar la compra');
    expect(
      find.text('Registrar Compra'),
      findsNothing,
      reason:
          'el diálogo de compra no se cerró: la compra fue rechazada. '
          'Pantalla: ${_pantalla(tester)}',
    );

    // Recibirla: aquí es donde el CHECK de `movimientos_stock_consumible`
    // devolvía 23514 en cada clic, en local y en producción.
    final recibir = find.text('Recibir');
    await esperarPor(
      tester,
      recibir,
      limite: const Duration(seconds: 45),
      descripcion: 'el botón Recibir de la compra recién creada',
    );
    await tester.ensureVisible(recibir.first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(recibir.first, warnIfMissed: false);
    _recoger(tester, 'abrir la recepción');
    await esperarPor(
      tester,
      find.text('Marcar como Recibida'),
      limite: const Duration(seconds: 45),
      descripcion: 'la pantalla de recepción de la compra',
    );
    await tester.tap(find.text('Marcar como Recibida'), warnIfMissed: false);
    _recoger(tester, 'confirmar la recepción');
    await esperarPor(
      tester,
      find.text(
        'Compra recibida correctamente e inventario/caja actualizados.',
      ),
      limite: const Duration(seconds: 60),
      descripcion:
          'la confirmación de la recepción (I1: antes respondía 23514 siempre)',
    );
    await _bombear(tester, 12);
    _recoger(tester, 'recepción de la compra');

    expect(
      [..._erroresDeUi.map((e) => e.exceptionAsString()), ..._excepciones],
      isEmpty,
      reason:
          'la interfaz lanzó excepciones durante la jornada del admin (caja y compras). '
          'Detalle: ${_erroresDeUi.map((e) => e.exceptionAsString()).join(" ||| ")} '
          '· por etapa: ${_excepciones.join(" ||| ")}',
    );
  });
}
