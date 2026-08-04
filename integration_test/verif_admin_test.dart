// Verificación post-audit · jornada del admin-doctor por la interfaz real.
//
// Recorre lo que el audit del 2 ago 2026 dejó tocado y nadie había vuelto a
// pulsar: el expediente y su PDF (P1-P4), el cobro de la pre-factura
// (F2-02/F2-03), el arqueo de caja (F2-01/S10) y la compra recibida
// (I1/I2/I5/I6), que era literalmente imposible antes de la corrección.
//
// Depende de que la jornada de la doctora se haya corrido antes: cobra la
// cuenta que dejó la consulta de Sara.
//
// Requiere: stack local + seed de certificación + overlay de login + overlay
// `e2e_agenda_hoy_overlay.sql`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:printing/printing.dart';

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

Future<void> _bombear(WidgetTester tester, [int veces = 12]) async {
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

Future<void> _volver(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(Scaffold).first)).pop();
  await _bombear(tester, 8);
}

/// Vuelve al shell cerrando las rutas apiladas, sin contar `pop`s.
///
/// Contar era frágil: la exportación del expediente apila un diálogo y una
/// previsualización, y un `pop` de más o de menos deja la jornada dentro de
/// una ruta donde la navegación lateral no existe —el fallo aparecía como
/// «el destino Caja no está en la navegación», que apunta a otro sitio.
Future<void> _volverAlShell(WidgetTester tester, {int maximo = 6}) async {
  for (var i = 0; i < maximo; i++) {
    if (find.text('Cuentas por Cobrar').evaluate().isNotEmpty) return;
    final navegador = Navigator.of(tester.element(find.byType(Scaffold).first));
    if (!navegador.canPop()) return;
    navegador.pop();
    await _bombear(tester, 8);
  }
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

  testWidgets('jornada del admin: expediente, cobro, caja y compras', (
    tester,
  ) async {
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
    // 1 · Expediente de Sara: lo que dejó la consulta de la doctora
    // ===================================================================
    await abrirDestino(tester, 'Pacientes');
    await _escribirHint(tester, 'Buscar por nombre o cédula...', 'Sara');
    await esperarPor(
      tester,
      find.text('Sara Sanabria'),
      limite: const Duration(seconds: 45),
      descripcion: 'Sara en el listado de pacientes',
    );
    await tester.tap(find.byTooltip('Ver expediente').first);
    await esperarPor(
      tester,
      find.text('Expediente Clínico'),
      limite: const Duration(seconds: 45),
      descripcion: 'el expediente de Sara',
    );

    final motivoSara = find.text('VERIF Sara: revisión y caries 16');
    await esperarPor(
      tester,
      motivoSara,
      limite: const Duration(seconds: 45),
      descripcion: 'la consulta cerrada de Sara en su historial',
    );
    await tester.ensureVisible(motivoSara.first);
    await _bombear(tester, 4);
    expect(
      find.text('1 diagnóstico(s)'),
      findsWidgets,
      reason: 'el diagnóstico de la consulta no llegó al historial',
    );
    expect(
      find.text('1 tratamiento(s)'),
      findsWidgets,
      reason: 'el tratamiento de la consulta no llegó al historial',
    );
    expect(
      find.text('1 receta(s)'),
      findsWidgets,
      reason: 'la receta de la consulta no llegó al historial',
    );

    // ===================================================================
    // 2 · El PDF del expediente se genera y se pinta
    // ===================================================================
    final exportar = find.byKey(const Key('exportar_expediente_button'));
    await esperarPor(tester, exportar, descripcion: 'exportar expediente');
    await tester.tap(exportar);
    await _asentar(tester);
    expect(
      find.text('Expediente con odontograma'),
      findsOneWidget,
      reason: 'el diálogo de exportación perdió la opción con odontograma',
    );
    await tester.tap(find.byKey(const Key('generar_expediente_pdf')));
    await esperarPor(
      tester,
      find.byType(PdfPreview),
      limite: const Duration(seconds: 90),
      descripcion: 'la vista previa del PDF con odontograma',
    );
    await _bombear(tester, 20);
    _recoger(tester, 'PDF del expediente');
    // Cierra la previsualización y el diálogo de exportación; el expediente
    // sigue debajo, que es donde vive el resumen financiero.
    await _volver(tester);
    if (find.text('Expediente con odontograma').evaluate().isNotEmpty) {
      await _volver(tester);
    }

    // ===================================================================
    // 3 · Cobro real de la cuenta que dejó la consulta
    // ===================================================================
    // La ruta al cobro es el resumen financiero de la ficha: Cuentas por
    // Cobrar sigue sin ofrecer detalle (observación abierta del audit).
    await esperarPor(
      tester,
      find.text('Historial de cuentas'),
      limite: const Duration(seconds: 45),
      descripcion: 'el resumen financiero del paciente',
    );
    // El importe se pinta dos veces —en la tarjeta «Total facturado» y en la
    // fila de la cuenta— y sólo la fila navega. Se ancla al modo de pago, que
    // únicamente aparece dentro de la fila.
    await esperarPor(
      tester,
      find.text('RD\$3,200.00'),
      limite: const Duration(seconds: 45),
      descripcion:
          'el importe de RD\$3,200 en el resumen financiero (el tratamiento '
          'aplicado debe haberse facturado)',
    );
    final filaCuenta = find.ancestor(
      of: find.text('Contado'),
      matching: find.byType(InkWell),
    );
    await esperarPor(
      tester,
      filaCuenta,
      limite: const Duration(seconds: 30),
      descripcion: 'la fila de la cuenta en el historial',
    );
    await tester.ensureVisible(filaCuenta.first);
    await _bombear(tester, 2);
    await tester.tap(filaCuenta.first);
    // La cuenta puede venir ya saldada de una corrida anterior: entonces se
    // comprueba el estado y se sigue, en vez de intentar cobrar dos veces.
    final fin = DateTime.now().add(const Duration(seconds: 45));
    var cobrable = false;
    while (DateTime.now().isBefore(fin)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.text('Registrar Cobro / Pago').evaluate().isNotEmpty) {
        cobrable = true;
        break;
      }
      if (find.text('Cuenta Saldada Completamente').evaluate().isNotEmpty) {
        break;
      }
    }
    if (!cobrable) {
      expect(
        find.text('Cuenta Saldada Completamente'),
        findsWidgets,
        reason: 'la pre-factura no ofrece cobrar ni se declara saldada. '
            'Pantalla: ${_pantalla(tester)}',
      );
      await _volverAlShell(tester);
    } else {

      await tester.tap(find.text('Registrar Cobro / Pago'));
      await esperarPor(
        tester,
        find.text('Registrar Pago'),
        descripcion: 'el diálogo de cobro',
      );
      // Método de pago explícito: que el elegido se guarde es la corrección
      // F2-03 (antes toda pre-factura nacía «contado»).
      final chipTarjeta = find.text('Tarjeta de Débito');
      if (chipTarjeta.evaluate().isNotEmpty) {
        await tester.tap(chipTarjeta.first, warnIfMissed: false);
        await _bombear(tester, 3);
      }
      final cobrar = find.textContaining('Cobrar RD\$');
      expect(
        cobrar,
        findsWidgets,
        reason: 'el diálogo de cobro no ofrece el botón. Pantalla: '
            '${_pantalla(tester)}',
      );
      await tester.tap(cobrar.first, warnIfMissed: false);
      await esperarPor(
        tester,
        find.text('Cuenta Saldada Completamente'),
        limite: const Duration(seconds: 60),
        descripcion: 'la cuenta saldada tras el cobro',
      );
      await _volverAlShell(tester);
    }

    _recoger(tester, 'cobro de la pre-factura');

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
    if (cobrable) {
      // El cobro se hizo en esta corrida: su ingreso tiene que estar en el
      // arqueo (S10/F2-04 · el pago sigue a la caja).
      expect(
        find.textContaining('3,200'),
        findsWidgets,
        reason:
            'el cobro de RD\$3,200 no aparece en el arqueo del día. '
            'Pantalla: ${_pantalla(tester)}',
      );
    }

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
    await _bombear(tester, 24);
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
          'la interfaz lanzó excepciones durante la jornada del admin. '
          'Detalle: ${_erroresDeUi.map((e) => e.exceptionAsString()).join(" ||| ")} '
          '· por etapa: ${_excepciones.join(" ||| ")}',
    );
  });
}
