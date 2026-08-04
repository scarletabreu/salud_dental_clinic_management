import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/models/diagnosis_model.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';

void main() {
  test('mapea las etiquetas reales de categoría de Postgres', () {
    final modelo = DiagnosisModel.fromJson({
      'id': 'diag-1',
      'nombre': 'Pérdida dental',
      'descripcion': '',
      'severidad_default': SeveridadDiagnosis.grave.name,
      'alcance': Alcance.diente.name,
      'categoria': 'patologia_atm',
      'clave_odontograma': 'perdida',
    });

    expect(modelo.categoria, CategoriaDiagnosis.patologiaATM);
    expect(modelo.claveOdontograma, 'perdida');
    expect(modelo.toJson()['categoria'], 'patologia_atm');
  });
}
