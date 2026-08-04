import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/consentimiento_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/errors/transicion_plan_invalida.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/resumen_actividad_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';

/// Repositorio en memoria: aplica las mismas reglas de transición del dominio,
/// que es justo lo que el cubit debe respetar.
class _RepoFake implements PlanTratamientoRepository {
  PlanTratamiento? plan;
  int contadorIds = 0;
  final List<String> llamadas = [];

  /// HFX-CLIN-003: la decisión del paciente se registra con su evidencia, y el
  /// servidor es quien la aplica al plan.
  @override
  Future<ConsentimientoPlan> registrarConsentimiento({
    required String planId,
    required bool aceptado,
    required String persona,
    required MetodoConsentimiento metodo,
    String relacion = 'titular',
    String? motivoRechazo,
  }) async {
    llamadas.add('registrarConsentimiento');
    final actual = plan;
    plan = actual?.copyWith(
      estado: aceptado
          ? EstadoPlanTratamiento.aceptado
          : EstadoPlanTratamiento.rechazado,
      motivoRechazo: motivoRechazo,
    );
    return ConsentimientoPlan(
      planId: planId,
      versionPlan: actual?.version ?? 1,
      aceptado: aceptado,
      totalAceptado: actual?.totalEstimado ?? 0,
      personaAcepta: persona,
      relacionConPaciente: relacion,
      metodo: metodo,
      motivoRechazo: motivoRechazo,
    );
  }

  @override
  Future<PlanTratamiento> crearPlan(PlanTratamiento nuevo) async {
    llamadas.add('crearPlan');
    plan = nuevo.copyWith(
      id: 'plan-1',
      items: [
        for (final item in nuevo.items)
          item.copyWith(id: 'item-${++contadorIds}', planId: 'plan-1'),
      ],
    );
    return plan!;
  }

  @override
  Future<List<ItemPlanTratamiento>> agregarItems(
    String planId,
    List<ItemPlanTratamiento> items,
  ) async {
    llamadas.add('agregarItems');
    return [
      for (final item in items)
        item.copyWith(id: 'item-${++contadorIds}', planId: planId),
    ];
  }

  @override
  Future<ItemPlanTratamiento> cambiarEstadoItem(
    ItemPlanTratamiento item,
    EstadoItemPlan destino, {
    String? motivoRechazo,
  }) async {
    final actualizado = item.transicionarA(
      destino,
      motivoRechazo: motivoRechazo,
    );
    if (actualizado == null) {
      throw TransicionPlanInvalida(
        origen: item.estado.etiqueta,
        destino: destino.etiqueta,
      );
    }
    return actualizado;
  }

  @override
  Future<PlanTratamiento> cambiarEstadoPlan(
    PlanTratamiento plan,
    EstadoPlanTratamiento destino, {
    String? motivoRechazo,
  }) async {
    final actualizado = plan.transicionarA(
      destino,
      motivoRechazo: motivoRechazo,
    );
    if (actualizado == null) {
      throw TransicionPlanInvalida(
        origen: plan.estado.etiqueta,
        destino: destino.etiqueta,
        sujeto: 'el plan',
      );
    }
    return actualizado;
  }

  // Lecturas de resumen y registro de ejecución: el cubit de este test no las
  // usa, pero la interfaz las exige desde SD-135/SD-144. Se dejan explícitas
  // en vez de heredar de un Fake, para que una llamada inesperada falle a la
  // vista en lugar de devolver null en silencio.
  @override
  Future<List<ResumenActividadPlan>> getResumenPorPlan(String planId) async {
    llamadas.add('getResumenPorPlan');
    return const [];
  }

  @override
  Future<List<ResumenActividadPlan>> getResumenPorPaciente(
    String pacienteId,
  ) async {
    llamadas.add('getResumenPorPaciente');
    return const [];
  }


  @override
  Future<void> eliminarItem(String id) async => llamadas.add('eliminarItem');

  @override
  Future<PlanTratamiento?> getPlanDeConsulta(String consultaId) async => plan;

  @override
  Future<List<PlanTratamiento>> getPlanesPaciente(String pacienteId) async =>
      plan == null ? const [] : [plan!];

  @override
  Future<List<ItemPlanTratamiento>> getItemsEjecutables(
    String pacienteId,
  ) async => plan?.items.where((i) => i.estado.admiteEjecucion).toList() ?? [];
}

