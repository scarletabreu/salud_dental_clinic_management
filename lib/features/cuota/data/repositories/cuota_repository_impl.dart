import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/models/cuota_model.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

class CuotaRepositoryImpl implements CuotaRepository {
  final CuotaRemoteDatasource remoteDataSource;

  CuotaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId) {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCuotasByCuenta(cuentaId);
      return data.map((json) => CuotaModel.fromJson(json)).toList();
    }, context: 'obtener las cuotas');
  }

  @override
  Future<void> pagarCuota(String cuotaId) {
    return runGuarded(
      () => remoteDataSource.actualizarEstadoCuota(
        cuotaId,
        EstadoCuota.pagada.name,
      ),
      context: 'registrar el pago de la cuota',
    );
  }

  @override
  Future<void> generarPlanDePagos(List<Cuota> cuotas) {
    return runGuarded(() async {
      final cuotasData = cuotas.map((c) {
        return CuotaModel(
          id: c.id,
          cuentaId: c.cuentaId,
          monto: c.monto,
          fechaVencimiento: c.fechaVencimiento,
          estado: c.estado,
        ).toJson();
      }).toList();

      await remoteDataSource.crearCuotas(cuotasData);
    }, context: 'generar el plan de pagos');
  }

  @override
  Future<void> eliminarCuota(String id) {
    return runGuarded(
      () => remoteDataSource.deleteCuota(id),
      context: 'eliminar la cuota',
    );
  }
}
