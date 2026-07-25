import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

ItemPlanTratamiento _item({
  String id = 'item-1',
  EstadoItemPlan estado = EstadoItemPlan.propuesto,
  double precio = 1000,
  String? diagnosticoAplicadoId,
}) {
  return ItemPlanTratamiento(
    id: id,
    planId: 'plan-1',
    tratamientoId: 'trat-1',
    diagnosticoAplicadoId: diagnosticoAplicadoId,
    dienteId: 'diente-1',
    superficie: TipoSuperficie.oclusal,
    estado: estado,
    precioEstimado: precio,
    fechaPropuesta: DateTime(2026, 7, 25),
  );
}

void main() {
  group('ItemPlanTratamiento.transicionarA', () {
    test('sella la fecha de la decisión que se toma', () {
      final momento = DateTime(2026, 7, 25, 10, 30);

      final aceptado = _item().transicionarA(
        EstadoItemPlan.aceptado,
        momento: momento,
      );
      expect(aceptado, isNotNull);
      expect(aceptado!.estado, EstadoItemPlan.aceptado);
      expect(aceptado.fechaAceptacion, momento);
      expect(aceptado.fechaRechazo, isNull);

      final enProceso = aceptado.transicionarA(
        EstadoItemPlan.enProceso,
        momento: momento,
      )!;
      expect(enProceso.fechaInicio, momento);

      final completado = enProceso.transicionarA(
        EstadoItemPlan.completado,
        momento: momento,
      )!;
      expect(completado.fechaCompletado, momento);
      // La auditoría anterior no se pisa al avanzar.
      expect(completado.fechaAceptacion, momento);
    });

    test('un rechazo guarda su motivo y su fecha', () {
      final momento = DateTime(2026, 7, 25, 11);
      final rechazado = _item().transicionarA(
        EstadoItemPlan.rechazado,
        momento: momento,
        motivoRechazo: 'El paciente prefiere esperar.',
      )!;

      expect(rechazado.estado, EstadoItemPlan.rechazado);
      expect(rechazado.fechaRechazo, momento);
      expect(rechazado.motivoRechazo, 'El paciente prefiere esperar.');
    });

    test('devuelve null en una transición ilegal, sin mutar nada', () {
      final propuesto = _item();
      expect(propuesto.transicionarA(EstadoItemPlan.completado), isNull);
      expect(propuesto.estado, EstadoItemPlan.propuesto);

      final rechazado = _item(estado: EstadoItemPlan.rechazado);
      expect(rechazado.transicionarA(EstadoItemPlan.aceptado), isNull);
    });
  });

  group('PlanTratamiento · totales', () {
    PlanTratamiento planCon(List<ItemPlanTratamiento> items) => PlanTratamiento(
      id: 'plan-1',
      pacienteId: 'pac-1',
      doctorId: 'doc-1',
      estado: EstadoPlanTratamiento.propuesto,
      fechaPropuesta: DateTime(2026, 7, 25),
      items: items,
    );

    test('el estimado ignora lo rechazado y lo cancelado', () {
      final plan = planCon([
        _item(id: 'a', precio: 1000),
        _item(id: 'b', estado: EstadoItemPlan.aceptado, precio: 2000),
        _item(id: 'c', estado: EstadoItemPlan.rechazado, precio: 5000),
        _item(id: 'd', estado: EstadoItemPlan.cancelado, precio: 9000),
      ]);

      expect(plan.totalEstimado, 3000);
    });

    test('el aceptado solo cuenta lo que ya se decidió hacer', () {
      final plan = planCon([
        _item(id: 'a', precio: 1000), // propuesto: aún no se decide
        _item(id: 'b', estado: EstadoItemPlan.aceptado, precio: 2000),
        _item(id: 'c', estado: EstadoItemPlan.enProceso, precio: 500),
      ]);

      expect(plan.totalAceptado, 2500);
    });

    test('pendientesDeDecision son las propuestas sin respuesta', () {
      final plan = planCon([
        _item(id: 'a'),
        _item(id: 'b', estado: EstadoItemPlan.aceptado),
      ]);

      expect(plan.pendientesDeDecision.map((i) => i.id), ['a']);
    });

    test('el total estimado no es un cargo: un plan no factura', () {
      // Regla central de SD-135. El presupuesto vive en el plan; el importe
      // cobrable sale de `tratamientos_aplicados.precio_aplicado` al ejecutar.
      final plan = planCon([_item(precio: 7500)]);
      expect(plan.totalEstimado, 7500);
      expect(plan.totalAceptado, 0);
    });
  });

  group('PlanTratamiento.transicionarA', () {
    test('aceptar sella la fecha; rechazar sella fecha y motivo', () {
      final momento = DateTime(2026, 7, 26);
      final plan = PlanTratamiento(
        id: 'plan-1',
        pacienteId: 'pac-1',
        doctorId: 'doc-1',
        estado: EstadoPlanTratamiento.propuesto,
        fechaPropuesta: DateTime(2026, 7, 25),
      );

      final aceptado = plan.transicionarA(
        EstadoPlanTratamiento.aceptado,
        momento: momento,
      )!;
      expect(aceptado.fechaAceptacion, momento);

      final rechazado = plan.transicionarA(
        EstadoPlanTratamiento.rechazado,
        momento: momento,
        motivoRechazo: 'Sin cobertura.',
      )!;
      expect(rechazado.fechaRechazo, momento);
      expect(rechazado.motivoRechazo, 'Sin cobertura.');
    });

    test('un borrador no se puede aceptar sin proponerlo antes', () {
      final plan = PlanTratamiento(
        pacienteId: 'pac-1',
        doctorId: 'doc-1',
        fechaPropuesta: DateTime(2026, 7, 25),
      );
      expect(plan.estado, EstadoPlanTratamiento.borrador);
      expect(plan.transicionarA(EstadoPlanTratamiento.aceptado), isNull);
    });
  });
}
