import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';

/// Fábrica falsa: expone los callbacks de cada canal para que el test pueda
/// simular eventos de tabla y cambios de estado del websocket.
class _FabricaFalsa implements FabricaCanalesSenal {
  final Map<String, void Function()> cambios = {};
  final Map<String, void Function(EstadoCanalSenal)> estados = {};
  final List<String> tablasAbiertas = [];
  int canalesCerrados = 0;

  @override
  CanalSenal abrir(
    String tabla, {
    required void Function() onCambio,
    required void Function(EstadoCanalSenal estado) onEstado,
  }) {
    tablasAbiertas.add(tabla);
    cambios[tabla] = onCambio;
    estados[tabla] = onEstado;
    return _CanalFalso(() => canalesCerrados++);
  }
}

class _CanalFalso implements CanalSenal {
  _CanalFalso(this._alCerrar);
  final void Function() _alCerrar;

  @override
  Future<void> cerrar() async => _alCerrar();
}

void main() {
  const debounce = Duration(milliseconds: 400);

  late _FabricaFalsa fabrica;
  late SenalesRealtime senales;

  setUp(() {
    fabrica = _FabricaFalsa();
    senales = SenalesRealtime(fabrica: fabrica);
  });

  test('abre un canal por cada tabla de cada dominio', () {
    senales.iniciar();

    final esperadas = DominioSenal.values.expand((d) => d.tablas).toList();
    expect(fabrica.tablasAbiertas, esperadas);
    expect(fabrica.tablasAbiertas.length, 8);
  });

  test('un cambio en la tabla emite la señal de su dominio tras el debounce',
      () {
    fakeAsync((async) {
      var recibidas = 0;
      senales.de(DominioSenal.agenda).listen((_) => recibidas++);
      async.flushMicrotasks();

      fabrica.cambios['citas']!();
      expect(recibidas, 0, reason: 'antes del debounce no debe emitir');

      async.elapse(debounce);
      expect(recibidas, 1);
    });
  });

  test('una ráfaga dentro del debounce colapsa en una sola señal', () {
    fakeAsync((async) {
      var recibidas = 0;
      senales.de(DominioSenal.cuentas).listen((_) => recibidas++);
      async.flushMicrotasks();

      for (var i = 0; i < 5; i++) {
        fabrica.cambios['cuentas']!();
        async.elapse(const Duration(milliseconds: 50));
      }
      async.elapse(debounce);

      expect(recibidas, 1);
    });
  });

  test('dos tablas del mismo dominio comparten señal y debounce', () {
    fakeAsync((async) {
      var recibidas = 0;
      senales.de(DominioSenal.pacientes).listen((_) => recibidas++);
      async.flushMicrotasks();

      fabrica.cambios['personas']!();
      fabrica.cambios['pacientes']!();
      async.elapse(debounce);

      expect(recibidas, 1);
    });
  });

  test('un cambio no cruza a dominios ajenos', () {
    fakeAsync((async) {
      var agenda = 0;
      var inventario = 0;
      senales.de(DominioSenal.agenda).listen((_) => agenda++);
      senales.de(DominioSenal.inventario).listen((_) => inventario++);
      async.flushMicrotasks();

      fabrica.cambios['citas']!();
      async.elapse(debounce);

      expect(agenda, 1);
      expect(inventario, 0);
    });
  });

  test('la primera suscripción del canal no dispara recarga', () {
    fakeAsync((async) {
      var recibidas = 0;
      senales.de(DominioSenal.agenda).listen((_) => recibidas++);
      async.flushMicrotasks();

      for (final tabla in fabrica.estados.keys) {
        fabrica.estados[tabla]!(EstadoCanalSenal.suscrito);
      }
      async.elapse(debounce);

      expect(recibidas, 0);
    });
  });

  test('re-suscribirse tras una caída pide recarga en todos los dominios', () {
    fakeAsync((async) {
      final recibidas = <DominioSenal, int>{};
      for (final dominio in DominioSenal.values) {
        recibidas[dominio] = 0;
        senales
            .de(dominio)
            .listen((_) => recibidas[dominio] = recibidas[dominio]! + 1);
      }
      async.flushMicrotasks();

      fabrica.estados['citas']!(EstadoCanalSenal.suscrito);
      fabrica.estados['citas']!(EstadoCanalSenal.caido);
      fabrica.estados['citas']!(EstadoCanalSenal.suscrito);
      async.elapse(debounce);

      for (final dominio in DominioSenal.values) {
        expect(recibidas[dominio], 1,
            reason: 'tras reconectar no se sabe qué se perdió: '
                'todos los dominios deben recargar (${dominio.name})');
      }
    });
  });

  test('recargarTodo emite en todos los dominios, agrupado por el debounce',
      () {
    fakeAsync((async) {
      var agenda = 0;
      senales.de(DominioSenal.agenda).listen((_) => agenda++);
      async.flushMicrotasks();

      senales.recargarTodo();
      senales.recargarTodo();
      async.elapse(debounce);

      expect(agenda, 1);
    });
  });

  test('detener cierra los canales y no emite señales pendientes', () {
    fakeAsync((async) {
      var recibidas = 0;
      senales.de(DominioSenal.agenda).listen((_) => recibidas++);
      async.flushMicrotasks();

      fabrica.cambios['citas']!();
      senales.detener();
      async.elapse(debounce);

      expect(recibidas, 0);
      expect(fabrica.canalesCerrados, 8);
    });
  });
}
