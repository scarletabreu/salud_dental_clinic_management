import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/models/cuota_model.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';

class CuotaRepositoryImpl implements CuotaRepository {
  final CuotaRemoteDatasource remoteDataSource;

  CuotaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId) async {
    final data = await remoteDataSource.fetchCuotasByCuenta(cuentaId);
    return data.map((json) => CuotaModel.fromJson(json)).toList();
  }

  @override
  Future<void> pagarCuota(String cuotaId) async {
    await remoteDataSource.actualizarEstadoCuota(
      cuotaId,
      EstadoCuota.pagada.name,
    );
  }

  @override
  Future<void> generarPlanDePagos(List<Cuota> cuotas) async {
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
  }

  @override
  Future<void> eliminarCuota(String id) async {
    await remoteDataSource.deleteCuota(id);
  }
}
