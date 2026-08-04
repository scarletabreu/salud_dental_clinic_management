import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/arqueo_pendiente.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';

abstract class CajaDiariaRepository {
  Future<CajaDiaria?> getCajaActual();
  Future<void> abrirCaja(double montoApertura);
  Future<void> cerrarCaja({
    required double montoReal,
    required double montoCierre,
    String? observaciones,
  });
  Future<bool> isCajaAbierta();
  Future<double> getMontoEsperado();

  /// Arqueos de días anteriores que quedaron sin cerrar, cada uno con sus
  /// movimientos para poder cuadrarlo sin abrirlo a ciegas.
  Future<List<ArqueoPendiente>> getArqueosPendientes();

  /// Cierra el arqueo de un día anterior.
  ///
  /// El esperado no se recibe: lo recalcula el datasource contra los
  /// movimientos de esa caja, igual que en el cierre del día.
  Future<void> cerrarArqueoPendiente({
    required String cajaId,
    required double montoReal,
    String? observaciones,
  });

  Stream<List<MovimientoCaja>> watchMovimientos(String cajaDiariaId);
}
