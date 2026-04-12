import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

class ItemCuenta {
  final String id;
  final String cuentaId;
  final String descripcion;
  final double precioUnitario;
  final int cantidad;
  final List<Tratamiento> tratamientosAplicados;

  ItemCuenta({
    required this.id,
    required this.cuentaId,
    required this.descripcion,
    required this.precioUnitario,
    required this.cantidad,
    this.tratamientosAplicados = const [],
  });

  double get precioTotal => precioUnitario * cantidad;

  ItemCuenta copyWith({
    String? cuentaId,
    String? descripcion,
    double? precioUnitario,
    int? cantidad,
    List<Tratamiento>? tratamientosAplicados,
  }) {
    return ItemCuenta(
      id: id,
      cuentaId: cuentaId ?? this.cuentaId,
      descripcion: descripcion ?? this.descripcion,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      cantidad: cantidad ?? this.cantidad,
      tratamientosAplicados:
          tratamientosAplicados ?? List.from(this.tratamientosAplicados),
    );
  }
}
