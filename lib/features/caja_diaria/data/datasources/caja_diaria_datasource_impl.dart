import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/models/movimiento_caja_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CajaDiariaDatasourceImpl implements CajaDiariaDatasource {
  final SupabaseClient supabase;

  CajaDiariaDatasourceImpl(this.supabase);

  @override
  Future<void> abrirCaja(double montoInicial) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    await supabase.from('cajas').insert({
      'monto_apertura': montoInicial,
      'cerrada': false,
      'fecha': DateTime.now().toIso8601String(),
      'abierta_por': userId,
      'monto_esperado': montoInicial,
      'monto_real': 0,
      'monto_cierre': 0,
    });
  }

  @override
  Future<void> registrarMovimiento(Map<String, dynamic> movimientoData) async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) {
      throw Exception('No hay una caja abierta para registrar movimientos.');
    }

    movimientoData['caja_diaria_id'] = caja['id'];
    movimientoData.remove('id');

    await supabase.from('movimientos_caja').insert(movimientoData);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDelDia() async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) return [];

    final response = await supabase
        .from('movimientos_caja')
        .select()
        .eq('caja_diaria_id', caja['id'])
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) throw Exception('No hay caja abierta para cerrar.');

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    final balanceCalculado = await getBalanceActual();
    final esperado = (datosCierre['monto_esperado'] as num).toDouble();
    // Comparar dos `double` con `!=` hacía que un céntimo de error de
    // redondeo —el que aparece en cuanto hay un pago fraccionado— abortara el
    // cierre con «INCONSISTENCIA» y dejara la caja abierta (defecto D13). El
    // dinero se lleva en centavos: la tolerancia es medio centavo.
    if ((esperado - balanceCalculado).abs() > 0.005) {
      throw Exception(
        'El monto esperado (RD\$ ${esperado.toStringAsFixed(2)}) no coincide '
        'con el balance calculado (RD\$ ${balanceCalculado.toStringAsFixed(2)}). '
        'Revisa los movimientos antes de cerrar.',
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
  }

  @override
  Future<double> getBalanceActual() async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) return 0.0;

    final movimientos = await fetchMovimientosDelDia();
    return BalanceCaja.esperado(
      montoApertura: (caja['monto_apertura'] as num).toDouble(),
      movimientos: movimientos.map(MovimientoCajaModel.fromJson),
    );
  }

  @override
  Future<bool> isCajaAbierta() async => (await _getCajaAbiertaActual()) != null;

  @override
  Future<Map<String, dynamic>?> fetchCajaAbierta() async =>
      await _getCajaAbiertaActual();

  @override
  Stream<List<Map<String, dynamic>>> watchMovimientos(String cajaDiariaId) {
    return supabase
        .from('movimientos_caja')
        .stream(primaryKey: ['id'])
        .eq('caja_diaria_id', cajaDiariaId)
        .map((rows) {
          final filtrados = rows
              .where((row) => row['deleted_at'] == null)
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

          filtrados.sort((a, b) {
            final fA =
                a['fecha']?.toString() ?? a['created_at']?.toString() ?? '';
            final fB =
                b['fecha']?.toString() ?? b['created_at']?.toString() ?? '';
            return fB.compareTo(fA);
          });

          return filtrados;
        });
  }

  /// La caja abierta, sea de hoy o de un día anterior.
  ///
  /// No filtra por fecha a propósito: el índice único `cajas_una_abierta_idx`
  /// es **global**, así que una caja de ayer sin cerrar impide abrir la de hoy.
  /// Esconderla haría que abrir la caja fallara sin decir por qué, que es
  /// justamente el síntoma que reportó QA (defecto D13). Quien la reciba debe
  /// mirar [esDeHoy] y ofrecer cerrarla.
  Future<Map<String, dynamic>?> _getCajaAbiertaActual() async {
    final response = await supabase
        .from('cajas')
        .select()
        .eq('cerrada', false)
        .order('created_at', ascending: false)
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }
}
