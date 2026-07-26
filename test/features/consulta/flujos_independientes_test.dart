import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/data/models/item_plan_tratamiento_model.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/models/tratamiento_aplicado_model.dart';

void main() {
  group('contrato de los flujos clínicos', () {
    test('el tipo de atención sobrevive al mapeo de consulta', () {
      final evaluacion = ConsultaModel.fromJson({
        'id': 'consulta-1',
        'paciente_id': 'paciente-1',
        'doctor_id': 'doctor-1',
        'fecha': '2026-07-25T12:00:00Z',
        'tipo_atencion': 'evaluacion',
      });

      expect(evaluacion.tipoAtencion, TipoAtencionClinica.evaluacion);
      expect(evaluacion.toJson()['tipo_atencion'], 'evaluacion');
    });

    test('los registros anteriores se interpretan como consulta', () {
      final anterior = ConsultaModel.fromJson({
        'paciente_id': 'paciente-1',
        'doctor_id': 'doctor-1',
        'fecha': '2026-07-25T12:00:00Z',
      });

      expect(anterior.tipoAtencion, TipoAtencionClinica.consulta);
    });

    test('la ejecución no planificada conserva su justificación', () {
      final tratamiento = TratamientoAplicadoModel.fromJson({
        'tratamiento_id': 'tratamiento-1',
        'es_continuo': false,
        'esta_terminado': true,
        'estado': 'aplicado',
        'justificacion_no_planificada': 'Dolor agudo durante la sesión',
      });

      expect(
        tratamiento.toJson()['justificacion_no_planificada'],
        'Dolor agudo durante la sesión',
      );
      expect(tratamiento.itemPlanId, isNull);
    });

    test('una actividad planificada trae la pieza FDI de su evaluación', () {
      final item = ItemPlanTratamientoModel.fromJson({
        'id': 'item-1',
        'plan_id': 'plan-1',
        'tratamiento_id': 'tratamiento-1',
        'fecha_propuesta': '2026-07-25T12:00:00Z',
        'diente': {'id': 'diente-1', 'fdi_code': 16},
        'tratamiento': {'nombre': 'Resina compuesta'},
      });

      expect(item.fdiDiente, 16);
      expect(item.nombreTratamiento, 'Resina compuesta');
    });
  });
}
