import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/models/consumible_model.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';

void main() {
  group('Consumible', () {
    Consumible createConsumible({
      required int stockActual,
      int stockMinimo = 5,
      bool activo = true,
    }) {
      return Consumible(
        id: 'b7c7a001-0000-4000-8000-000000000001',
        nombre: 'Guantes',
        descripcion: 'Caja de guantes',
        precio: 325.50,
        stockActual: stockActual,
        stockMinimo: stockMinimo,
        estado: EstadoConsumible.disponible,
        activo: activo,
      );
    }

    test('calcula el estado desde las existencias actuales', () {
      expect(
        createConsumible(stockActual: 8).estadoCalculado,
        EstadoConsumible.disponible,
      );
      expect(
        createConsumible(stockActual: 5).estadoCalculado,
        EstadoConsumible.bajoStock,
      );
      expect(
        createConsumible(stockActual: 0).estadoCalculado,
        EstadoConsumible.agotado,
      );
      expect(
        createConsumible(stockActual: 8, activo: false).estadoCalculado,
        EstadoConsumible.descontinuado,
      );
    });

    test('mapea precio, suplidor y activo desde Supabase', () {
      final model = ConsumibleModel.fromJson({
        'id': 'b7c7a001-0000-4000-8000-000000000001',
        'nombre': 'Guantes',
        'descripcion': 'Caja de guantes',
        'precio': 325.50,
        'stock_actual': 12,
        'stock_minimo': 5,
        'estado': 'disponible',
        'suplidor_id': 'b7c7a001-0000-4000-8000-000000000002',
        'suplidor': {'nombre': 'Dental Supply'},
        'activo': true,
      });

      expect(model.precio, 325.50);
      expect(model.suplidorNombre, 'Dental Supply');
      expect(model.activo, isTrue);
      expect(
        model.toJson()['suplidor_id'],
        'b7c7a001-0000-4000-8000-000000000002',
      );
    });
  });
}
