import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/seccion_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Solo sostiene un estado: la sección no dispara llamadas al backend en estos
/// escenarios.
class _CubitDoble extends Cubit<PlanTratamientoState>
    implements PlanTratamientoCubit {
  _CubitDoble(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Diente _diente({
  required int fdi,
  List<DiagnosticoAplicado> diagnosis = const [],
}) => Diente(
  id: 'diente-$fdi',
  odontogramaId: 'odo-1',
  superficies: const [],
  diagnosis: diagnosis,
  fdiCode: fdi,
);

DiagnosticoAplicado _hallazgo({
  String? id,
  required String nombre,
  TipoSuperficie? superficie,
}) => DiagnosticoAplicado(
  id: id,
  diagnosisId: 'diag-1',
  severidad: SeveridadDiagnosis.moderada,
  fechaAplicacion: DateTime(2026, 7, 25),
  notas: '',
  superficie: superficie,
  nombreDiagnostico: nombre,
);

ItemPlanTratamiento _item({
  String id = 'item-1',
  EstadoItemPlan estado = EstadoItemPlan.propuesto,
  double precio = 2500,
  String? diagnosticoAplicadoId,
  String nombre = 'Resina compuesta',
}) => ItemPlanTratamiento(
  id: id,
  planId: 'plan-1',
  tratamientoId: 'trat-1',
  diagnosticoAplicadoId: diagnosticoAplicadoId,
  dienteId: 'diente-36',
  superficie: TipoSuperficie.oclusal,
  estado: estado,
  precioEstimado: precio,
  fechaPropuesta: DateTime(2026, 7, 25),
  nombreTratamiento: nombre,
);

Widget _app(PlanTratamientoState estado, {List<Diente>? dientes}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(
        child: BlocProvider<PlanTratamientoCubit>(
          create: (_) => _CubitDoble(estado),
          child: SeccionPlanTratamiento(
            dientes: dientes ?? const [],
            pacienteId: 'pac-1',
            doctorId: 'doc-1',
            consultaId: 'consulta-1',
            onElegirTratamiento: () async => null,
            onEjecutarActividad: (_, _, _, _) async {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('sin hallazgos invita a anotarlos en el odontograma', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const PlanTratamientoCargado()));
    await tester.pump();

    expect(
      find.textContaining('La evaluación aún no registra hallazgos'),
      findsOneWidget,
    );
  });

  testWidgets('un hallazgo sin llevar al plan se ofrece, no se planifica solo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PlanTratamientoCargado(),
        dientes: [
          _diente(
            fdi: 36,
            diagnosis: [
              _hallazgo(
                id: 'h-1',
                nombre: 'Caries',
                superficie: TipoSuperficie.oclusal,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Hallazgos sin decidir'), findsOneWidget);
    expect(find.textContaining('Caries · 36 Oclusal'), findsOneWidget);
    expect(find.text('Llevar al plan'), findsOneWidget);
    // Registrar el hallazgo no creó ninguna actividad: esa es la regla del
    // ticket, y aquí se ve en pantalla.
    expect(
      find.textContaining('Ningún hallazgo se ha llevado al plan'),
      findsOneWidget,
    );
  });

  testWidgets('un hallazgo ya atendido deja de aparecer como pendiente', (
    tester,
  ) async {
    final plan = PlanTratamiento(
      id: 'plan-1',
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      estado: EstadoPlanTratamiento.propuesto,
      fechaPropuesta: DateTime(2026, 7, 25),
      items: [_item(diagnosticoAplicadoId: 'h-1')],
    );

    await tester.pumpWidget(
      _app(
        PlanTratamientoCargado(plan: plan),
        dientes: [
          _diente(
            fdi: 36,
            diagnosis: [_hallazgo(id: 'h-1', nombre: 'Caries')],
          ),
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Hallazgos sin decidir'), findsNothing);
    expect(find.text('Actividades del plan'), findsOneWidget);
  });

  testWidgets('cada actividad muestra su estado y su precio estimado', (
    tester,
  ) async {
    final plan = PlanTratamiento(
      id: 'plan-1',
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      estado: EstadoPlanTratamiento.propuesto,
      fechaPropuesta: DateTime(2026, 7, 25),
      items: [
        _item(id: 'a', precio: 2500),
        _item(
          id: 'b',
          estado: EstadoItemPlan.aceptado,
          precio: 3000,
          nombre: 'Extracción',
        ),
        _item(
          id: 'c',
          estado: EstadoItemPlan.rechazado,
          precio: 9000,
          nombre: 'Blanqueamiento',
        ),
      ],
    );

    await tester.pumpWidget(_app(PlanTratamientoCargado(plan: plan)));
    await tester.pump();

    expect(find.text('Propuesta'), findsOneWidget);
    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Rechazada'), findsOneWidget);

    // El estimado excluye lo rechazado; el aceptado solo cuenta lo decidido.
    expect(find.text('RD\$ 5,500.00'), findsOneWidget);
    expect(find.text('RD\$ 3,000.00'), findsWidgets);
  });

  testWidgets('el resumen advierte que el plan no factura', (tester) async {
    final plan = PlanTratamiento(
      id: 'plan-1',
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      fechaPropuesta: DateTime(2026, 7, 25),
      items: [_item()],
    );

    await tester.pumpWidget(_app(PlanTratamientoCargado(plan: plan)));
    await tester.pump();

    expect(
      find.textContaining('Nada se cobra hasta que la actividad se ejecuta'),
      findsOneWidget,
    );
  });

  testWidgets('una actividad terminal no ofrece cambios de estado', (
    tester,
  ) async {
    final plan = PlanTratamiento(
      id: 'plan-1',
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      fechaPropuesta: DateTime(2026, 7, 25),
      items: [_item(estado: EstadoItemPlan.completado)],
    );

    await tester.pumpWidget(_app(PlanTratamientoCargado(plan: plan)));
    await tester.pump();

    expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
  });
}
