import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/shell/lazy_destination_stack.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';

/// Cuenta cuántas veces se ha *creado* su estado y cuántas veces ha construido.
///
/// `creaciones` es la métrica que importa para el arranque: es el número de
/// pantallas que existen de verdad, cada una con su cubit y su petición de red.
class _PantallaEspia extends StatefulWidget {
  const _PantallaEspia({required this.nombre, required this.registro});

  final String nombre;
  final _Registro registro;

  @override
  State<_PantallaEspia> createState() => _PantallaEspiaState();
}

class _Registro {
  final Map<String, int> creaciones = {};
  final Map<String, int> destrucciones = {};
  int get vivas =>
      creaciones.keys
          .where((k) => (creaciones[k] ?? 0) > (destrucciones[k] ?? 0))
          .length;
}

class _PantallaEspiaState extends State<_PantallaEspia> {
  /// Estado local que debe sobrevivir a ir y volver.
  int contador = 0;

  @override
  void initState() {
    super.initState();
    widget.registro.creaciones.update(
      widget.nombre,
      (v) => v + 1,
      ifAbsent: () => 1,
    );
  }

  @override
  void dispose() {
    widget.registro.destrucciones.update(
      widget.nombre,
      (v) => v + 1,
      ifAbsent: () => 1,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Text('${widget.nombre}:$contador', textDirection: TextDirection.ltr),
  );
}

List<ShellDestination> _destinos(_Registro registro, int cuantos) => [
  for (var i = 0; i < cuantos; i++)
    ShellDestination(
      icon: Icons.circle_outlined,
      selectedIcon: Icons.circle,
      label: 'P$i',
      builder: (_) => _PantallaEspia(nombre: 'P$i', registro: registro),
    ),
];

/// Envoltorio que permite cambiar el destino seleccionado como lo hace el shell.
class _Anfitrion extends StatefulWidget {
  const _Anfitrion({required this.destinos, this.maxRetenidas = 4});

  final List<ShellDestination> destinos;
  final int maxRetenidas;

  @override
  State<_Anfitrion> createState() => _AnfitrionState();
}

class _AnfitrionState extends State<_Anfitrion> {
  int indice = 0;

  /// Cambia de destino como lo hace el rail del shell.
  void irA(int destino) => setState(() => indice = destino);

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: LazyDestinationStack(
        destinations: widget.destinos,
        selectedIndex: indice,
        maxRetenidas: widget.maxRetenidas,
      ),
    ),
  );
}

Future<void> _irA(WidgetTester tester, int indice) async {
  tester.state<_AnfitrionState>(find.byType(_Anfitrion)).irA(indice);
  await tester.pumpAndSettle();
}

void main() {
  group('LazyDestinationStack · arranque y navegación (SD-132)', () {
    testWidgets('al arrancar solo existe la pantalla visible', (tester) async {
      final registro = _Registro();
      await tester.pumpWidget(_Anfitrion(destinos: _destinos(registro, 12)));

      expect(
        registro.creaciones.keys.toList(),
        ['P0'],
        reason: 'las otras once pantallas no debían construirse ni pedir datos',
      );
    });

    testWidgets('una pantalla se construye la primera vez que se visita', (
      tester,
    ) async {
      final registro = _Registro();
      await tester.pumpWidget(_Anfitrion(destinos: _destinos(registro, 12)));

      await _irA(tester, 3);

      expect(registro.creaciones['P3'], 1);
      expect(registro.creaciones.containsKey('P5'), isFalse);
    });

    testWidgets('volver a una pantalla retenida no la reconstruye ni pierde su estado', (
      tester,
    ) async {
      final registro = _Registro();
      await tester.pumpWidget(_Anfitrion(destinos: _destinos(registro, 12)));

      // El usuario deja P0 con estado propio (una búsqueda escrita, un scroll).
      tester.state<_PantallaEspiaState>(find.byType(_PantallaEspia)).contador =
          7;

      await _irA(tester, 1);
      await _irA(tester, 0);

      expect(
        registro.creaciones['P0'],
        1,
        reason: 'volver no debía recrear la pantalla ni recargar sus datos',
      );
      expect(find.text('P0:7'), findsOneWidget, reason: 'se perdió el estado');
    });

    testWidgets('pasado el tope se descarta la pantalla usada hace más tiempo', (
      tester,
    ) async {
      final registro = _Registro();
      await tester.pumpWidget(
        _Anfitrion(destinos: _destinos(registro, 12), maxRetenidas: 3),
      );

      await _irA(tester, 1);
      await _irA(tester, 2);
      expect(registro.vivas, 3);

      // La cuarta desaloja a P0, que es la que lleva más tiempo sin usarse.
      await _irA(tester, 3);

      expect(registro.vivas, 3, reason: 'la retención debe estar acotada');
      expect(registro.destrucciones['P0'], 1);
      expect(registro.destrucciones.containsKey('P1'), isFalse);
    });

    testWidgets('una pantalla desalojada se reconstruye al volver a pedirla', (
      tester,
    ) async {
      final registro = _Registro();
      await tester.pumpWidget(
        _Anfitrion(destinos: _destinos(registro, 12), maxRetenidas: 2),
      );

      await _irA(tester, 1);
      await _irA(tester, 2); // desaloja P0
      await _irA(tester, 0);

      expect(registro.creaciones['P0'], 2);
      expect(find.text('P0:0'), findsOneWidget);
    });

    testWidgets('las pantallas retenidas pero ocultas no reciben frames', (
      tester,
    ) async {
      final registro = _Registro();
      await tester.pumpWidget(_Anfitrion(destinos: _destinos(registro, 4)));
      await _irA(tester, 1);

      // P0 sigue viva pero oculta: sus animaciones no deben pedir frames.
      final oculta = tester.element(find.text('P0:0', skipOffstage: false));
      expect(TickerMode.valuesOf(oculta).enabled, isFalse);

      final visible = tester.element(find.text('P1:0'));
      expect(TickerMode.valuesOf(visible).enabled, isTrue);
    });

    testWidgets('un destino que deja de estar permitido se descarta', (
      tester,
    ) async {
      final registro = _Registro();
      final todos = _destinos(registro, 4);

      await tester.pumpWidget(_Anfitrion(destinos: todos));
      await _irA(tester, 1);
      expect(registro.vivas, 2);

      // Cambia el rol: P0 ya no es visible para este usuario.
      await tester.pumpWidget(_Anfitrion(destinos: todos.sublist(1)));
      await tester.pumpAndSettle();

      expect(registro.destrucciones['P0'], 1);
    });
  });
}
