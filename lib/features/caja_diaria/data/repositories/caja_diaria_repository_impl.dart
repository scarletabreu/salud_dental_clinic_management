import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/models/caja_diaria_model.dart';

class CajaDiariaRepositoryImpl implements CajaDiariaRepository {
  final CajaDiariaDatasource remoteDataSource;

  CajaDiariaRepositoryImpl(this.remoteDataSource);

  @override
  Future<CajaDiaria?> getCajaActual() async {
    try {
      final data = await remoteDataSource.fetchCajaAbierta();
      return data == null ? null : CajaDiariaModel.fromJson(data);
    } catch (e) {
      throw Exception('Error al obtener la caja actual: $e');
    }
  }

  @override
  Future<void> abrirCaja(double montoApertura) async {
    try {
      final estaAbierta = await remoteDataSource.isCajaAbierta();
      if (estaAbierta) {
        throw Exception(
          'Ya existe una caja abierta. Debe cerrarla antes de abrir una nueva.',
        );
      }
      await remoteDataSource.abrirCaja(montoApertura);
    } catch (e) {
      throw Exception('Error al abrir la caja: $e');
    }
  }

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) async {
    try {
      final montoEsperado = await remoteDataSource.getBalanceActual();
      final datosCierre = {
        'monto_real': montoReal,
        'monto_cierre': montoCierre,
        'monto_esperado': montoEsperado,
        'observaciones': observaciones ?? 'Cierre sin observaciones',
      };
      await remoteDataSource.cerrarCaja(datosCierre);
    } catch (e) {
      throw Exception('Error al cerrar la caja: $e');
    }
  }

  @override
  Future<bool> isCajaAbierta() async {
    try {
      return await remoteDataSource.isCajaAbierta();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<double> getMontoEsperado() async {
    try {
      return await remoteDataSource.getBalanceActual();
    } catch (e) {
      throw Exception('Error al calcular el balance esperado: $e');
    }
  }
}
