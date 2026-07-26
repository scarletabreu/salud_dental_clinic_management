import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';

/// Contenedor de las pantallas del shell: las construye la primera vez que se
/// visitan y conserva vivas solo las últimas [maxRetenidas].
///
/// El shell había pasado por los dos extremos y ninguno servía:
///
/// - Con un `IndexedStack` sobre *todos* los destinos, entrar a la app
///   construía las doce pantallas de un admin de golpe: doce cubits, doce
///   consultas a Supabase y doce árboles en memoria antes de que nadie tocara
///   nada. Eso es el arranque lento en gama baja.
/// - Con un `KeyedSubtree` sobre el destino seleccionado ocurría lo contrario:
///   salir de una pantalla la destruía junto con su cubit, así que volver a
///   ella recargaba todo desde la red. Es la recarga al navegar que se
///   reporta como lentitud.
///
/// Aquí se paga la construcción una sola vez, en el momento en que el usuario
/// pide la pantalla, y volver es gratis. La retención es acotada a propósito:
/// conservarlo *todo* para siempre convierte el problema de CPU en uno de
/// memoria, que en un teléfono de gama baja termina en muerte por el
/// low-memory killer. Al pasarse del tope se descarta la pantalla usada hace
/// más tiempo, que es la que menos probablemente se vuelva a pedir.
///
/// Las pantallas retenidas pero no visibles quedan con [TickerMode] apagado:
/// sin eso, cada `AnimatedContainer` o spinner de una pantalla oculta seguiría
/// pidiendo frames y gastando CPU sin que nadie lo vea.
class LazyDestinationStack extends StatefulWidget {
  const LazyDestinationStack({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    this.maxRetenidas = 4,
  });

  final List<ShellDestination> destinations;
  final int selectedIndex;

  /// Cuántas pantallas se conservan vivas a la vez, incluida la visible.
  ///
  /// Cuatro cubre el ida y vuelta real de una jornada (agenda → paciente →
  /// consulta → cuenta) sin sostener el árbol entero.
  final int maxRetenidas;

  @override
  State<LazyDestinationStack> createState() => _LazyDestinationStackState();
}

class _LazyDestinationStackState extends State<LazyDestinationStack> {
  /// Etiquetas vivas, de la usada hace más tiempo a la más reciente. El orden
  /// *es* la política de descarte, por eso es una lista y no un `Set`.
  final List<String> _vivas = <String>[];

  @override
  void initState() {
    super.initState();
    _registrarVisita();
  }

  @override
  void didUpdateWidget(LazyDestinationStack old) {
    super.didUpdateWidget(old);
    _registrarVisita();
  }

  /// Marca la pantalla actual como la más reciente y descarta las sobrantes.
  ///
  /// Se llama desde `initState`/`didUpdateWidget` y no desde `build` para no
  /// mutar estado mientras se construye el árbol.
  void _registrarVisita() {
    final destinos = widget.destinations;
    if (destinos.isEmpty) return;
    final indice = widget.selectedIndex;
    if (indice < 0 || indice >= destinos.length) return;

    final actual = destinos[indice].label;
    _vivas
      ..remove(actual)
      ..add(actual);

    // Un destino que dejó de ser visible —cambió el rol— no debe seguir
    // ocupando cupo ni memoria.
    final visibles = destinos.map((d) => d.label).toSet();
    _vivas.removeWhere((label) => !visibles.contains(label));

    final tope = widget.maxRetenidas < 1 ? 1 : widget.maxRetenidas;
    while (_vivas.length > tope) {
      _vivas.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinos = widget.destinations;
    if (destinos.isEmpty) return const SizedBox.shrink();

    final indice = widget.selectedIndex.clamp(0, destinos.length - 1);

    return IndexedStack(
      index: indice,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < destinos.length; i++)
          _ranura(context, destinos[i], visible: i == indice),
      ],
    );
  }

  Widget _ranura(
    BuildContext context,
    ShellDestination destino, {
    required bool visible,
  }) {
    // Nunca visitada, o descartada por el tope: hueco vacío. No hay cubit ni
    // petición de red detrás de esto.
    if (!_vivas.contains(destino.label)) {
      return const SizedBox.shrink();
    }

    // La clave va por etiqueta y no por posición: cuando cambian los roles la
    // lista se reordena, y sin esto Flutter emparejaría cada estado con la
    // pantalla equivocada.
    return KeyedSubtree(
      key: ValueKey<String>(destino.label),
      child: TickerMode(
        enabled: visible,
        child: Builder(builder: destino.builder),
      ),
    );
  }
}
