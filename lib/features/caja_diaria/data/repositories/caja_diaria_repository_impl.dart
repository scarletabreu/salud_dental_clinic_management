import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/arqueo_pendiente.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/models/caja_diaria_model.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/models/movimiento_caja_model.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

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
  Future<List<ArqueoPendiente>> getArqueosPendientes() {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchCajasSinCerrarDeOtrosDias();
      final cajas = filas
          .map(CajaDiariaModel.fromJson)
          .where((caja) => caja.id != null)
          .toList();
      if (cajas.isEmpty) return const <ArqueoPendiente>[];

      // Una sola consulta para todos los arqueos. Son pocos, pero pedirlos de
      // a uno convertiría cada refresco de la pantalla de caja en N viajes.
      final movimientos = await remoteDataSource.fetchMovimientosDeCajas([
        for (final caja in cajas) caja.id!,
      ]);

      final porCaja = <String, List<MovimientoCaja>>{};
      for (final fila in movimientos) {
        final movimiento = MovimientoCajaModel.fromJson(fila);
        porCaja.putIfAbsent(movimiento.cajaDiariaId, () => []).add(movimiento);
      }

      return [
        for (final caja in cajas)
          ArqueoPendiente(
            id: caja.id!,
            caja: caja,
            movimientos: porCaja[caja.id] ?? const [],
          ),
      ];
    }, context: 'buscar los arqueos pendientes');
  }

  @override
  Future<void> abrirCaja(double montoApertura) async {
    // «Abierta» significa abierta HOY: desde `audit_002` la unicidad es por día
    // civil, así que una caja olvidada de otro día ya no impide trabajar.
    final estaAbierta = await runGuarded(
      () => remoteDataSource.isCajaAbierta(),
      context: 'verificar la caja',
    );
    if (estaAbierta) {
      throw Exception(
        'Ya existe una caja abierta hoy. Debe cerrarla antes de abrir otra.',
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
  Future<void> cerrarArqueoPendiente({
    required String cajaId,
    required double montoReal,
    String? observaciones,
  }) {
    return runGuarded(() async {
      // El esperado sale de los movimientos de *esa* caja, no de los de hoy ni
      // del número que la pantalla tenía cargado cuando se abrió el aviso.
      final montoEsperado = await remoteDataSource.getBalanceDeCaja(cajaId);
      await remoteDataSource.cerrarCajaPorId(cajaId, {
        'monto_real': montoReal,
        'monto_cierre': montoReal,
        'monto_esperado': montoEsperado,
        'observaciones': observaciones ?? 'Arqueo cerrado en diferido.',
      });
    }, context: 'cerrar el arqueo pendiente');
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

  @override
  Stream<List<MovimientoCaja>> watchMovimientos(String cajaDiariaId) {
    return remoteDataSource
        .watchMovimientos(cajaDiariaId)
        .map((data) => data.map(MovimientoCajaModel.fromJson).toList());
  }
}
