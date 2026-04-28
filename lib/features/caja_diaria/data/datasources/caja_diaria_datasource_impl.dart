import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CajaDiariaDatasourceImpl implements CajaDiariaDatasource {
  final SupabaseClient supabase;

  CajaDiariaDatasourceImpl(this.supabase);

  @override
  Future<void> abrirCaja(double montoInicial) async {
    await supabase.from('cajas').insert({
      'monto_apertura': montoInicial,
      'cerrada': false,
      'fecha': DateTime.now().toIso8601String(),
      'abierta_por': supabase.auth.currentUser?.id,
      'monto_esperado': montoInicial,
      'monto_real': 0,
      'monto_cierre': 0,
    });
  }

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData) async {
    final caja = await _getCajaAbiertaActual();

    if (caja != null) {
      movimientoData['caja_id'] = caja['id'];
      await supabase.from('movimientos_caja').insert(movimientoData);
    } else {
      throw Exception('No hay una caja abierta para registrar movimientos.');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia() async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) return [];

    final response = await supabase
        .from('movimientos_caja')
        .select()
        .eq('caja_id', caja['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) {
      throw Exception('No se encontró una caja abierta para cerrar.');
    }

    await supabase
        .from('cajas')
        .update({
          'monto_cierre': datosCierre['monto_cierre'],
          'monto_real': datosCierre['monto_real'],
          'monto_esperado': datosCierre['monto_esperado'],
          'cerrada': true,
          'cerrada_por': supabase.auth.currentUser?.id,
        })
        .eq('id', caja['id']);
  }

  @override
  Future<bool> isCajaAbierta() async {
    final caja = await _getCajaAbiertaActual();
    return caja != null;
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
  Future<Map<String, dynamic>?> fetchCajaAbierta() async {
    return await _getCajaAbiertaActual();
  }

  Future<Map<String, dynamic>?> _getCajaAbiertaActual() async {
    final response = await supabase
        .from('cajas')
        .select()
        .eq('cerrada', false)
        .maybeSingle();
    return response;
  }
}
