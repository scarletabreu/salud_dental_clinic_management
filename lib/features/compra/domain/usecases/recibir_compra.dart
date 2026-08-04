import 'package:salud_dental_clinic_management/features/compra/domain/repositories/compra_repository.dart';

class RecibirCompra {
  final CompraRepository _repository;

  const RecibirCompra(this._repository);

  Future<void> call({
    required String compraId,
    required String usuarioId,
    String metodoPago = 'efectivo',
  }) {
    return _repository.recibirCompra(
      compraId: compraId,
      usuarioId: usuarioId,
      metodoPago: metodoPago,
    );
  }
}
