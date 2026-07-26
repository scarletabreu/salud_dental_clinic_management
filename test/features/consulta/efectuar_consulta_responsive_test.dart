import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/efectuar_consulta_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/panel_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

const _pacienteId = '11111111-1111-1111-1111-111111111111';
const _doctorId = '22222222-2222-2222-2222-222222222222';

class _PacienteCubitDoble extends Cubit<PacienteState>
    implements PacienteCubit {
  _PacienteCubitDoble(super.initialState);

  @override
  Future<void> loadParaConsulta(String id) async {}

  /// La página consulta esto en `initState` para decidir si pide el registro
  /// completo; el doble responde que el paciente ya está registrado.
  @override
  Future<bool> isPaciente(String id) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ConsultaCubitDoble extends Cubit<ConsultaState>
    implements ConsultaCubit {
  _ConsultaCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Paciente _paciente() => Paciente(
  id: _pacienteId,
  nombre: 'Ana Mercedes',
  apellido: 'Rodríguez Montás',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'ana.rodriguez@correo.com.do',
      direccion: 'Santo Domingo',
    ),
  ],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: 'Docente',
  referencia: '—',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: _pacienteId,
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const ['Extracción de terceros molares'],
    historialFamiliar: 'Diabetes tipo 2 por línea materna',
  ),
);

Widget _app({double textScale = 1}) {
  if (sl.isRegistered<PacienteCubit>()) sl.unregister<PacienteCubit>();
  if (sl.isRegistered<ConsultaCubit>()) sl.unregister<ConsultaCubit>();
  sl.registerFactory<PacienteCubit>(
    () => _PacienteCubitDoble(PacienteDetailLoaded(_paciente())),
  );
  sl.registerFactory<ConsultaCubit>(
    () => _ConsultaCubitDoble(const ConsultaInactiva()),
  );

  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, inner) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: inner!,
    ),
    home: EfectuarConsultaPage(
      citaId: 'cita-1',
      pacienteId: _pacienteId,
      doctorId: _doctorId,
    ),
  );
}

void _viewport(WidgetTester tester, Size tamano) {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

final _viewports = <String, Size>{
  '320 px': const Size(320, 900),
  '360 px': const Size(360, 900),
  '390 px': const Size(390, 900),
  'tablet': const Size(768, 1024),
  'escritorio': const Size(1280, 900),
};

void main() {
  tearDown(() {
    if (sl.isRegistered<PacienteCubit>()) sl.unregister<PacienteCubit>();
    if (sl.isRegistered<ConsultaCubit>()) sl.unregister<ConsultaCubit>();
  });

  _viewports.forEach((nombre, tamano) {
    testWidgets('la consulta clínica se puede efectuar en $nombre', (
      tester,
    ) async {
      _viewport(tester, tamano);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.text('Consulta clínica'), findsWidgets);
      expect(
        tester.takeException(),
        isNull,
        reason: 'la consulta no debe desbordar en $nombre',
      );
    });
  });

  testWidgets('la pantalla inicial presenta un único flujo clínico', (
    tester,
  ) async {
    _viewport(tester, const Size(390, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Consulta clínica'), findsWidgets);
    expect(find.text('Motivo de consulta'), findsOneWidget);
    expect(find.text('Evaluar y planificar'), findsNothing);
  });

  testWidgets('en escritorio la ficha del paciente va anclada al workspace', (
    tester,
  ) async {
    _viewport(tester, const Size(1280, 900));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byType(PanelPaciente), findsOneWidget);
    expect(find.byKey(const ValueKey('abrir-panel-paciente')), findsNothing);
  });

  for (final tamano in [
    const Size(320, 900),
    const Size(390, 900),
    const Size(768, 1024),
  ]) {
    testWidgets(
      'en ${tamano.width.toInt()} px la ficha se abre desde la cabecera',
      (tester) async {
        _viewport(tester, tamano);
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        // El workspace se queda con todo el ancho...
        expect(find.byType(PanelPaciente), findsNothing);

        // ...y la ficha sigue siendo alcanzable sin perder información.
        final boton = find.byKey(const ValueKey('abrir-panel-paciente'));
        expect(boton, findsOneWidget);
        await tester.tap(boton);
        await tester.pumpAndSettle();

        expect(find.byType(PanelPaciente), findsOneWidget);
        expect(find.text('Ana Mercedes Rodríguez Montás'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('la consulta resiste el texto ampliado en 320 px', (
    tester,
  ) async {
    _viewport(tester, const Size(320, 1200));
    await tester.pumpWidget(_app(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
