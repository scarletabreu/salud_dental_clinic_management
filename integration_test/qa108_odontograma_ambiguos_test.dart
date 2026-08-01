import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/main.dart' as app;
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/expediente_print_options.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/helpers/expediente_pdf_builder.dart';

import 'jornada_ui_test.dart' show abrirDestino, esperarPor, iniciarSesion;

const _consultas = [
  '10810000-0000-4000-8000-000000000201',
  '10810000-0000-4000-8000-000000000202',
  '10810000-0000-4000-8000-000000000203',
];
const _paciente71 = '10810000-0000-4000-8000-000000000103';

Future<void> _bombear(WidgetTester tester, [int veces = 12]) async {
  for (var i = 0; i < veces; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _abrirConsulta(WidgetTester tester, String paciente) async {
  final filaPaciente = find.byWidgetPredicate(
    (w) => w is Text && w.data == paciente,
  );
  await esperarPor(
    tester,
    filaPaciente,
    limite: const Duration(seconds: 20),
    descripcion: 'la consulta de $paciente',
  );
  final tarjeta = find
      .ancestor(of: filaPaciente, matching: find.byType(InkWell))
      .first;
  final continuar = find.descendant(
    of: tarjeta,
    matching: find.text('Continuar'),
  );
  expect(continuar, findsOneWidget);
  await tester.tap(continuar);
  await esperarPor(
    tester,
    find.text('Consulta en curso'),
    descripcion: 'el workspace de $paciente',
  );
  await esperarPor(
    tester,
    find.text('ODONTODIAGRAMA'),
    descripcion: 'el odontodiagrama de $paciente',
  );
}

Future<void> _volverAlListado(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pump(const Duration(milliseconds: 500));
  await esperarPor(tester, find.text('Consultas'), descripcion: 'Consultas');
  await _bombear(tester, 4);
}

Future<void> _elegirDiagnostico(WidgetTester tester) async {
  await tester.tap(find.text('Diagnóstico'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(ListTile), matching: find.text('Cariada')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Asignar diagnóstico'));
  await tester.pumpAndSettle();
}

Future<void> _registrarCaries(WidgetTester tester, int fdi) async {
  final pieza = find.byKey(ValueKey('pieza_$fdi'));
  await tester.ensureVisible(pieza);
  await tester.tap(pieza);
  await tester.pumpAndSettle();

  // Reproduce la omisión histórica: diagnóstico puntual sin escoger cara.
  await _elegirDiagnostico(tester);
  expect(
    find.textContaining('Selecciona la superficie en la pieza $fdi'),
    findsOneWidget,
    reason: 'la UI debe impedir una nueva caries puntual sin superficie',
  );

  // Ahora se completa la circunstancia correctamente desde la misma ficha.
  final mapa = find.byKey(const ValueKey('mapa_superficies'));
  await tester.tapAt(tester.getCenter(mapa));
  await tester.pumpAndSettle();
  await _elegirDiagnostico(tester);
  // El badge de guardado queda fuera del viewport al bajar hasta algunas
  // piezas. Se deja completar el debounce y la confirmación definitiva se
  // hace contra Supabase al final del recorrido.
  await _bombear(tester, 24);
}

Future<void> _registrarEmpaste(WidgetTester tester) async {
  await tester.tap(find.text('Tratamiento'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Empaste de resina'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('los cinco casos ambiguos se registran o bloquean por la web', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    app.main();
    await tester.pump(const Duration(seconds: 1));

    await iniciarSesion(tester, 'cert_admin');
    await abrirDestino(tester, 'Consultas');

    await _abrirConsulta(tester, 'Caso QA108 Caries pieza 36');
    await _registrarCaries(tester, 36);
    await _volverAlListado(tester);

    await _abrirConsulta(tester, 'Caso QA108 Caries pieza 15');
    await _registrarCaries(tester, 15);
    await _volverAlListado(tester);

    await _abrirConsulta(tester, 'Caso QA108 Pieza 71 y empastes');
    await _registrarCaries(tester, 71);

    // Los dos empastes equivalentes se crean desde la pieza 71. Aunque haya
    // una cara seleccionada, su alcance es `diente`: la superficie se omite,
    // pero el diente nunca puede perderse.
    await _registrarEmpaste(tester);
    await _registrarEmpaste(tester);
    await _bombear(tester, 24);

    final db = Supabase.instance.client;
    final diagnosticos = await db
        .from('diagnosticos_aplicados')
        .select(
          'consulta_id, superficie, '
          'diente:dientes!diagnosticos_aplicados_diente_id_fkey(fdi_code)',
        )
        .inFilter('consulta_id', _consultas)
        .isFilter('deleted_at', null);
    expect(diagnosticos, hasLength(3));
    expect(
      {
        for (final fila in diagnosticos as List)
          ((fila as Map)['diente'] as Map)['fdi_code'] as int,
      },
      {15, 36, 71},
    );
    expect(
      diagnosticos.every((fila) => (fila as Map)['superficie'] != null),
      isTrue,
    );

    final tratamientos = await db
        .from('tratamientos_aplicados')
        .select(
          'consulta_id, diente_id, superficie, '
          'diente:dientes!tratamientos_aplicados_diente_id_fkey(fdi_code)',
        )
        .eq('consulta_id', _consultas.last)
        .isFilter('deleted_at', null);
    expect(tratamientos, hasLength(2));
    expect(
      tratamientos.every(
        (fila) =>
            (fila as Map)['diente_id'] != null &&
            fila['superficie'] == null &&
            (fila['diente'] as Map)['fdi_code'] == 71,
      ),
      isTrue,
    );

    // Reabre el mismo dato por la ruta que alimenta el expediente y genera el
    // PDF real. Así la prueba no termina en la tabla: cubre lectura, modelo y
    // render consolidado con los dos empastes de pieza completa.
    final historial = await sl<ConsultaRepository>().getHistorialPaciente(
      _paciente71,
    );
    expect(historial.single.odontograma!.dientes, isNotEmpty);
    final pieza71 = historial.single.odontograma!.dientes.singleWhere(
      (diente) => diente.fdiCode == 71,
    );
    expect(pieza71.diagnosis, hasLength(1));
    expect(pieza71.tratamientos, hasLength(2));

    late Paciente paciente;
    final resultadoPaciente = await sl<IPacienteRepository>().getPacienteById(
      _paciente71,
    );
    resultadoPaciente.fold(
      (fallo) => fail('no se pudo cargar el paciente sintético: $fallo'),
      (cargado) => paciente = cargado,
    );
    paciente = paciente.copyWith(
      record: paciente.record.copyWith(consultas: historial),
    );
    final odontogramas = historial
        .map((consulta) => consulta.odontograma)
        .whereType<Odontograma>()
        .toList();
    final pdf = await ExpedientePdfBuilder.buildPdf(
      paciente: paciente,
      options: const ExpedientePrintOptions(incluirOdontograma: true),
      odontograma: odontogramas.first,
      historialOdontogramas: odontogramas,
      compress: false,
    );
    expect(pdf.length, greaterThan(1000));
  });
}
