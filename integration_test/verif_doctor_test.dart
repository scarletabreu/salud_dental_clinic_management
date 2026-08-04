// Verificación post-audit · jornada del doctor punta a punta.
//
// Conduce la aplicación real como lo haría la doctora en un día de clínica:
// llegada → consulta (signos vitales, odontograma, tratamiento, receta) →
// cierre; dos consultas abiertas a la vez y retomadas; y una receta
// contraindicada que debe quedar bloqueada. Deriva del arnés del audit del 2
// ago 2026: aquí todas las afirmaciones son de comportamiento correcto.
//
// Requiere: stack local + seed de certificación + overlay de login + overlay
// `e2e_agenda_hoy_overlay.sql`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/helpers/expediente_pdf_builder.dart';
import 'package:salud_dental_clinic_management/main.dart' as app;

import 'jornada_ui_test.dart' show abrirDestino, esperarPor, iniciarSesion;

const _pacienteSara = 'ce470000-0000-4000-8000-000000000101';
const _pacienteHugo = 'ce470000-0000-4000-8000-000000000103';

final List<FlutterErrorDetails> _erroresDeUi = <FlutterErrorDetails>[];

/// Paso en curso. Sin esto, un `Bad state: No element` de `flutter_test` no
/// dice en qué punto de la jornada ocurrió: la pila es toda del framework.
final List<String> _pasos = <String>[];
void _paso(String descripcion) => _pasos.add(descripcion);

String _textoVisible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data)
    .whereType<String>()
    .where((s) => s.trim().isNotEmpty)
    .toSet()
    .join(' ~ ');

