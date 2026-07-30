import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/widgets/nueva_cita_dialog.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';

class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble() : super(const CitaCubitLoading());

  @override
  List<Cita> eventLoader(DateTime day) => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Devuelve siempre la misma persona: el diálogo tiene dos pasos y hay que
/// pasar el primero para llegar a la fecha y la hora.
class _PersonaRepoDoble extends Fake implements PersonaRepository {
  @override
  Future<List<Persona>> searchPersonas(String query) async => [
    Persona(
      id: 'p-1',
      nombre: 'Ana',
      apellido: 'Pérez',
      birthDate: DateTime(1990, 5, 12),
      govID: '001-1234567-8',
      contactos: const [],
      estatus: EstatusPersona.activo,
    ),
  ];
}

class _PacienteRepoDoble extends Fake implements IPacienteRepository {}

class _DoctorRepoDoble extends Fake implements DoctorRepository {
  @override
  Future<List<Doctor>> getDoctores() async => const [];
}

/// Pasa el primer paso del diálogo: buscar al paciente y elegirlo.
Future<void> _elegirPersona(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Ana');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ana Pérez').first);
  await tester.pumpAndSettle();
}

/// El paso 2 ofrece las actividades del plan (SD-146). Este paciente no tiene
/// ninguna: la prueba no va de eso.
class _CitaRepoDoble extends Fake implements CitaRepository {
  @override
  Future<List<ActividadPlanificada>> getActividadesAgendables(
    String pacienteId,
  ) async => const [];
}

void main() {
  testWidgets(
    'abrir la cita desde una casilla de la agenda trae su fecha y su hora',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<CitaCubit>(
            create: (_) => _CitaCubitDoble(),
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => NuevaCitaDialog.show(
                      context,
                      personaRepository: _PersonaRepoDoble(),
                      doctorRepository: _DoctorRepoDoble(),
                      pacienteRepository: _PacienteRepoDoble(),
                      citaRepository: _CitaRepoDoble(),
                      // La casilla del miércoles a las 9:00 de la agenda semanal.
                      fechaInicial: DateTime(2026, 8, 12, 9),
                    ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await _elegirPersona(tester);

      // La casilla tocada ya viene puesta: el doctor no vuelve a elegirla.
      expect(find.text('12/08/2026'), findsOneWidget);
      expect(find.text('Seleccionar fecha'), findsNothing);
      expect(find.text('Seleccionar hora'), findsNothing);
    },
  );

  testWidgets('sin casilla de origen el formulario abre vacío', (tester) async {
    tester.view.physicalSize = const Size(1280, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<CitaCubit>(
          create: (_) => _CitaCubitDoble(),
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => NuevaCitaDialog.show(
                    context,
                    personaRepository: _PersonaRepoDoble(),
                    doctorRepository: _DoctorRepoDoble(),
                    pacienteRepository: _PacienteRepoDoble(),
                    citaRepository: _CitaRepoDoble(),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await _elegirPersona(tester);

    expect(find.text('Seleccionar fecha'), findsOneWidget);
    expect(find.text('Seleccionar hora'), findsOneWidget);
  });
}
