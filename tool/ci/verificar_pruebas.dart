// Ejecuta la suite y la compara con la lista de fallos ya conocidos.
//
// SD-132. El repo arrastra pruebas rojas heredadas de `dev`. Un CI que gatee
// sobre la suite entera nacería en rojo y en dos días nadie lo miraría; uno
// que solo informe no impide nada. La salida es un trinquete, igual que con
// los presupuestos de tamaño: se versiona lo que hoy está roto y CI falla si
// **cambia** ese conjunto.
//
// Falla en dos casos, y los dos importan:
//
//  - Aparece un fallo que no estaba en la lista. Es una regresión.
//  - Una prueba de la lista empieza a pasar. Es una buena noticia, pero hay
//    que quitarla de la lista o dejará de protegernos: si más tarde vuelve a
//    romperse, el trinquete la daría por conocida y callaría.
//
// Uso:
//   dart run tool/ci/verificar_pruebas.dart
//   dart run tool/ci/verificar_pruebas.dart --actualizar   # reescribe la lista

import 'dart:convert';
import 'dart:io';

final _listaConocidos = File('tool/ci/pruebas_conocidas_rojas.txt');

Future<void> main(List<String> args) async {
  final actualizar = args.contains('--actualizar');

  stdout.writeln('→ flutter test');
  final fallos = await _ejecutarSuite();

  if (actualizar) {
    _escribirLista(fallos);
    stdout.writeln('Lista actualizada con ${fallos.length} fallo(s).');
    return;
  }

  final conocidos = _leerLista();
  final nuevos = fallos.difference(conocidos).toList()..sort();
  final arreglados = conocidos.difference(fallos).toList()..sort();

  stdout.writeln();
  stdout.writeln('Fallos: ${fallos.length} · conocidos: ${conocidos.length}');

  if (nuevos.isEmpty && arreglados.isEmpty) {
    stdout.writeln('✓ Sin regresiones. La suite está como se esperaba.');
    return;
  }

  if (nuevos.isNotEmpty) {
    stdout.writeln();
    stdout.writeln('✗ ${nuevos.length} prueba(s) rota(s) por este cambio:');
    for (final t in nuevos) {
      stdout.writeln('    $t');
    }
  }

  if (arreglados.isNotEmpty) {
    stdout.writeln();
    stdout.writeln(
      '✗ ${arreglados.length} prueba(s) de la lista ya pasan. '
      'Quítalas de tool/ci/pruebas_conocidas_rojas.txt para que vuelvan a '
      'estar protegidas:',
    );
    for (final t in arreglados) {
      stdout.writeln('    $t');
    }
    stdout.writeln();
    stdout.writeln('    dart run tool/ci/verificar_pruebas.dart --actualizar');
  }

  exit(1);
}

/// Corre la suite y devuelve los fallos como `ruta/al/test.dart :: nombre`.
Future<Set<String>> _ejecutarSuite() async {
  final proceso = await Process.start('flutter', [
    'test',
    '--reporter=json',
  ], runInShell: true);

  // Los errores de compilación de una suite no llegan como `testDone`; se ven
  // aquí y hundirían la ejecución en silencio si no se mirara.
  proceso.stderr.transform(utf8.decoder).listen(stderr.write);

  final suites = <int, String>{};
  final pruebas = <int, ({String nombre, int suite})>{};
  final fallos = <String>{};

  await for (final linea
      in proceso.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
    if (!linea.startsWith('{')) continue;

    final Map<String, dynamic> evento;
    try {
      evento = jsonDecode(linea) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    switch (evento['type']) {
      case 'suite':
        final s = evento['suite'] as Map<String, dynamic>;
        suites[s['id'] as int] = _relativa(s['path'] as String? ?? '?');

      case 'testStart':
        final t = evento['test'] as Map<String, dynamic>;
        pruebas[t['id'] as int] = (
          nombre: t['name'] as String? ?? '?',
          suite: t['suiteID'] as int? ?? -1,
        );

      case 'testDone':
        if (evento['hidden'] == true) break;
        if (evento['result'] == 'success') break;
        final t = pruebas[evento['testID'] as int];
        if (t == null) break;
        fallos.add('${suites[t.suite] ?? '?'} :: ${_limpiar(t.nombre)}');
    }
  }

  await proceso.exitCode;
  return fallos;
}

/// Las rutas llegan absolutas y cambian de una máquina a otra.
String _relativa(String ruta) {
  final i = ruta.indexOf('/test/');
  return i == -1 ? ruta : ruta.substring(i + 1);
}

/// Una suite que no compila se reporta como `loading <ruta absoluta>`; sin
/// esto, la lista dependería de dónde esté clonado el repo.
String _limpiar(String nombre) =>
    nombre.startsWith('loading ') ? 'loading ${_relativa(nombre.substring(8))}' : nombre;

Set<String> _leerLista() {
  if (!_listaConocidos.existsSync()) return {};
  return _listaConocidos
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty && !l.startsWith('#'))
      .toSet();
}

void _escribirLista(Set<String> fallos) {
  final ordenados = fallos.toList()..sort();
  final entradas = ordenados.isEmpty ? '' : '\n${ordenados.join('\n')}\n';
  _listaConocidos.writeAsStringSync(
    '# Pruebas rojas heredadas, no rotas por el cambio en curso.\n'
    '# Las comprueba tool/ci/verificar_pruebas.dart: CI falla si aparece una\n'
    '# nueva o si alguna de estas empieza a pasar sin quitarla de aquí.\n'
    '#\n'
    '# Regenerar:  dart run tool/ci/verificar_pruebas.dart --actualizar\n'
    '$entradas',
  );
}
