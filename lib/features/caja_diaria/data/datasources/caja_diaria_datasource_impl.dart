import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/models/movimiento_caja_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CajaDiariaDatasourceImpl implements CajaDiariaDatasource {
  final SupabaseClient supabase;

  CajaDiariaDatasourceImpl(this.supabase);

  /// Zona civil de la clínica. Es la misma que usan el trigger de pagos y la
  /// recepción de compras para decidir cuál es «la caja de hoy».
  static const _zonaClinica = Duration(hours: -4);

  @override
  Future<void> abrirCaja(double montoInicial) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    await supabase.from('cajas').insert({
      'monto_apertura': montoInicial,
      'cerrada': false,
      // Sin `.toUtc()` la cadena no llevaba zona y Postgres la interpretaba
      // como UTC: una caja abierta entre las 00:00 y las 04:00 nacía fechada el
      // día anterior y el trigger de pagos no la encontraba nunca.
      'fecha': DateTime.now().toUtc().toIso8601String(),
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

    return fetchMovimientosDeCaja(caja['id'] as String);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDeCaja(
    String cajaId,
  ) async {
    final response = await supabase
        .from('movimientos_caja')
        .select()
        .eq('caja_diaria_id', cajaId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMovimientosDeCajas(
    List<String> cajaIds,
  ) async {
    if (cajaIds.isEmpty) return [];

    final response = await supabase
        .from('movimientos_caja')
        .select()
        .inFilter('caja_diaria_id', cajaIds)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Cierre de la caja de hoy. Es el mismo cierre que el de un arqueo
  /// atrasado —quién, cuándo y con cuánto— sólo que resolviendo la caja por
  /// fecha en vez de por id.
  @override
  Future<void> cerrarCaja(Map<String, dynamic> datosCierre) async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) throw Exception('No hay caja abierta para cerrar.');

    await cerrarCajaPorId(caja['id'] as String, datosCierre);
  }

  @override
  Future<void> cerrarCajaPorId(
    String cajaId,
    Map<String, dynamic> datosCierre,
  ) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado.');

    final balanceCalculado = await getBalanceDeCaja(cajaId);
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

    final ahora = DateTime.now().toUtc().toIso8601String();
    final observaciones = datosCierre['observaciones'];

    // `cerrada = false` en el filtro, no sólo en la pantalla: dos sesiones
    // viendo el mismo arqueo pendiente podían cerrarlo las dos y la segunda
    // pisaba el conteo de la primera. `.select()` delata ese caso, porque un
    // UPDATE que no tocó ninguna fila no devuelve ninguna.
    final filas = await supabase
        .from('cajas')
        .update({
          'monto_cierre': datosCierre['monto_cierre'],
          'monto_real': datosCierre['monto_real'],
          'monto_esperado': datosCierre['monto_esperado'],
          // La observación del cajero se armaba en el repositorio y se perdía
          // aquí: la columna existe y nunca se llenaba.
          if (observaciones != null) 'observaciones': observaciones,
          'cerrada': true,
          'cerrada_por': userId,
          'cerrada_at': ahora,
          'updated_at': ahora,
        })
        .eq('id', cajaId)
        .eq('cerrada', false)
        .select('id');

    if ((filas as List).isEmpty) {
      throw Exception(
        'Esa caja ya fue cerrada por otra persona. Actualiza la pantalla para '
        'ver el arqueo definitivo.',
      );
    }
  }

  @override
  Future<double> getBalanceActual() async {
    final caja = await _getCajaAbiertaActual();
    if (caja == null) return 0.0;

    return _balanceDe(caja);
  }

  @override
  Future<double> getBalanceDeCaja(String cajaId) async {
    final caja = await _fetchCaja(cajaId);
    if (caja == null) {
      throw Exception('La caja indicada ya no existe.');
    }

    return _balanceDe(caja);
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

  /// Cajas abiertas de días anteriores a hoy.
  ///
  /// Desde `audit_002` la unicidad es por día civil, así que una caja olvidada
  /// ya no impide abrir la de hoy ni cobrar. Pero sigue siendo un pendiente
  /// contable real, y la pantalla tiene que poder decirlo en vez de mostrar el
  /// saldo de otro día como si fuera el de hoy.
  @override
  Future<List<Map<String, dynamic>>> fetchCajasSinCerrarDeOtrosDias() async {
    final response = await supabase
        .from('cajas')
        .select()
        .eq('cerrada', false)
        .lt('fecha_civil', _hoyCivil())
        .order('fecha_civil', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<double> _balanceDe(Map<String, dynamic> caja) async {
    final movimientos = await fetchMovimientosDeCaja(caja['id'] as String);
    return BalanceCaja.esperado(
      montoApertura: (caja['monto_apertura'] as num).toDouble(),
      movimientos: movimientos.map(MovimientoCajaModel.fromJson),
    );
  }

  Future<Map<String, dynamic>?> _fetchCaja(String cajaId) async {
    final response = await supabase
        .from('cajas')
        .select()
        .eq('id', cajaId)
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  /// La caja abierta **de hoy**, con la misma definición de «hoy» que usa la
  /// base: el día civil en hora de Santo Domingo.
  ///
  /// Antes no filtraba por fecha: devolvía la caja del viernes como «la caja
  /// abierta», la pantalla pintaba su saldo, y al cobrar la base respondía «No
  /// hay una caja abierta para hoy» — la pantalla y la base decían cosas
  /// distintas sobre el mismo hecho.
  Future<Map<String, dynamic>?> _getCajaAbiertaActual() async {
    final response = await supabase
        .from('cajas')
        .select()
        .eq('cerrada', false)
        .eq('fecha_civil', _hoyCivil())
        .limit(1);

    final list = response as List;
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  static String _hoyCivil() {
    final civil = DateTime.now().toUtc().add(_zonaClinica);
    final mes = civil.month.toString().padLeft(2, '0');
    final dia = civil.day.toString().padLeft(2, '0');
    return '${civil.year}-$mes-$dia';
  }
}