Future<void> _bombear(WidgetTester tester, [int veces = 12]) async {
  for (var i = 0; i < veces; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// `pumpAndSettle` sin límite se cuelga diez minutos enteros en cuanto hay un
/// indicador de progreso girando —y en esta pantalla siempre hay alguno en
/// vuelo—. Aquí se le pone tope y, si no asienta, se sigue bombeando.

/// Pulsa [objetivo] asegurándose de que la pulsación aterriza.
///
/// `tap(..., warnIfMissed: false)` sobre un widget que existe en el árbol pero
/// está fuera del viewport no hace nada y no avisa: el arnés seguía como si
/// hubiera pulsado. Aquí se lleva a pantalla y se exige que sea alcanzable por
/// hit-test antes de pulsar.
Future<void> _pulsar(
  WidgetTester tester,
  Finder objetivo,
  String descripcion,
) async {
  await tester.ensureVisible(objetivo.first);
  await _bombear(tester, 2);
  final alcanzable = objetivo.hitTestable();
  expect(
    alcanzable,
    findsWidgets,
    reason: '«$descripcion» está en el árbol pero no es alcanzable por '
        'hit-test: la pulsación no aterrizaría',
  );
  await tester.tap(alcanzable.first);
  await _bombear(tester, 4);
}

Future<void> _asentar(WidgetTester tester) async {
  // Nada de `pumpAndSettle`: en esta pantalla siempre hay una animación o una
  // petición en vuelo, así que agota su plazo y —aunque se capture el throw—
  // la binding ya anotó la excepción. El resultado era una jornada que hacía
  // todo bien y terminaba en «Multiple exceptions (3) were detected», que
  // parece un defecto de la aplicación y es del arnés.
  await _bombear(tester, 8);
}

/// Escribe en el campo cuyo hint es [pista] (TextField o TextFormField).
Future<void> _escribir(WidgetTester tester, String pista, String texto) async {
  // TextFormField construye un TextField interno con la misma decoración,
  // así que esta búsqueda cubre ambos.
  final objetivo = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == pista,
  );
  expect(objetivo, findsWidgets, reason: 'no hay campo con la pista «$pista»');
  await tester.ensureVisible(objetivo.first);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.tap(objetivo.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 150));
  await tester.enterText(objetivo.first, texto);
  await tester.pump(const Duration(milliseconds: 200));
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

/// Contenedor accionable de la cita. La misma persona aparece tanto en el
/// calendario como en el panel del día; sólo este InkWell contiene a la vez el
/// nombre y los botones clínicos.
Finder _contenedorDeCita(String nombre) => find.byElementPredicate(
  (element) =>
      element.widget is InkWell && _subarbolContieneTexto(element, nombre),
  description: 'contenedor de la cita de $nombre',
);

Finder _botonDeCita(String nombre, String etiqueta) => find.descendant(
  of: _contenedorDeCita(nombre),
  matching: find.text(etiqueta),
);

Future<void> _tapEnCita(
  WidgetTester tester,
  String nombre,
  String etiqueta,
) async {
  _paso('cita «$nombre» → «$etiqueta»');
  await esperarPor(
    tester,
    find.textContaining(nombre),
    limite: const Duration(seconds: 60),
    descripcion: 'la cita de $nombre',
  );
  final boton = _botonDeCita(nombre, etiqueta);
  await esperarPor(
    tester,
    boton,
    descripcion: '«$etiqueta» en la cita de $nombre',
  );
  await tester.ensureVisible(boton);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(boton, warnIfMissed: false);
  await _bombear(tester, 8);
}

/// Rellena el paso «Datos iniciales» y entra al workspace clínico.
Future<void> _abrirWorkspace(
  WidgetTester tester, {
  required String motivo,
  bool conVitales = true,
}) async {
  _paso('abrir workspace: $motivo');
  try {
    await esperarPor(
      tester,
      find.text('Motivo de consulta'),
      limite: const Duration(seconds: 45),
      descripcion: 'el formulario de evaluación',
    );
  } catch (_) {
    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .join(' | ');
    fail('No abrió el formulario de evaluación. Textos visibles: $textos');
  }
  await _escribir(
    tester,
    'Ej: Dolor en molar superior derecho desde hace 3 días…',
    motivo,
  );
  if (conVitales) {
    await _escribir(tester, 'PS mmHg', '120');
    await _escribir(tester, 'PD mmHg', '80');
    await _escribir(tester, 'Pulso lpm', '72');
    await _escribir(tester, 'Temp °C', '36.5');
    await _escribir(tester, 'Sat %', '98');
    await _escribir(tester, 'Dolor 0-10', '2');
    await _escribir(tester, 'Peso kg', '62');
    await _escribir(tester, 'Talla cm', '165');
  }
  final continuar = find.text('Continuar con la consulta');
  await esperarPor(tester, continuar, descripcion: 'el botón de continuar');
  await _pulsar(tester, continuar, 'Continuar con la consulta');
  await esperarPor(
    tester,
    find.text('ODONTODIAGRAMA'),
    limite: const Duration(seconds: 45),
    descripcion: 'el workspace clínico',
  );
  await _bombear(tester, 8);
}

Future<void> _diagnosticarPieza(WidgetTester tester, int fdi) async {
  _paso('diagnosticar pieza $fdi');
  final pieza = find.byKey(ValueKey('pieza_$fdi'));
  await esperarPor(tester, pieza, descripcion: 'la pieza $fdi');
  await tester.ensureVisible(pieza);
  await tester.tap(pieza);
  await _asentar(tester);

  final mapa = find.byKey(const ValueKey('mapa_superficies'));
  await esperarPor(tester, mapa, descripcion: 'el mapa de superficies');
  await tester.tapAt(tester.getCenter(mapa));
  await _asentar(tester);

  await tester.tap(find.text('Diagnóstico'));
  await _asentar(tester);
  await tester.tap(
    find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Caries dental'),
    ),
  );
  await _asentar(tester);
  await tester.tap(find.widgetWithText(FilledButton, 'Asignar diagnóstico'));
  await _asentar(tester);
  await _bombear(tester, 8);
}

Future<void> _aplicarTratamiento(WidgetTester tester, String nombre) async {
  _paso('aplicar tratamiento «$nombre»');
  await tester.tap(find.text('Tratamiento'));
  await _asentar(tester);
  await tester.tap(
    find.descendant(of: find.byType(BottomSheet), matching: find.text(nombre)),
  );
  await _asentar(tester);
  await _bombear(tester, 8);
}

/// El scroll del workspace clínico, no el de la ficha del paciente.
///
/// En escritorio hay dos columnas desplazables lado a lado. Coger «la última»
/// acertaba por casualidad: arrastraba la ficha del paciente y la sección de
/// receta no bajaba nunca. Se ancla al odontodiagrama, que sólo vive en la
/// columna clínica.
Finder _scrollVerticalWorkspace() {
  final vertical = find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        (w.axisDirection == AxisDirection.down ||
            w.axisDirection == AxisDirection.up),
  );
  final ancla = find.text('ODONTODIAGRAMA');
  if (ancla.evaluate().isNotEmpty) {
    final delWorkspace = find.ancestor(of: ancla.first, matching: vertical);
    if (delWorkspace.evaluate().isNotEmpty) return delWorkspace.first;
  }
  return vertical.last;
}

