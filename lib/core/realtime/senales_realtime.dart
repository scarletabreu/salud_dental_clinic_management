import 'dart:async';

/// Dominios cuya frescura importa a más de una sesión (plan multiusuario).
///
/// Cada dominio agrupa las tablas cuyo cambio significa «este módulo debe
/// recargar». El recorte por rol no se hace aquí: Realtime aplica las
/// policies RLS de cada tabla, así que a cada sesión sólo le llegan los
/// eventos que su rol puede leer.
enum DominioSenal {
  agenda(['citas']),
  caja(['cajas']),
  cuentas(['cuentas']),
  pacientes(['personas', 'pacientes']),
  inventario(['consumibles']),
  asignaciones(['doctor_asistentes']),
  reglasClinicas(['reglas_clinicas']);

  const DominioSenal(this.tablas);

  /// Tablas de `public` que alimentan el dominio.
  final List<String> tablas;
}

/// Estado observable de un canal de tabla.
enum EstadoCanalSenal { suscrito, caido }

/// Un canal abierto sobre una tabla. Lo único que el servicio necesita de él
/// es poder cerrarlo.
abstract class CanalSenal {
  Future<void> cerrar();
}

/// Fabrica los canales por tabla. Es la costura con Supabase: en producción
/// la implementa [FabricaCanalesSupabase]; los tests inyectan una falsa.
abstract class FabricaCanalesSenal {
  CanalSenal abrir(
    String tabla, {
    required void Function() onCambio,
    required void Function(EstadoCanalSenal estado) onEstado,
  });
}

/// Señales de invalidación por dominio (mecanismo B del plan multiusuario).
///
/// No transporta datos: cuando una tabla del dominio cambia, emite un «algo
/// tuyo cambió, recarga» y el cubit ejecuta su `load()` de siempre, con toda
/// su lógica de filtros y alcances intacta. Un debounce (~400 ms) absorbe las
/// ráfagas: finalizar una consulta escribe en 4-5 tablas seguidas y debe
/// producir una sola recarga por dominio.
///
/// El websocket se cae en silencio (pantalla apagada, cambio de WiFi). El
/// cliente de Supabase reintenta y re-suscribe solo; cuando un canal vuelve
/// a `suscrito` después de una caída, aquí se emite [recargarTodo] porque no
/// hay manera de saber qué se perdió mientras tanto. Si realtime no vuelve,
/// la app se queda como está hoy: datos del último load + refresh manual.
class SenalesRealtime {
  SenalesRealtime({
    required FabricaCanalesSenal fabrica,
    Duration debounce = const Duration(milliseconds: 400),
  }) : _fabrica = fabrica,
       _debounce = debounce;

  final FabricaCanalesSenal _fabrica;
  final Duration _debounce;

  final Map<DominioSenal, StreamController<void>> _emisores = {
    for (final dominio in DominioSenal.values)
      dominio: StreamController<void>.broadcast(),
  };
  final Map<DominioSenal, Timer> _pendientes = {};
  final List<CanalSenal> _canales = [];

  /// Tablas que perdieron el canal y aún no lo recuperan. La primera
  /// suscripción no cuenta como reconexión.
  final Set<String> _tablasCaidas = {};

  bool _iniciado = false;
  bool _detenido = false;

  /// Señal del dominio: emite cuando algo suyo cambió y hay que recargar.
  ///
  /// Abre los canales la primera vez que alguien escucha, lo que en la app
  /// ocurre siempre con una sesión ya autenticada (RLS necesita el JWT).
  Stream<void> de(DominioSenal dominio) {
    iniciar();
    return _emisores[dominio]!.stream;
  }

  /// Abre un canal por tabla. Idempotente.
  void iniciar() {
    if (_iniciado || _detenido) return;
    _iniciado = true;
    for (final dominio in DominioSenal.values) {
      for (final tabla in dominio.tablas) {
        _canales.add(
          _fabrica.abrir(
            tabla,
            onCambio: () => _programar(dominio),
            onEstado: (estado) => _registrarEstado(tabla, estado),
          ),
        );
      }
    }
  }

  /// Pide recarga en todos los dominios. La usan la reconexión y el resume
  /// de la app: cualquier momento en que no sabemos qué nos perdimos.
  void recargarTodo() {
    for (final dominio in DominioSenal.values) {
      _programar(dominio);
    }
  }

  void _registrarEstado(String tabla, EstadoCanalSenal estado) {
    switch (estado) {
      case EstadoCanalSenal.caido:
        _tablasCaidas.add(tabla);
      case EstadoCanalSenal.suscrito:
        if (_tablasCaidas.remove(tabla)) {
          recargarTodo();
        }
    }
  }

  void _programar(DominioSenal dominio) {
    if (_detenido) return;
    _pendientes[dominio]?.cancel();
    _pendientes[dominio] = Timer(_debounce, () {
      _pendientes.remove(dominio);
      final emisor = _emisores[dominio]!;
      if (!emisor.isClosed) emisor.add(null);
    });
  }

  /// Cierra canales y streams. Tras esto el servicio no se puede reusar.
  Future<void> detener() async {
    _detenido = true;
    for (final pendiente in _pendientes.values) {
      pendiente.cancel();
    }
    _pendientes.clear();
    for (final canal in _canales) {
      await canal.cerrar();
    }
    _canales.clear();
    for (final emisor in _emisores.values) {
      await emisor.close();
    }
  }
}
