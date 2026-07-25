import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_theme.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/planes_tratamiento_card.dart';

/// La tarjeta construye su cubit contra el repositorio del service locator, así
/// que el doble se inyecta ahí: se ejercita el cableado real, no un atajo.
class _RepoDoble implements PlanTratamientoRepository {
  final List<PlanTratamiento> planes;
  final List<ItemPlanTratamiento> pendientes;

  _RepoDoble({this.planes = const [], this.pendientes = const []});

  @override
  Future<List<PlanTratamiento>> getPlanesPaciente(String pacienteId) async =>
      planes;

  @override
  Future<List<ItemPlanTratamiento>> getItemsEjecutables(
    String pacienteId,
  ) async => pendientes;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ItemPlanTratamiento _item({
  required String id,
  required String nombre,
  required EstadoItemPlan estado,
  double precio = 2500,
}) => ItemPlanTratamiento(
  id: id,
  planId: 'plan-1',
  tratamientoId: 'trat-1',
  estado: estado,
  precioEstimado: precio,
  fechaPropuesta: DateTime(2026, 7, 25),
  nombreTratamiento: nombre,
);

Widget _app({
  List<PlanTratamiento> planes = const [],
  List<ItemPlanTratamiento> pendientes = const [],
}) {
  if (sl.isRegistered<PlanTratamientoRepository>()) {
    sl.unregister<PlanTratamientoRepository>();
  }
  sl.registerFactory<PlanTratamientoRepository>(
    () => _RepoDoble(planes: planes, pendientes: pendientes),
  );

  return MaterialApp(
    theme: AppTheme.light,
    home: const Scaffold(
      body: SingleChildScrollView(
        child: PlanesTratamientoCard(
          pacienteId: '11111111-2222-3333-4444-555555555555',
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('un paciente de prueba no muestra la tarjeta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: PlanesTratamientoCard(pacienteId: 'paciente-de-prueba'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Planes de tratamiento'), findsNothing);
  });

  testWidgets('sin planes lo dice en vez de dejar la tarjeta vacía', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('no tiene planes de tratamiento registrados'),
      findsOneWidget,
    );
  });

  testWidgets('lo aceptado y sin ejecutar encabeza la tarjeta con su total', (
    tester,
  ) async {
    final pendientes = [
      _item(
        id: 'a',
        nombre: 'Extracción',
        estado: EstadoItemPlan.aceptado,
        precio: 3000,
      ),
      _item(
        id: 'b',
        nombre: 'Endodoncia',
        estado: EstadoItemPlan.enProceso,
        precio: 7000,
      ),
    ];

    await tester.pumpWidget(
      _app(
        planes: [
          PlanTratamiento(
            id: 'plan-1',
            pacienteId: 'pac-1',
            doctorId: 'doc-1',
            estado: EstadoPlanTratamiento.aceptado,
            fechaPropuesta: DateTime(2026, 7, 20),
            items: pendientes,
          ),
        ],
        pendientes: pendientes,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aceptado y pendiente de ejecutar'), findsOneWidget);
    expect(find.text('RD\$ 10,000.00'), findsWidgets);
    expect(find.text('Plan del 20/7/2026'), findsOneWidget);
  });

  testWidgets('un plan sin nada aceptado no muestra bandeja de pendientes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        planes: [
          PlanTratamiento(
            id: 'plan-1',
            pacienteId: 'pac-1',
            doctorId: 'doc-1',
            estado: EstadoPlanTratamiento.propuesto,
            fechaPropuesta: DateTime(2026, 7, 25),
            items: [
              _item(
                id: 'a',
                nombre: 'Resina',
                estado: EstadoItemPlan.propuesto,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aceptado y pendiente de ejecutar'), findsNothing);
    expect(find.text('Propuesta'), findsOneWidget);
  });
}
