import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/models/caja_diaria_model.dart';

class CajaDiariaRepositoryImpl implements CajaDiariaRepository {
  final CajaDiariaDatasource remoteDataSource;

  CajaDiariaRepositoryImpl(this.remoteDataSource);

  @override
  Future<CajaDiaria?> getCajaActual() async {
    final data = await remoteDataSource.fetchCajaAbierta();

    if (data == null) return null;

    return CajaDiariaModel.fromJson(data);
  }

  @override
  Future<void> abrirCaja(double montoApertura) async {
    final estaAbierta = await remoteDataSource.isCajaAbierta();
    if (estaAbierta) {
      throw Exception(
        'Ya existe una caja abierta. Debe cerrarla antes de abrir una nueva.',
      );
    }

    await remoteDataSource.abrirCaja(montoApertura);
  }

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) async {
    final montoEsperado = await remoteDataSource.getBalanceActual();

    final datosCierre = {
      'monto_real': montoReal,
      'monto_cierre': montoCierre,
      'monto_esperado': montoEsperado,
      'observaciones': observaciones ?? 'Cierre sin observaciones',
    };

    await remoteDataSource.cerrarCaja(datosCierre);
  }

  @override
  Future<bool> isCajaAbierta() async {
    return await remoteDataSource.isCajaAbierta();
  }

  @override
  Future<double> getMontoEsperado() async {
    return await remoteDataSource.getBalanceActual();
  }
}
