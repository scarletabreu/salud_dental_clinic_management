import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';

sealed class SuplidorState {
  const SuplidorState();
}

class SuplidorLoading extends SuplidorState {
  const SuplidorLoading();
}

class SuplidorLoaded extends SuplidorState {
  final List<Suplidor> suplidores;
  final String busqueda;

  const SuplidorLoaded({required this.suplidores, this.busqueda = ''});

  List<Suplidor> get suplidoresFiltrados {
    if (busqueda.trim().isEmpty) return suplidores;
    final query = busqueda.toLowerCase();
    return suplidores.where((s) {
      return s.nombre.toLowerCase().contains(query) ||
          s.summary.toLowerCase().contains(query);
    }).toList();
  }

  SuplidorLoaded copyWith({List<Suplidor>? suplidores, String? busqueda}) {
    return SuplidorLoaded(
      suplidores: suplidores ?? this.suplidores,
      busqueda: busqueda ?? this.busqueda,
    );
  }
}

class SuplidorError extends SuplidorState {
  final String mensaje;
  const SuplidorError(this.mensaje);
}