ItemPlanTratamiento _actividad({String? id}) => ItemPlanTratamiento(
  id: id,
  planId: '',
  tratamientoId: 'trat-1',
  dienteId: 'diente-1',
  precioEstimado: 1500,
  fechaPropuesta: DateTime(2026, 7, 25),
);

void main() {
  late _RepoFake repo;
  late PlanTratamientoCubit cubit;

  setUp(() {
    repo = _RepoFake();
    cubit = PlanTratamientoCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  test('una consulta sin plan carga vacía aunque tenga hallazgos', () async {
    // La evaluación puede haber registrado veinte hallazgos: ninguno crea plan.
    await cubit.cargarDeConsulta('consulta-1');

    final estado = cubit.state;
    expect(estado, isA<PlanTratamientoCargado>());
    expect((estado as PlanTratamientoCargado).plan, isNull);
  });

  test('proponer actividades crea el plan en estado propuesto', () async {
    await cubit.cargarDeConsulta('consulta-1');
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      evaluacionId: 'eval-1',
      actividades: [_actividad()],
    );

    final plan = (cubit.state as PlanTratamientoCargado).plan!;
    expect(plan.estado, EstadoPlanTratamiento.propuesto);
    expect(plan.evaluacionId, 'eval-1');
    expect(plan.items.single.id, 'item-1');
    // Nace propuesta: nadie la aceptó todavía, así que no admite ejecución.
    expect(plan.items.single.estado, EstadoItemPlan.propuesto);
    expect(plan.items.single.estado.admiteEjecucion, isFalse);
  });

  test('proponer sobre un plan existente agrega sin recrearlo', () async {
    await cubit.cargarDeConsulta('consulta-1');
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      actividades: [_actividad()],
    );
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      actividades: [_actividad()],
    );

    expect(repo.llamadas, ['crearPlan', 'agregarItems']);
    expect((cubit.state as PlanTratamientoCargado).plan!.items, hasLength(2));
  });

  test('proponer una lista vacía no toca el repositorio', () async {
    await cubit.cargarDeConsulta('consulta-1');
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      actividades: const [],
    );

    expect(repo.llamadas, isEmpty);
  });

  test('aceptar una actividad la deja ejecutable y sella la fecha', () async {
    await cubit.cargarDeConsulta('consulta-1');
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      actividades: [_actividad()],
    );

    final propuesta = (cubit.state as PlanTratamientoCargado).plan!.items.single;
    await cubit.cambiarEstadoActividad(propuesta, EstadoItemPlan.aceptado);

    final aceptada = (cubit.state as PlanTratamientoCargado).plan!.items.single;
    expect(aceptada.estado, EstadoItemPlan.aceptado);
    expect(aceptada.fechaAceptacion, isNotNull);
    expect(aceptada.estado.admiteEjecucion, isTrue);
  });

  test('una transición ilegal deja aviso y conserva el plan intacto', () async {
    await cubit.cargarDeConsulta('consulta-1');
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      actividades: [_actividad()],
    );

    final propuesta = (cubit.state as PlanTratamientoCargado).plan!.items.single;
    await cubit.cambiarEstadoActividad(propuesta, EstadoItemPlan.completado);

    final estado = cubit.state as PlanTratamientoCargado;
    expect(estado.aviso, contains('No se puede pasar'));
    expect(estado.guardando, isFalse);
    expect(estado.plan!.items.single.estado, EstadoItemPlan.propuesto);

    cubit.limpiarAviso();
    expect((cubit.state as PlanTratamientoCargado).aviso, isNull);
  });

  test('rechazar guarda el motivo y cierra la actividad', () async {
    await cubit.cargarDeConsulta('consulta-1');
    await cubit.proponerActividades(
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      consultaId: 'consulta-1',
      actividades: [_actividad()],
    );

    final propuesta = (cubit.state as PlanTratamientoCargado).plan!.items.single;
    await cubit.cambiarEstadoActividad(
      propuesta,
      EstadoItemPlan.rechazado,
      motivoRechazo: 'El paciente no lo quiere ahora.',
    );

    final rechazada = (cubit.state as PlanTratamientoCargado).plan!.items.single;
    expect(rechazada.estado, EstadoItemPlan.rechazado);
    expect(rechazada.motivoRechazo, 'El paciente no lo quiere ahora.');
    expect(rechazada.estado.esTerminal, isTrue);
    // Rechazada nunca puede llegar a facturar.
    expect(rechazada.estado.admiteEjecucion, isFalse);
  });
}