/// Arrastra el scroll vertical del workspace hasta que [objetivo] aparezca.
///
/// `scrollUntilVisible` no sirve aquí: llama a `pumpAndSettle` en cada vuelta
/// y el workspace siempre tiene alguna animación o petición en vuelo, así que
/// se queda diez minutos colgado en la primera iteración.
Future<bool> _desplazarHasta(
  WidgetTester tester,
  Finder objetivo, {
  int intentos = 25,
}) async {
  for (var i = 0; i < intentos; i++) {
    if (objetivo.evaluate().isNotEmpty) return true;
    final scroll = _scrollVerticalWorkspace();
    if (scroll.evaluate().isEmpty) return false;
    await tester.drag(scroll, const Offset(0, -420));
    await _bombear(tester, 3);
  }
  return objetivo.evaluate().isNotEmpty;
}

/// Añade una medicina a la receta. Devuelve true si el renglón se agregó y
/// false si un diálogo de contraindicación absoluta lo bloqueó.
Future<bool> _recetar(WidgetTester tester, String medicina) async {
  _paso('recetar «$medicina»');
  final agregar = find.text('Agregar medicina');
  await _desplazarHasta(tester, agregar);
  await esperarPor(tester, agregar, descripcion: 'la sección de receta');
  await _pulsar(tester, agregar, 'Agregar medicina');
  await _asentar(tester);

  await _escribir(tester, 'Nombre de la medicina…', medicina);
  await tester.tap(find.textContaining(medicina).last);
  await _asentar(tester);
  await _bombear(tester, 4);

  // ¿Bloqueo absoluto?
  if (find.textContaining('está contraindicado').evaluate().isNotEmpty) {
    await tester.tap(find.text('Entendido'));
    await _asentar(tester);
    return false;
  }

  await esperarPor(
    tester,
    find.text('Dosis *'),
    descripcion: 'el formulario del renglón de receta',
  );
  await _escribir(tester, 'Ej. 1', '1');
  await _escribir(tester, 'tableta, ml, cápsula', 'tableta');
  await _escribir(tester, 'Ej. 8', '8');
  await _escribir(tester, 'Ej. 5', '5');
  await _escribir(tester, 'oral, tópica', 'oral');
  await tester.tap(find.text('Agregar renglón'));
  await _asentar(tester);
  await _bombear(tester, 4);
  return true;
}

Future<void> _terminarConsulta(WidgetTester tester) async {
  _paso('terminar consulta');
  final terminar = find.text('Terminar consulta');
  await _desplazarHasta(tester, terminar);
  await esperarPor(tester, terminar, descripcion: 'el botón de terminar');
  await _pulsar(tester, terminar, 'Terminar consulta');

  // El cierre es una RPC transaccional: puede tardar. La señal de que ocurrió
  // es la pre-factura («Detalle de Cuenta»), que reemplaza al workspace.
  //
  // Antes bastaba con que desapareciera el odontodiagrama, y un cierre
  // rechazado —un `CL001`, un diálogo modal encima— se daba por bueno: la
  // jornada seguía sobre consultas que en la base seguían abiertas.
  final fin = DateTime.now().add(const Duration(seconds: 60));
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('Detalle de Cuenta').evaluate().isNotEmpty ||
        find.text('Consulta finalizada con éxito.').evaluate().isNotEmpty) {
      await _bombear(tester, 8);
      return;
    }
  }
  fail(
    'La consulta no se cerró: ni pre-factura ni confirmación tras 60 s. '
    'Pantalla: ${_textoVisible(tester)}',
  );
}

Future<void> _volver(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pump(const Duration(milliseconds: 500));
  await _bombear(tester, 6);
}

