import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';

sealed class CompraState {
  const CompraState();
}

class CompraLoading extends CompraState {
  const CompraLoading();
}

class CompraLoaded extends CompraState {
  final List<Compra> compras;
  final String busqueda;

  const CompraLoaded({required this.compras, this.busqueda = ''});

  List<Compra> get comprasFiltradas {
    if (busqueda.trim().isEmpty) return compras;
    final query = busqueda.toLowerCase();
    return compras.where((c) {
      return (c.id ?? '').toLowerCase().contains(query) ||
          c.estado.name.toLowerCase().contains(query);
    }).toList();
  }

  CompraLoaded copyWith({List<Compra>? compras, String? busqueda}) {
    return CompraLoaded(
      compras: compras ?? this.compras,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}

class CompraError extends CompraState {
  final String mensaje;
  const CompraError(this.mensaje);
}
