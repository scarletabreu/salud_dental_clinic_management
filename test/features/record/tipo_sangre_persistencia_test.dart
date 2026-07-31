// La grafía del tipo de sangre es un contrato entre dos enums que no se
// conocen: el de Dart, en camelCase, y el de Postgres, en snake_case.
//
// La aplicación enviaba `TipoSangre.name`, así que el alta de un paciente
// mandaba «oPositivo», Postgres rechazaba el cast con 22P02 y la transacción
// entera de `registrar_paciente` hacía rollback: ninguna alta se completaba. La
// certificación no lo vio porque sus jornadas escriben el payload REST a mano,
// ya en snake_case, sin pasar por el datasource.
//
// La contraparte en la base es supabase/tests/hfx_clin_007_escrituras_directas_test.sql,
// que comprueba que estas mismas nueve cadenas son etiquetas válidas del enum.

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/record/data/models/record_model.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

void main() {
  group('TipoSangre ↔ enum tipo_sangre de Postgres', () {
    test('cada valor persiste con la etiqueta que la base acepta', () {
      const esperado = <TipoSangre, String>{
        TipoSangre.aPositivo: 'a_positivo',
        TipoSangre.aNegativo: 'a_negativo',
        TipoSangre.bPositivo: 'b_positivo',
        TipoSangre.bNegativo: 'b_negativo',
        TipoSangre.abPositivo: 'ab_positivo',
        TipoSangre.abNegativo: 'ab_negativo',
        TipoSangre.oPositivo: 'o_positivo',
        TipoSangre.oNegativo: 'o_negativo',
        TipoSangre.desconocido: 'desconocido',
      };

      expect(esperado.length, TipoSangre.values.length);
      for (final entrada in esperado.entries) {
        expect(entrada.key.dbValue, entrada.value);
      }
    });

    test('ningún valor se persiste con el nombre de la constante de Dart', () {
      // `desconocido` es la única etiqueta que coincide en ambas grafías, y es
      // justo la que hacía parecer que el defecto no existía.
      final camelCase = TipoSangre.values
          .where((t) => t != TipoSangre.desconocido)
          .where((t) => t.dbValue == t.name)
          .toList();

      expect(camelCase, isEmpty);
    });

    test('se reconstruye desde lo que devuelve la base', () {
      for (final tipo in TipoSangre.values) {
        expect(TipoSangre.desdeDb(tipo.dbValue), tipo);
      }
    });

    test('sigue leyendo la grafía vieja para no perder fichas ya guardadas', () {
      expect(TipoSangre.desdeDb('oPositivo'), TipoSangre.oPositivo);
      expect(TipoSangre.desdeDb('abNegativo'), TipoSangre.abNegativo);
    });

    test('lo desconocido o ilegible cae en desconocido, no revienta', () {
      expect(TipoSangre.desdeDb(null), TipoSangre.desconocido);
      expect(TipoSangre.desdeDb(''), TipoSangre.desconocido);
      expect(TipoSangre.desdeDb('vino tinto'), TipoSangre.desconocido);
    });
  });

  group('RecordModel', () {
    test('serializa el tipo de sangre con la etiqueta de la base', () {
      final record = RecordModel(
        pacienteId: 'p1',
        tipoSangre: TipoSangre.oPositivo,
        condiciones: const [],
        cirugiasPrevias: const [],
        historialFamiliar: '',
      );

      expect(record.toJson()['tipo_sangre'], 'o_positivo');
    });

    test('no degrada a desconocido lo que la base devuelve', () {
      // El `firstWhere` anterior comparaba contra `name`, así que ningún tipo
      // guardado en snake_case casaba y todo expediente se leía como
      // «desconocido» sin dar el menor error.
      final record = RecordModel.fromJson({
        'paciente_id': 'p1',
        'tipo_sangre': 'ab_negativo',
        'cirugias_previas': <String>[],
        'historial_familiar': '',
      });

      expect(record.tipoSangre, TipoSangre.abNegativo);
    });

    test('la etiqueta clínica se muestra como O+, no como OPOSITIVO', () {
      final record = RecordModel(
        pacienteId: 'p1',
        tipoSangre: TipoSangre.oPositivo,
        condiciones: const [],
        cirugiasPrevias: const [],
        historialFamiliar: '',
      );

      expect(record.bloodType, 'O+');
    });
  });
}
