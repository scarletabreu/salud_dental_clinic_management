import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';

void main() {
  group('EstadoItemPlan · ciclo de vida de la actividad planificada (SD-135)', () {
    test('el ticket exige los siete estados', () {
      expect(EstadoItemPlan.values, const [
        EstadoItemPlan.propuesto,
        EstadoItemPlan.aceptado,
        EstadoItemPlan.rechazado,
        EstadoItemPlan.pendiente,
        EstadoItemPlan.enProceso,
        EstadoItemPlan.completado,
        EstadoItemPlan.cancelado,
      ]);
    });

    test('grafo de transiciones', () {
      expect(EstadoItemPlan.propuesto.transicionesPermitidas, const [
        EstadoItemPlan.aceptado,
        EstadoItemPlan.rechazado,
        EstadoItemPlan.cancelado,
      ]);
      expect(EstadoItemPlan.aceptado.transicionesPermitidas, const [
        EstadoItemPlan.pendiente,
        EstadoItemPlan.enProceso,
        EstadoItemPlan.cancelado,
      ]);
      expect(EstadoItemPlan.pendiente.transicionesPermitidas, const [
        EstadoItemPlan.enProceso,
        EstadoItemPlan.cancelado,
      ]);
      expect(EstadoItemPlan.enProceso.transicionesPermitidas, const [
        EstadoItemPlan.completado,
        EstadoItemPlan.cancelado,
      ]);
    });

    test('rechazado, completado y cancelado son terminales', () {
      expect(EstadoItemPlan.rechazado.esTerminal, isTrue);
      expect(EstadoItemPlan.completado.esTerminal, isTrue);
      expect(EstadoItemPlan.cancelado.esTerminal, isTrue);
    });

    test('no se puede completar lo que nunca se empezó ni revivir lo rechazado', () {
      expect(
        EstadoItemPlan.propuesto.puedeTransicionarA(EstadoItemPlan.completado),
        isFalse,
      );
      expect(
        EstadoItemPlan.rechazado.puedeTransicionarA(EstadoItemPlan.aceptado),
        isFalse,
      );
    });

    test('solo una actividad ya decidida admite registro de ejecución', () {
      // Es el mismo contrato que impone el trigger trg_item_plan_ejecutable.
      expect(EstadoItemPlan.propuesto.admiteEjecucion, isFalse);
      expect(EstadoItemPlan.rechazado.admiteEjecucion, isFalse);
      expect(EstadoItemPlan.cancelado.admiteEjecucion, isFalse);

      expect(EstadoItemPlan.aceptado.admiteEjecucion, isTrue);
      expect(EstadoItemPlan.pendiente.admiteEjecucion, isTrue);
      expect(EstadoItemPlan.enProceso.admiteEjecucion, isTrue);
      expect(EstadoItemPlan.completado.admiteEjecucion, isTrue);
    });

    test('dbValue y fromDb coinciden con el enum de Postgres', () {
      for (final estado in EstadoItemPlan.values) {
        expect(EstadoItemPlan.fromDb(estado.dbValue), estado);
      }
      expect(EstadoItemPlan.enProceso.dbValue, 'en_proceso');
      // Puente con SD-150: una indicación era una actividad sin decidir.
      expect(EstadoItemPlan.fromDb('indicado'), EstadoItemPlan.propuesto);
    });
  });

  group('EstadoPlanTratamiento', () {
    test('un borrador solo puede proponerse o cancelarse', () {
      expect(
        EstadoPlanTratamiento.borrador.transicionesPermitidas,
        const [
          EstadoPlanTratamiento.propuesto,
          EstadoPlanTratamiento.cancelado,
        ],
      );
    });

    test('un plan propuesto se acepta, se rechaza o se cancela', () {
      expect(
        EstadoPlanTratamiento.propuesto.transicionesPermitidas,
        const [
          EstadoPlanTratamiento.aceptado,
          EstadoPlanTratamiento.rechazado,
          EstadoPlanTratamiento.cancelado,
        ],
      );
    });

    test('rechazado, completado y cancelado son terminales', () {
      expect(EstadoPlanTratamiento.rechazado.esTerminal, isTrue);
      expect(EstadoPlanTratamiento.completado.esTerminal, isTrue);
      expect(EstadoPlanTratamiento.cancelado.esTerminal, isTrue);
    });

    test('dbValue y fromDb coinciden con el enum de Postgres', () {
      for (final estado in EstadoPlanTratamiento.values) {
        expect(EstadoPlanTratamiento.fromDb(estado.dbValue), estado);
      }
      expect(EstadoPlanTratamiento.enProceso.dbValue, 'en_proceso');
    });
  });
}
