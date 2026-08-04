import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

class RegistrarEgresoCaja {
  final MovimientoCajaRepository repository;

  RegistrarEgresoCaja(this.repository);

  Future<void> call({
    required String cajaDiariaId,
    required double monto,
    required String descripcion,
    required double montoDisponibleEsperado,
  }) async {
    if (monto <= 0) {
      throw Exception('El monto del egreso debe ser mayor a cero.');
    }

    if (descripcion.trim().isEmpty) {
      throw Exception('La descripción del egreso es obligatoria.');
    }

    if (monto > montoDisponibleEsperado) {
      throw Exception(
        'El egreso (RD\$ ${monto.toStringAsFixed(2)}) excede el monto esperado disponible en caja (RD\$ ${montoDisponibleEsperado.toStringAsFixed(2)}).',
      );
    }

    final movimiento = MovimientoCaja(
      cajaDiariaId: cajaDiariaId,
      tipo: TipoMovimiento.egreso,
      monto: monto,
      descripcion: descripcion.trim(),
      fecha: DateTime.now(),
      referenciaId: 'EGRESO_MANUAL_${DateTime.now().millisecondsSinceEpoch}',
    );

    await repository.crearMovimiento(movimiento);
  }
}
