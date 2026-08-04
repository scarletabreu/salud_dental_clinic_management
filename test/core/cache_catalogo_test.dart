import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/cache_catalogo.dart';

/// Reloj manejable: la vigencia se prueba moviendo el tiempo, no esperándolo.
class _Reloj {
  DateTime instante = DateTime(2026, 1, 1);
  DateTime call() => instante;
  void avanzar(Duration d) => instante = instante.add(d);
}

void main() {
  group('CacheCatalogo · reutilización de catálogos (SD-132)', () {
    test('la segunda lectura dentro de la vigencia no vuelve a la red', () async {
      var cargas = 0;
      final cache = CacheCatalogo(vigencia: const Duration(minutes: 2));

      Future<List<String>> cargar() async {
        cargas++;
        return ['amoxicilina'];
      }

      expect(await cache.obtener('medicinas', cargar), ['amoxicilina']);
      expect(await cache.obtener('medicinas', cargar), ['amoxicilina']);

      expect(cargas, 1, reason: 'el catálogo debía servirse de memoria');
    });

    test('al vencer la vigencia se vuelve a cargar', () async {
      var cargas = 0;
      final reloj = _Reloj();
      final cache = CacheCatalogo(
        vigencia: const Duration(minutes: 2),
        reloj: reloj.call,
      );

      Future<int> cargar() async => ++cargas;

      await cache.obtener('medicinas', cargar);
      reloj.avanzar(const Duration(minutes: 3));
      await cache.obtener('medicinas', cargar);

      expect(cargas, 2);
    });

    test('varias solicitudes simultáneas comparten una sola carga', () async {
      var cargas = 0;
      final completer = Completer<List<String>>();
      final cache = CacheCatalogo();

      Future<List<String>> cargar() {
        cargas++;
        return completer.future;
      }

      // Las dos secciones de la consulta se montan en el mismo frame.
      final receta = cache.obtener('medicinas', cargar);
      final insumos = cache.obtener('medicinas', cargar);

      completer.complete(['ibuprofeno']);
      await Future.wait([receta, insumos]);

      expect(cargas, 1, reason: 'no debía dispararse una petición por llamador');
    });

    test('invalidar fuerza la recarga tras una escritura', () async {
      var cargas = 0;
      final cache = CacheCatalogo();
      Future<int> cargar() async => ++cargas;

      await cache.obtener('medicinas', cargar);
      cache.invalidar('medicinas');
      await cache.obtener('medicinas', cargar);

      expect(cargas, 2);
    });

    test('un fallo no se guarda: el siguiente intento vuelve a la red', () async {
      var intentos = 0;
      final cache = CacheCatalogo();

      Future<String> cargar() async {
        intentos++;
        if (intentos == 1) throw StateError('sin red');
        return 'ok';
      }

      await expectLater(
        cache.obtener('medicinas', cargar),
        throwsA(isA<StateError>()),
      );
      expect(await cache.obtener('medicinas', cargar), 'ok');
      expect(intentos, 2);
    });

    test('cada catálogo se guarda por separado', () async {
      final cache = CacheCatalogo();

      expect(await cache.obtener('medicinas', () async => 'M'), 'M');
      expect(await cache.obtener('inventario', () async => 'I'), 'I');
      expect(await cache.obtener('medicinas', () async => 'otro'), 'M');
    });
  });
}
