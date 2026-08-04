import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/models/cuenta_model.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';

void main() {
  test('mapea credito de Postgres sin confundirlo con la etiqueta Crédito', () {
    final cuenta = CuentaModel.fromJson({
      'id': 'c1',
      'consulta_id': 'consulta-1',
      'fecha_creacion': '2026-07-20T12:00:00Z',
      'metodo_pago': 'credito',
    });

    expect(cuenta.metodoPago, MetodoPago.credito);
    expect(cuenta.toJson()['metodo_pago'], 'credito');
  });
}
