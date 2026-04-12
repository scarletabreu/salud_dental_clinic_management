import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';

class MovimientoCaja {
  final String id;
  final String cajaDiariaId;
  final TipoMovimiento tipo;
  final double monto;
  final String descripcion;
  final DateTime fecha;
  final String referenciaId;

  MovimientoCaja({
    required this.id,
    required this.cajaDiariaId,
    required this.tipo,
    required this.monto,
    required this.descripcion,
    required this.fecha,
    required this.referenciaId,
  });

  MovimientoCaja copyWith({
    String? cajaDiariaId,
    TipoMovimiento? tipo,
    double? monto,
    String? descripcion,
    DateTime? fecha,
    String? referenciaId,
  }) {
    return MovimientoCaja(
      id: id,
      cajaDiariaId: cajaDiariaId ?? this.cajaDiariaId,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
      referenciaId: referenciaId ?? this.referenciaId,
    );
  }
}
