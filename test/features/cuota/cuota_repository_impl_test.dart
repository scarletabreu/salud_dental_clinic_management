import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/repositories/cuota_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

class _FakeCuotaDatasource implements CuotaRemoteDatasource {
  final llamadas = <String>[];

  @override
  Future<void> marcarCuotasVencidas(String cuentaId) async {
    llamadas.add('marcar:$cuentaId');
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCuotasByCuenta(
    String cuentaId,
  ) async {
    llamadas.add('cargar:$cuentaId');
    return [
      {
        'id': 'q1',
        'cuenta_id': cuentaId,
        'monto': 500,
        'monto_pagado': 125,
        'fecha_vencimiento': '2026-07-01',
        'estado': 'vencida',
      },
    ];
  }

  @override
  Future<void> crearCuotas(List<Map<String, dynamic>> cuotasData) async {}
}

void main() {
  test('marca vencidas antes de cargar y conserva el monto abonado', () async {
    final datasource = _FakeCuotaDatasource();
    final repository = CuotaRepositoryImpl(remoteDataSource: datasource);

    final cuotas = await repository.getCuotasDeCuenta('c1');

    expect(datasource.llamadas, ['marcar:c1', 'cargar:c1']);
    expect(cuotas.single.estado, EstadoCuota.vencida);
    expect(cuotas.single.montoPagado, 125);
    expect(cuotas.single.saldoPendiente, 375);
  });
}
