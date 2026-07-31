import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/pages/inicio_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

class _DashboardCubitDoble extends Cubit<DashboardState>
    implements DashboardCubit {
  _DashboardCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Doctor _doctor() => Doctor(
  id: 'doc-1',
  nombre: 'Bartolomé',
  apellido: 'Santana Villalona',
  birthDate: DateTime(1985, 3, 2),
  govID: '402-1234567-1',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'bsantana',
  specialty: 'Endodoncia',
  assistants: const [],
);

Paciente _paciente() => Paciente(
  id: 'pac-1',
  nombre: 'Ana Mercedes',
  apellido: 'Rodríguez Montás',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: [
    Contacto(
      numeroTelefono: '809-555-0134',
      email: 'ana@correo.com.do',
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
    pacienteId: 'pac-1',
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

DashboardLoaded _estado(List<RolUsuario> roles) => DashboardLoaded(
  roles: roles,
  nombreDoctor: 'Bartolomé Santana Villalona',
  citasHoy: 12,
  citasPendientes: 5,
  citasEnEspera: 3,
  citasCompletadas: 4,
  totalPacientes: 348,
  totalMedicinas: 76,
  citasDeHoy: [
    Cita(
      id: 'cita-1',
      doctor: _doctor(),
      persona: _paciente(),
      date: DateTime(2026, 7, 22, 9, 30),
      esEmergencia: true,
      estado: EstadoCita.enEspera,
    ),
  ],
);

Widget _app(DashboardState estado, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, inner) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: inner!,
  ),
  home: Scaffold(
    body: BlocProvider<DashboardCubit>(
      create: (_) => _DashboardCubitDoble(estado),
      child: const InicioPage(),
    ),
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
  for (final rol in [RolUsuario.admin, RolUsuario.doctor]) {
    _viewports.forEach((nombre, tamano) {
      testWidgets('el inicio de ${rol.name} se lee en $nombre', (tester) async {
        _viewport(tester, tamano);
        await tester.pumpWidget(_app(_estado([rol])));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'el inicio no debe desbordar en $nombre',
        );
      });
    });
  }

  testWidgets('el inicio resiste el texto ampliado en 320 px', (tester) async {
    _viewport(tester, const Size(320, 2000));
    await tester.pumpWidget(_app(_estado([RolUsuario.admin]), textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
