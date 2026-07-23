import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';

sealed class InventarioState {
  const InventarioState();
}

class InventarioLoading extends InventarioState {
  const InventarioLoading();
}

class InventarioLoaded extends InventarioState {
  final List<Consumible> consumibles;
  final String busqueda;
  final bool soloCriticos;

  const InventarioLoaded({
    required this.consumibles,
    this.busqueda = '',
    this.soloCriticos = false,
  });

  int get totalArticulos => consumibles.length;
  int get totalCriticos => consumibles.where((c) => c.estaBajoStock).length;

  List<Consumible> get consumiblesFiltrados {
    return consumibles.where((c) {
      final coincideNombre =
          c.nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
          c.descripcion.toLowerCase().contains(busqueda.toLowerCase());
      final coincideFiltro = !soloCriticos || c.estaBajoStock;
      return coincideNombre && coincideFiltro;
    }).toList();
  }

  InventarioLoaded copyWith({
    List<Consumible>? consumibles,
    String? busqueda,
    bool? soloCriticos,
  }) {
    return InventarioLoaded(
      consumibles: consumibles ?? this.consumibles,
      busqueda: busqueda ?? this.busqueda,
      soloCriticos: soloCriticos ?? this.soloCriticos,
    );
  }
}

class InventarioError extends InventarioState {
  final String mensaje;
  const InventarioError(this.mensaje);
}
