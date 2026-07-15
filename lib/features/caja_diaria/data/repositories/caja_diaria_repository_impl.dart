import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/models/caja_diaria_model.dart';

class CajaDiariaRepositoryImpl implements CajaDiariaRepository {
  final CajaDiariaDatasource remoteDataSource;

  CajaDiariaRepositoryImpl(this.remoteDataSource);

  @override
  Future<CajaDiaria?> getCajaActual() {
    return runGuarded(() async {
      final data = await remoteDataSource.fetchCajaAbierta();
      return data == null ? null : CajaDiariaModel.fromJson(data);
    }, context: 'obtener la caja actual');
  }

  @override
  Future<void> abrirCaja(double montoApertura) async {
    final estaAbierta = await runGuarded(
      () => remoteDataSource.isCajaAbierta(),
      context: 'verificar la caja',
    );
    if (estaAbierta) {
      throw Exception(
        'Ya existe una caja abierta. Debe cerrarla antes de abrir una nueva.',
      );
    }
    await runGuarded(
      () => remoteDataSource.abrirCaja(montoApertura),
      context: 'abrir la caja',
    );
  }

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) {
    return runGuarded(() async {
      final montoEsperado = await remoteDataSource.getBalanceActual();
      final datosCierre = {
        'monto_real': montoReal,
        'monto_cierre': montoCierre,
        'monto_esperado': montoEsperado,
        'observaciones': observaciones ?? 'Cierre sin observaciones',
      };
      await remoteDataSource.cerrarCaja(datosCierre);
    }, context: 'cerrar la caja');
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
  Future<double> getMontoEsperado() {
    return runGuarded(
      () => remoteDataSource.getBalanceActual(),
      context: 'calcular el balance esperado',
    );
  }
}
