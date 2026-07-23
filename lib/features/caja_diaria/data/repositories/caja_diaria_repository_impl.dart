import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/resumen_cierre.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/models/caja_diaria_model.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

class CajaDiariaRepositoryImpl implements CajaDiariaRepository {
  final CajaDiariaDatasource remoteDataSource;
  final MovimientoCajaRepository movimientoCajaRepository;

  CajaDiariaRepositoryImpl(
    this.remoteDataSource,
    this.movimientoCajaRepository,
  );

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

  Future<double> _calcularMontoEsperado({
    required String cajaId,
    required double montoApertura,
  }) async {
    final movimientos = await movimientoCajaRepository.getMovimientosDeHoy(
      cajaId,
    );
    double balance = montoApertura;
    for (final mov in movimientos) {
      if (mov.tipo == TipoMovimiento.ingreso) {
        balance += mov.monto;
      } else {
        balance -= mov.monto;
      }
    }
    return balance;
  }

  @override
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  }) async {
    try {
      final caja = await remoteDataSource.fetchCajaAbierta();
      if (caja == null) throw Exception('No hay caja abierta para cerrar.');

      final montoEsperado = await _calcularMontoEsperado(
        cajaId: caja['id'] as String,
        montoApertura: (caja['monto_apertura'] as num).toDouble(),
      );

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
      final caja = await remoteDataSource.fetchCajaAbierta();
      if (caja == null) return 0.0;
      return _calcularMontoEsperado(
        cajaId: caja['id'] as String,
        montoApertura: (caja['monto_apertura'] as num).toDouble(),
      );
    } catch (e) {
      throw Exception('Error al calcular el balance esperado: $e');
    }
  }

  Future<ResumenCierre> getResumenCierre() async {
    try {
      final caja = await remoteDataSource.fetchCajaAbierta();
      if (caja == null) throw Exception('No hay una caja abierta.');

      final cajaId = caja['id'] as String;
      final montoApertura = (caja['monto_apertura'] as num).toDouble();

      final movimientos = await movimientoCajaRepository.getMovimientosDeHoy(
        cajaId,
      );

      final totalesPorMetodoPago = <String, double>{};
      double totalIngresos = 0;
      double totalEgresos = 0;

      for (final mov in movimientos) {
        final signo = mov.tipo == TipoMovimiento.ingreso ? 1 : -1;
        totalesPorMetodoPago.update(
          mov.metodoPago,
          (valor) => valor + (signo * mov.monto),
          ifAbsent: () => signo * mov.monto,
        );
        if (mov.tipo == TipoMovimiento.ingreso) {
          totalIngresos += mov.monto;
        } else {
          totalEgresos += mov.monto;
        }
      }

      return ResumenCierre(
        totalesPorMetodoPago: totalesPorMetodoPago,
        totalIngresos: totalIngresos,
        totalEgresos: totalEgresos,
        montoEsperado: montoApertura + totalIngresos - totalEgresos,
        movimientos: movimientos,
      );
    } catch (e) {
      throw Exception('Error al generar el resumen de cierre: $e');
    }
  }
}
