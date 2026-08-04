import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/efectuar_consulta_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

const _pacienteId = '11111111-1111-1111-1111-111111111111';
const _doctorId = '22222222-2222-2222-2222-222222222222';

class _PacienteCubitDoble extends Cubit<PacienteState>
    implements PacienteCubit {
  _PacienteCubitDoble(super.initialState);

  @override
  Future<void> loadParaConsulta(String id) async {}

  @override
  Future<bool> isPaciente(String id) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ConsultaCubitDoble extends Cubit<ConsultaState>
    implements ConsultaCubit {
  _ConsultaCubitDoble(super.initialState);

  /// Deja que la prueba mueva el estado como lo haría el cubit real.
  void publicar(ConsultaState estado) => emit(estado);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PlanCubitDoble extends Cubit<PlanTratamientoState>
    implements PlanTratamientoCubit {
  _PlanCubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Paciente _paciente() => Paciente(
  id: _pacienteId,
  nombre: 'Ana',
  apellido: 'Rodríguez',
  birthDate: DateTime(1990, 5, 12),
  govID: '001-1234567-8',
  contactos: const [],
  estatus: EstatusPersona.activo,
  genero: Genero.femenino,
  trabajo: '',
  referencia: '',
  citas: const [],
  tipoPaciente: TipoPaciente.integrado,
  record: Record(
    pacienteId: _pacienteId,
    tipoSangre: TipoSangre.oPositivo,
    condiciones: const [],
    cirugiasPrevias: const [],
    historialFamiliar: '',
  ),
);

late _ConsultaCubitDoble consultaCubit;

Widget _app() {
  consultaCubit = _ConsultaCubitDoble(const ConsultaInactiva());

  sl.registerFactory<PacienteCubit>(
    () => _PacienteCubitDoble(PacienteDetailLoaded(_paciente())),
  );
  sl.registerFactory<ConsultaCubit>(() => consultaCubit);
  sl.registerFactory<PlanTratamientoCubit>(
    () => _PlanCubitDoble(const PlanTratamientoInitial()),
  );

  return MaterialApp(
    theme: AppTheme.light,
    home: const EfectuarConsultaPage(
      citaId: 'cita-1',
      pacienteId: _pacienteId,
      doctorId: _doctorId,
    ),
  );
}

void main() {
  tearDown(() {
    if (sl.isRegistered<PacienteCubit>()) sl.unregister<PacienteCubit>();
    if (sl.isRegistered<ConsultaCubit>()) sl.unregister<ConsultaCubit>();
    if (sl.isRegistered<PlanTratamientoCubit>()) {
      sl.unregister<PlanTratamientoCubit>();
    }
  });

  testWidgets('un fallo clínico se queda en pantalla y no se va con el tiempo', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    consultaCubit.publicar(
      const ConsultaError('No se pudo registrar la consulta.'),
    );
    // Dos frames: el listener corre en el primero y su setState repinta en el
    // siguiente.
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('banner-fallo-consulta')), findsOneWidget);
    expect(find.text('No se pudo registrar la consulta.'), findsOneWidget);

    // Lo que hacía el snackbar: desaparecer solo a los pocos segundos, con el
    // doctor creyendo que la consulta se guardó.
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const ValueKey('banner-fallo-consulta')), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('banner-fallo-consulta')), findsNothing);
  });

  testWidgets('una consulta cerrada en el servidor deja de ofrecer edición', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    consultaCubit.publicar(
      const ConsultaCerradaEnServidor(
        mensaje: 'Esta consulta ya fue finalizada y no admite cambios.',
        consultaId: 'c-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('panel-consulta-cerrada')),
      findsOneWidget,
    );
    expect(find.text('Esta consulta ya está finalizada'), findsOneWidget);
    expect(find.text('Motivo de consulta'), findsNothing);
  });
}
