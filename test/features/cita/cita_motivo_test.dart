import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/cita/data/models/cita_model.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/formulario_evaluacion.dart';

class _ConsultaCubitDoble extends Cubit<ConsultaState>
    implements ConsultaCubit {
  _ConsultaCubitDoble() : super(const ConsultaInactiva());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Map<String, dynamic> _citaJson({String? motivo}) => {
  'id': '33333333-3333-3333-3333-333333333333',
  'fecha_hora': '2026-08-12T13:00:00Z',
  'duracion_minutos': 30,
  'es_emergencia': false,
  'estado': 'programada',
  'motivo': motivo,
  'doctor': {
    'id': '22222222-2222-2222-2222-222222222222',
    'nombre': 'Carlos',
    'apellido': 'Mendoza',
    'fecha_nacimiento': '1980-01-01',
    'cedula': '001-0000000-1',
    'estatus': 'activo',
    'username': 'cmendoza',
    'password_hash': '',
    'especialidad': 'General',
    'esta_disponible': true,
    'assistants': <dynamic>[],
    'contacto': {'email': '', 'numero_telefono': '', 'direccion': ''},
  },
  'persona': {
    'id': '11111111-1111-1111-1111-111111111111',
    'nombre': 'Maria',
    'apellido': 'Sanchez',
    'fecha_nacimiento': '1995-03-04',
    'cedula': '402-1838236-0',
    'estatus': 'activo',
  },
};

void main() {
  test('el motivo de la cita sobrevive el viaje a la base y de vuelta', () {
    final cita = CitaModel.fromJson(
      _citaJson(motivo: '  Dolor en molar superior  '),
    );

    expect(cita.motivo, 'Dolor en molar superior');
    expect(cita.toJson()['motivo'], 'Dolor en molar superior');
  });

  test('un motivo en blanco se guarda como ausente, no como cadena vacía', () {
    expect(CitaModel.fromJson(_citaJson(motivo: '   ')).motivo, isNull);
    expect(CitaModel.fromJson(_citaJson()).motivo, isNull);
    expect(
      CitaModel.fromJson(_citaJson(motivo: '  ')).toJson()['motivo'],
      isNull,
    );
  });

  testWidgets('la evaluación abre con el motivo que traía la cita', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<ConsultaCubit>(
          create: (_) => _ConsultaCubitDoble(),
          child: const Scaffold(
            body: FormularioEvaluacion(
              pacienteId: '11111111-1111-1111-1111-111111111111',
              doctorId: '22222222-2222-2222-2222-222222222222',
              citaId: '33333333-3333-3333-3333-333333333333',
              motivoCita: 'Dolor en molar superior',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dolor en molar superior'), findsOneWidget);
  });
}
