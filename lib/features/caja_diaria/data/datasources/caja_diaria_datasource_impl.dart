import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CajaDiariaDatasourceImpl implements CajaDiariaDatasource {
  final SupabaseClient supabase;

  CajaDiariaDatasourceImpl(this.supabase);

  @override
  Future<void> abrirCaja(double montoInicial) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado.');

      await supabase.from('cajas').insert({
        'monto_apertura': montoInicial,
        'cerrada': false,
        'fecha': DateTime.now().toIso8601String(),
        'abierta_por': userId, // Integración de campo
        'monto_esperado': montoInicial,
        'monto_real': 0,
        'monto_cierre': 0,
      });
    } on PostgrestException catch (e) {
      throw Exception('Error al abrir caja: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al abrir caja: $e');
    }
  }

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData) async {
    try {
      final caja = await _getCajaAbiertaActual();
      if (caja == null) {
        throw Exception('No hay una caja abierta para registrar movimientos.');
      }

      movimientoData['caja_id'] = caja['id'];
      movimientoData.remove('id');

      await supabase.from('movimientos_caja').insert(movimientoData);
    } catch (e) {
      throw Exception('Error al registrar movimiento: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia() async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) return [];

    try {
      final response = await supabase
          .from('movimientos_caja')
          .select()
          .eq('caja_id', caja['id'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Error al obtener movimientos: $e');
    }
  }

  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    try {
      final caja = await _getCajaAbiertaActual();
      if (caja == null) throw Exception('No hay caja abierta para cerrar.');

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado.');

      final balanceCalculado = await getBalanceActual();
      if ((datosCierre['monto_esperado'] as num).toDouble() !=
          balanceCalculado) {
        throw Exception(
          'INCONSISTENCIA: El monto esperado ($balanceCalculado) no coincide con el balance calculado.',
        );
      }

      await supabase
          .from('cajas')
          .update({
            'monto_cierre': datosCierre['monto_cierre'],
            'monto_real': datosCierre['monto_real'],
            'monto_esperado': datosCierre['monto_esperado'],
            'cerrada': true,
            'cerrada_por': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', caja['id']);
    } catch (e) {
      throw Exception('Error al cerrar caja: $e');
    }
  }

  @override
  Future<double> getBalanceActual() async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) return 0.0;

    final movimientos = await fetchMovimientosDelDia();
    double balance = (caja['monto_apertura'] as num).toDouble();

    for (var mov in movimientos) {
      double monto = (mov['monto'] as num).toDouble();
      if (mov['tipo'] == 'ingreso') {
        balance += monto;
      } else {
        balance -= monto;
      }
    }
    return balance;
  }

  @override
  Future<bool> isCajaAbierta() async => (await _getCajaAbiertaActual()) != null;

  @override
  Future<Map<String, dynamic>?> fetchCajaAbierta() async =>
      await _getCajaAbiertaActual();

  Future<Map<String, dynamic>?> _getCajaAbiertaActual() async {
    try {
      return await supabase
          .from('cajas')
          .select()
          .eq('cerrada', false)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }
}
