import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/widgets/nueva_cita_dialog.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';

class _CitaCubitDoble extends Cubit<CitaCubitState> implements CitaCubit {
  _CitaCubitDoble() : super(const CitaCubitLoading());

  Cita? citaCreada;

  @override
  Future<void> createCita(Cita cita) async => citaCreada = cita;

  @override
  List<Cita> eventLoader(DateTime day) => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PersonaRepoDoble extends Fake implements PersonaRepository {
  @override
  Future<List<Persona>> searchPersonas(String query) async => const [];
}

class _PacienteRepoDoble extends Fake implements IPacienteRepository {
  Paciente? registrado;

  @override
  Future<Either<Failure, String>> addPaciente(Paciente paciente) async {
    registrado = paciente;
    return const Right('11111111-1111-1111-1111-111111111111');
  }
}

class _DoctorRepoDoble extends Fake implements DoctorRepository {
  @override
  Future<List<Doctor>> getDoctores() async => [
    Doctor(
      id: '22222222-2222-2222-2222-222222222222',
      nombre: 'Carlos',
      apellido: 'Mendoza',
      birthDate: DateTime(1980, 1, 1),
      govID: '001-0000000-1',
      contactos: const <ContactoModel>[],
      estatus: EstatusPersona.activo,
      username: 'cmendoza',
      passwordHash: '',
      specialty: 'General',
      assistants: const [],
    ),
  ];
}

void main() {
  testWidgets(
    'el paciente nuevo de la agenda se registra como paciente y su id agenda la cita',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = _CitaCubitDoble();
      final pacienteRepo = _PacienteRepoDoble();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BlocProvider<CitaCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => NuevaCitaDialog.show(
                      context,
                      personaRepository: _PersonaRepoDoble(),
                      doctorRepository: _DoctorRepoDoble(),
                      pacienteRepository: pacienteRepo,
                      fechaInicial: DateTime.now().add(
                        const Duration(days: 3, hours: 2),
                      ),
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

      await tester.tap(find.text('Registrar Nuevo Paciente'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre *'), 'Maria');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Apellido *'),
        'Sanchez',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cédula *'),
        '40218382360',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Teléfono *'),
        '8297630729',
      );
      await tester.pumpAndSettle();

      // Fecha de nacimiento: el picker abre en la fecha por defecto y basta
      // aceptarla para que el formulario deje avanzar.
      await tester.ensureVisible(find.text('F. Nacimiento *'));
      await tester.tap(find.text('F. Nacimiento *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Emergencia').last);
      await tester.tap(find.text('Emergencia').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continuar a Agendar Cita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar a Agendar Cita'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<Doctor>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dr. Carlos Mendoza').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirmar Cita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar Cita'));
      // Sin `pumpAndSettle`: el botón queda con su spinner mientras el cubit
      // doble no emite el estado de éxito.
      await tester.pump(const Duration(milliseconds: 300));

      // Se registró una ficha de paciente completa, no una persona suelta.
      final registrado = pacienteRepo.registrado;
      expect(registrado, isNotNull);
      expect(registrado!.nombre, 'Maria');
      expect(registrado.tipoPaciente, TipoPaciente.emergencia);
      expect(registrado.genero, Genero.masculino);
      expect(registrado.contactos.single.numeroTelefono, '8297630729');

      // Y la cita apunta al id que devolvió ese registro.
      expect(
        cubit.citaCreada?.persona.id,
        '11111111-1111-1111-1111-111111111111',
      );
    },
  );
}