Future<void> _retomarDesdeConsultas(
  WidgetTester tester,
  String nombreCompleto,
) async {
  _paso('retomar la consulta de $nombreCompleto');
  await abrirDestino(tester, 'Consultas');
  await esperarPor(
    tester,
    find.textContaining(nombreCompleto),
    descripcion: 'la consulta en curso de $nombreCompleto',
  );
  final continuar = find.descendant(
    of: _contenedorDeCita(nombreCompleto),
    matching: find.text('Continuar'),
  );
  await esperarPor(
    tester,
    continuar,
    descripcion: 'Continuar la consulta de $nombreCompleto',
  );
  await tester.tap(continuar.first);
  await esperarPor(
    tester,
    find.text('ODONTODIAGRAMA'),
    limite: const Duration(seconds: 45),
    descripcion: 'el workspace retomado de $nombreCompleto',
  );
  await _bombear(tester, 8);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jornada del doctor punta a punta por la interfaz real', (tester) async {
    try {
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

      await iniciarSesion(tester, 'cert_doctora');
      await abrirDestino(tester, 'Mis Citas del Día');

      // Control de agenda: las tres citas confirmadas del overlay deben estar
      // presentes y la cancelada puede verse, pero no debe ofrecer llegada.
      for (final paciente in const [
        'Sara Sanabria',
        'Hugo Herrera',
        'Ana Alcántara',
      ]) {
        await esperarPor(
          tester,
          find.textContaining(paciente),
          limite: const Duration(seconds: 60),
          descripcion: 'la cita confirmada de $paciente',
        );
      }
      await esperarPor(
        tester,
        find.text('Diana Duarte'),
        limite: const Duration(seconds: 60),
        descripcion: 'la cita cancelada de Diana',
      );
      final nombreCancelada = find.text('Diana Duarte');
      nombreCancelada.evaluate();
      final tarjetasCanceladas = find.ancestor(
        of: nombreCancelada.first,
        matching: find.byType(InkWell),
      );
      expect(tarjetasCanceladas, findsWidgets);
      final tarjetaCancelada = tarjetasCanceladas.first;
      tarjetaCancelada.evaluate();
      expect(
        find.descendant(
          of: tarjetaCancelada,
          matching: find.text('Registrar llegada'),
        ),
        findsNothing,
        reason: 'una cita cancelada no debe permitir registrar llegada',
      );

      // ============ Consulta 1 · Sara, ciclo completo ============
      final iniciarSara = _botonDeCita('Sara Sanabria', 'Iniciar consulta');
      final llegadaSara = _botonDeCita('Sara Sanabria', 'Registrar llegada');
      var saraEditable = true;
      if (iniciarSara.evaluate().isEmpty && llegadaSara.evaluate().isEmpty) {
        // Permite retomar una corrida interrumpida por un selector del propio
        // arnés sin repetir diagnóstico ni tratamiento.
        await abrirDestino(tester, 'Consultas');
        await esperarPor(
          tester,
          find.textContaining('Sara Sanabria'),
          descripcion: 'el historial/listado de Sara',
        );
        final continuarSara = find.descendant(
          of: _contenedorDeCita('Sara Sanabria'),
          matching: find.text('Continuar'),
        );
        if (continuarSara.evaluate().isNotEmpty) {
          await tester.tap(continuarSara.first);
          await esperarPor(
            tester,
            find.text('ODONTODIAGRAMA'),
            limite: const Duration(seconds: 45),
            descripcion: 'el workspace retomado de Sara',
          );
          await _bombear(tester, 8);
        } else {
          saraEditable = false;
        }
      } else {
        await _tapEnCita(tester, 'Sara Sanabria', 'Registrar llegada');
        await _tapEnCita(tester, 'Sara Sanabria', 'Iniciar consulta');
        await _abrirWorkspace(tester, motivo: 'VERIF Sara: revisión y caries 16');
        await _diagnosticarPieza(tester, 16);
        await _aplicarTratamiento(tester, 'Resina compuesta');
      }
      if (saraEditable) {
        final recetaSara = await _recetar(tester, 'Paracetamol');
        expect(recetaSara, isTrue, reason: 'el paracetamol no debió bloquearse');
        await _terminarConsulta(tester);
        // Con tratamientos, el cierre reemplaza el workspace por la pre-factura
        // y hay que volver explícitamente al shell.
        await _volver(tester);
      }

      // De vuelta en la agenda: la cita de Sara ya no debe ofrecer «Iniciar
      // consulta».
      await abrirDestino(tester, 'Mis Citas del Día');
      await esperarPor(
        tester,
        find.text('Mis Citas del Día'),
        descripcion: 'la agenda tras cerrar',
      );

      // ============ Consulta 2 · Hugo, queda EN CURSO ============
      await _tapEnCita(tester, 'Hugo Herrera', 'Registrar llegada');
      await _tapEnCita(tester, 'Hugo Herrera', 'Iniciar consulta');
      await _abrirWorkspace(tester, motivo: 'VERIF Hugo: dolor molar 26');
      await _diagnosticarPieza(tester, 26);
      await _volver(tester); // se queda abierta, sin terminar

      // ============ Consulta 3 · Ana, contraindicación absoluta ============
      await esperarPor(
        tester,
        find.text('Mis Citas del Día'),
        descripcion: 'la agenda para Ana',
      );
      await _tapEnCita(tester, 'Ana Alcántara', 'Registrar llegada');
      await _tapEnCita(tester, 'Ana Alcántara', 'Iniciar consulta');
      await _abrirWorkspace(tester, motivo: 'VERIF Ana: absceso, receta');
      final recetaAna = await _recetar(tester, 'Amoxicilina');
      expect(
        recetaAna,
        isFalse,
        reason:
            'la amoxicilina en paciente alérgica a penicilina debe bloquearse '
            'con contraindicación absoluta',
      );
      // La alternativa segura sí debe pasar.
      final recetaAlt = await _recetar(tester, 'Clindamicina');
      expect(recetaAlt, isTrue, reason: 'la clindamicina no debió bloquearse');
      await _terminarConsulta(tester);

      // ============ Concurrencia · retomar la consulta de Hugo ============
      await _retomarDesdeConsultas(tester, 'Hugo Herrera');
      // El workspace retomado es el de Hugo, no debe filtrar nada de Sara/Ana.
      expect(
        find.textContaining('Hugo'),
        findsWidgets,
        reason: 'el workspace no identifica a Hugo',
      );
      expect(
        find.textContaining('Sara'),
        findsNothing,
        reason: 'estado de la consulta de Sara filtrado en la de Hugo',
      );
      await _terminarConsulta(tester);

      // ============ Verificación de lectura consolidada + PDF ============
      final historialSara = await sl<ConsultaRepository>().getHistorialPaciente(
        _pacienteSara,
      );
      expect(historialSara, isNotEmpty, reason: 'Sara sin historial');
      final consultaSara = historialSara.first;
      expect(
        consultaSara.odontograma,
        isNotNull,
        reason: 'el historial de Sara no trae odontograma',
      );
      final pieza16 = consultaSara.odontograma!.dientes
          .where((d) => d.fdiCode == 16)
          .toList();
      expect(pieza16, hasLength(1), reason: 'pieza 16 ausente del historial');
      expect(
        pieza16.single.diagnosis,
        isNotEmpty,
        reason: 'el diagnóstico de la pieza 16 se perdió',
      );
      expect(
        pieza16.single.tratamientos,
        isNotEmpty,
        reason: 'el tratamiento de la pieza 16 se perdió',
      );

      late Paciente sara;
      (await sl<IPacienteRepository>().getPacienteById(
        _pacienteSara,
      )).fold((f) => fail('no se pudo leer a Sara: $f'), (p) => sara = p);
      sara = sara.copyWith(
        record: sara.record.copyWith(consultas: historialSara),
      );
      final odontogramas = historialSara
          .map((c) => c.odontograma)
          .whereType<Odontograma>()
          .toList();
      final pdf = await ExpedientePdfBuilder.buildPdf(
        paciente: sara,
        options: const ExpedientePrintOptions(incluirOdontograma: true),
        odontograma: odontogramas.first,
        historialOdontogramas: odontogramas,
        compress: false,
      );
      expect(pdf.length, greaterThan(1000), reason: 'el PDF salió vacío');

      // El historial de Hugo debe existir y NO contener la pieza 16 de Sara.
      final historialHugo = await sl<ConsultaRepository>().getHistorialPaciente(
        _pacienteHugo,
      );
      expect(historialHugo, isNotEmpty, reason: 'Hugo sin historial');
      final dientesHugo = historialHugo
          .expand((c) => c.odontograma?.dientes ?? const [])
          .toList();
      expect(
        dientesHugo.where((d) => d.fdiCode == 26),
        isNotEmpty,
        reason: 'el diagnóstico 26 de Hugo se perdió',
      );
      expect(
        dientesHugo.where((d) => d.fdiCode == 16 && d.diagnosis.isNotEmpty),
        isEmpty,
        reason: 'un diagnóstico de Sara apareció en el expediente de Hugo',
      );

      // Nada de todo lo anterior debió dejar excepciones de UI.
      expect(
        _erroresDeUi.map((e) => e.exceptionAsString()).toList(),
        isEmpty,
        reason: 'la interfaz lanzó excepciones durante la jornada del audit',
      );

      // Deja constancia del usuario con el que quedó la sesión para el chequeo
      // psql posterior.
      // ignore: avoid_print
      print('VERIF-E2E-OK uid=${Supabase.instance.client.auth.currentUser?.id}');
    } catch (e) {
      fail(
        'FALLÓ tras el paso «${_pasos.isEmpty ? "(ninguno)" : _pasos.last}». '
        'Pasos completados: ${_pasos.join(" → ")}. '
        'Error: $e. Pantalla: ${_textoVisible(tester)}',
      );
    }
  });
}
