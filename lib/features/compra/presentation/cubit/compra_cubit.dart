import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/entities/compra.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/repositories/compra_repository.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/usecases/recibir_compra.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/cubit/compra_state.dart';

class CompraCubit extends Cubit<CompraState> {
  final CompraRepository _repository;
  final RecibirCompra _recibirCompraUseCase;

  CompraCubit({
    required CompraRepository repository,
    required RecibirCompra recibirCompraUseCase,
  }) : _repository = repository,
       _recibirCompraUseCase = recibirCompraUseCase,
       super(const CompraLoading());

  Future<void> cargar() async {
    emit(const CompraLoading());
    try {
      final list = await _repository.fetchCompras();
      emit(CompraLoaded(compras: list));
    } catch (e) {
      emit(CompraError('No se pudieron obtener las compras: $e'));
    }
  }

  void filtrarPorBusqueda(String query) {
    final currentState = state;
    if (currentState is CompraLoaded) {
      emit(currentState.copyWith(busqueda: query));
    }
  }

  Future<void> registrarCompra(Compra compra) async {
    try {
      await _repository.registrarCompra(compra);
      await cargar();
    } catch (e) {
      emit(CompraError('No se pudo registrar la compra: $e'));
    }
  }

  Future<String?> recibirCompra({
    required String compraId,
    required String usuarioId,
    String metodoPago = 'efectivo',
  }) async {
    try {
      await _recibirCompraUseCase(
        compraId: compraId,
        usuarioId: usuarioId,
        metodoPago: metodoPago,
      );
      await cargar();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}
