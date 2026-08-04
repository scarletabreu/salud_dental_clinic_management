import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';

void main() {
  group('EstadoCita.transicionesPermitidas', () {
    test('grafo de transiciones del ticket SD-81', () {
      // `programada → en_espera` la permite `hfx_clin_004_validar_transicion_cita`
      // desde HFX-CLIN-004. Sin ella aquí, el desplegable no ofrecía «En Espera»
      // y no se podía iniciar la consulta de una cita programada sin pasar
      // antes por Confirmada, con el paciente ya delante (F3-03 del audit del
      // 2 ago 2026). El grafo del cliente y el de la base son el mismo.
      expect(EstadoCita.programada.transicionesPermitidas, const [
        EstadoCita.confirmada,
        EstadoCita.enEspera,
        EstadoCita.cancelada,
        EstadoCita.noAsistio,
      ]);
      expect(EstadoCita.confirmada.transicionesPermitidas, const [
        EstadoCita.enEspera,
        EstadoCita.cancelada,
        EstadoCita.noAsistio,
      ]);
      expect(EstadoCita.enEspera.transicionesPermitidas, const [
        EstadoCita.enConsulta,
        EstadoCita.cancelada,
        EstadoCita.noAsistio,
      ]);
      expect(EstadoCita.enConsulta.transicionesPermitidas, const [
        EstadoCita.completada,
        EstadoCita.cancelada,
      ]);
    });

    test('completada, cancelada y noAsistio son terminales', () {
      expect(EstadoCita.completada.transicionesPermitidas, isEmpty);
      expect(EstadoCita.cancelada.transicionesPermitidas, isEmpty);
      expect(EstadoCita.noAsistio.transicionesPermitidas, isEmpty);
    });

    test('puedeTransicionarA refleja el grafo', () {
      expect(EstadoCita.enConsulta.puedeTransicionarA(EstadoCita.completada),
          isTrue);
      // Transición ilegal: no se puede completar sin pasar por en_consulta.
      expect(EstadoCita.enEspera.puedeTransicionarA(EstadoCita.completada),
          isFalse);
      // No se puede revivir un estado terminal.
      expect(EstadoCita.cancelada.puedeTransicionarA(EstadoCita.programada),
          isFalse);
    });
  });

  group('EstadoCita dbValue / fromDb', () {
    test('dbValue usa snake_case 1:1 con Postgres', () {
      expect(EstadoCita.programada.dbValue, 'programada');
      expect(EstadoCita.confirmada.dbValue, 'confirmada');
      expect(EstadoCita.enEspera.dbValue, 'en_espera');
      expect(EstadoCita.enConsulta.dbValue, 'en_consulta');
      expect(EstadoCita.completada.dbValue, 'completada');
      expect(EstadoCita.cancelada.dbValue, 'cancelada');
      expect(EstadoCita.noAsistio.dbValue, 'no_asistio');
    });

    test('fromDb es inverso de dbValue', () {
      for (final estado in EstadoCita.values) {
        expect(EstadoCita.fromDb(estado.dbValue), estado);
      }
    });

    test('fromDb tolera los valores heredados pre-migración', () {
      expect(EstadoCita.fromDb('pendiente'), EstadoCita.programada);
      expect(EstadoCita.fromDb('atendida'), EstadoCita.completada);
    });
  });
}
