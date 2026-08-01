import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/models/cuota_model.dart';

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

  /// Un `42501` aquí no es un fallo de la operación en curso: significa que
  /// quien la ejecuta no tiene capacidad de caja. La consolidación del estado
  /// «vencida» ocurrirá la próxima vez que cobre alguien que sí la tenga, y
  /// mientras tanto la interfaz ya deriva el vencimiento por fecha
  /// (`Cuota.estaVencida`). Los demás errores sí se propagan.
  @override
  Future<void> marcarCuotasVencidas(String cuentaId) async {
    try {
      await runGuarded(
        () => remoteDataSource.marcarCuotasVencidas(cuentaId),
        context: 'actualizar las cuotas vencidas',
      );
    } on PermisoDenegadoFailure {
      // Sin capacidad de caja: se deja como está. Nada más que hacer.
    }
  }

  @override
  Future<void> generarPlanDePagos(List<Cuota> cuotas) {
    return runGuarded(() async {
      final cuotasData = cuotas.map((c) {
        return CuotaModel(
          id: c.id,
          cuentaId: c.cuentaId,
          monto: c.monto,
          montoPagado: c.montoPagado,
          fechaVencimiento: c.fechaVencimiento,
          estado: c.estado,
        ).toJson();
      }).toList();

      await remoteDataSource.crearCuotas(cuotasData);
    }, context: 'generar el plan de pagos');
  }
}
