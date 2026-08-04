import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/repositories/cuota_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeCuotaDatasource implements CuotaRemoteDatasource {
  _FakeCuotaDatasource({this.errorAlMarcar});

  final Object? errorAlMarcar;
  final llamadas = <String>[];

  @override
  Future<void> marcarCuotasVencidas(String cuentaId) async {
    llamadas.add('marcar:$cuentaId');
    if (errorAlMarcar != null) throw errorAlMarcar!;
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
  test('leer las cuotas no escribe: nunca llama a marcar_cuotas_vencidas', () async {
    // Defecto D1 (QA 1 ago): un doctor abre «Detalle de Cuenta» y la pantalla
    // entera moría con «Capacidad de caja requerida», porque la lectura
    // ejecutaba antes una RPC de escritura reservada a admin/asistente.
    final datasource = _FakeCuotaDatasource();
    final repository = CuotaRepositoryImpl(remoteDataSource: datasource);

    final cuotas = await repository.getCuotasDeCuenta('c1');

    expect(datasource.llamadas, ['cargar:c1']);
    expect(cuotas.single.estado, EstadoCuota.vencida);
    expect(cuotas.single.montoPagado, 125);
    expect(cuotas.single.saldoPendiente, 375);
  });

  test('marcar vencidas sin capacidad de caja no revienta', () async {
    final datasource = _FakeCuotaDatasource(
      errorAlMarcar: const PostgrestException(
        message: 'Capacidad de caja requerida.',
        code: '42501',
      ),
    );
    final repository = CuotaRepositoryImpl(remoteDataSource: datasource);

    await expectLater(repository.marcarCuotasVencidas('c1'), completes);
    expect(datasource.llamadas, ['marcar:c1']);
  });

  test('marcar vencidas sí propaga cualquier otro fallo', () async {
    final datasource = _FakeCuotaDatasource(
      errorAlMarcar: const PostgrestException(
        message: 'relation "cuotas" does not exist',
        code: '42P01',
      ),
    );
    final repository = CuotaRepositoryImpl(remoteDataSource: datasource);

    await expectLater(
      repository.marcarCuotasVencidas('c1'),
      throwsA(isA<ServerFailure>()),
    );
  });
}
