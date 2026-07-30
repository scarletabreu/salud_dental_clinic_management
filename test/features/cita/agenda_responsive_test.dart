import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble(super.initialState);

  @override
  Future<void> load({
    String? restringidoADoctorId,
    List<String>? doctorIdsPermitidos,
  }) async {}

  @override
  List<Cita> eventLoader(DateTime day) {
    final actual = state;
    return actual is CitaCubitLoaded ? actual.citasForDay(day) : const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// La agenda lee el rol desde `AuthCubit` (roles y usuario). El cubit real se
/// suscribe al stream de Supabase Auth al construirse, así que aquí se sustituye
/// por un doble con el estado ya puesto.
class _AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  _AuthCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _hoy = DateTime(2026, 7, 22);

Doctor _doctor() => Doctor(
  id: '22222222-2222-2222-2222-222222222222',
  nombre: 'Bartolomé',
  apellido: 'Santana Villalona',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  passwordHash: 'x',
  specialty: 'Endodoncia',
  assistants: const [],
);

Paciente _paciente(String nombre, String apellido) => Paciente(
  id: '11111111-1111-1111-1111-111111111111',
  nombre: nombre,
  apellido: apellido,
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'paciente@correo.com.do',
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
    pacienteId: '11111111-1111-1111-1111-111111111111',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

CitaCubitLoaded _estado(CalendarioViewMode modo) => CitaCubitLoaded(
  citas: [
    Cita(
      id: 'cita-1',
      doctor: _doctor(),
      persona: _paciente('Ana Mercedes', 'Rodríguez Montás'),
      date: DateTime(2026, 7, 22, 9, 30),
      duracionMinutos: 45,
      esEmergencia: false,
      estado: EstadoCita.confirmada,
    ),
    Cita(
      id: 'cita-2',
      doctor: _doctor(),
      persona: _paciente('Juan Carlos', 'De la Cruz Peralta'),
      date: DateTime(2026, 7, 22, 11, 0),
      duracionMinutos: 30,
      esEmergencia: true,
      estado: EstadoCita.enEspera,
    ),
  ],
  focusedDay: _hoy,
  selectedDay: _hoy,
  viewMode: modo,
);

Widget _app(CitaCubitState estado, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: MultiBlocProvider(
    providers: [
      BlocProvider<CitaCubit>(create: (_) => _CitaCubitDoble(estado)),
      BlocProvider<AuthCubit>(
        create: (_) => _AuthCubitDoble(
          AuthState(isAuthenticated: true, usuario: _doctor()),
        ),
      ),
    ],
    child: const MisCitasDelDiaPage(),
  ),
);

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
  for (final modo in CalendarioViewMode.values) {
    _viewports.forEach((nombre, tamano) {
      testWidgets('la agenda ${modo.name} se muestra en $nombre', (
        tester,
      ) async {
        _viewport(tester, tamano);
        await tester.pumpWidget(_app(_estado(modo)));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'la agenda ${modo.name} no debe desbordar en $nombre',
        );
      });
    });
  }

  testWidgets('la agenda resiste el texto ampliado en 320 px', (tester) async {
    _viewport(tester, const Size(320, 1400));
    await tester.pumpWidget(
      _app(_estado(CalendarioViewMode.diaria), textScale: 2),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
