import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/data/models/receta_model.dart';

/// La tabla `recetas` convive con dos formatos:
///
///  · el antiguo, una medicina por fila (`titulo`, `dosis`, `medicina_id`…);
///  · el de SD-153, una cabecera con `codigo_receta` y las medicinas dentro
///    del jsonb `items_receta`, donde las columnas antiguas quedan NULL.
///
/// Los casts no-nulos del parser lanzaban `TypeError` con el segundo formato.
/// Como el parseo ocurre dentro del guard del repositorio, una sola fila así
/// dejaba el listado entero de consultas en «Error al obtener las consultas»,
/// sin detalle. Las filas de aquí son las tres que había en la instancia.
///
/// HFX-CLIN-000 actualizó las aserciones al contrato vigente de `Receta`
/// —cabecera con `codigoReceta`, `fechaEmision` e `items`— sin cambiar lo que
/// comprueba cada caso. El único dato que dejó de tener representación es
/// `notas` del formato antiguo: la entidad de SD-153 no lo modela.
void main() {
  group('RecetaModel.fromJson', () {
    test('formato SD-153: columnas antiguas en NULL no revientan', () {
      final receta = RecetaModel.fromJson({
        'id': '9c59bbe1-e3ff-4a93-ab0e-79f1441eb28b',
        'consulta_id': '7b522b9d-bbf2-49ba-a7cd-d6d8d4945d84',
        'titulo': null,
        'title': null,
        'medicina_id': null,
        'dosis': null,
        'frecuencia': null,
        'indicaciones': null,
        'duracion': null,
        'notas': null,
        'created_at': '2026-07-27T11:02:20.659071+00:00',
        'codigo_receta': 'RX-2026-00014',
        'estado': 'activa',
        'items_receta': [
          {
            'dosis': '500mg',
            'duracion': '7 días',
            'frecuencia': 'Cada 8 horas',
            'medicamento_id': null,
          },
        ],
      });

      // El código de receta es el identificador que el doctor reconoce.
      expect(receta.codigoReceta, 'RX-2026-00014');
      expect(receta.items, hasLength(1));
      expect(receta.items.single.dosis, '500mg');
      expect(receta.items.single.medicamentoId, isNull);
      expect(receta.fechaEmision.year, 2026);
    });

    test('formato antiguo se sigue leyendo igual', () {
      final receta = RecetaModel.fromJson({
        'id': '3363469b-21ee-4eac-a61c-6bfe2ce757b3',
        'titulo': 'Amoxicilina 500mg',
        'medicina_id': '7b1c3d4e-a123-4567-8901-000000000000',
        'dosis': '500mg',
        'frecuencia': 'Cada 8 horas',
        'indicaciones': 'Con alimentos',
        'duracion': '7 días',
        'notas': 'Suspender si hay rash',
        'created_at': '2026-06-11T19:52:21.568714+00:00',
      });

      // La fila antigua se lee como una receta de una sola medicina.
      expect(receta.items, hasLength(1));
      final item = receta.items.single;
      expect(item.nombreMedicamento, 'Amoxicilina 500mg');
      expect(item.dosis, '500mg');
      expect(item.frecuencia, 'Cada 8 horas');
      expect(item.indicacionesEspecificas, 'Con alimentos');
      expect(item.duracion, '7 días');
      // Sin `codigo_receta`, el código se deriva del id para que la pantalla
      // nunca muestre una receta sin identificador.
      expect(receta.codigoReceta, 'RX-3363469B');
    });

    test('sin titulo ni codigo_receta la receta queda vacía, no lanza', () {
      final receta = RecetaModel.fromJson({
        'id': 'e72f7832-e915-4337-9322-63b11c811530',
        'created_at': '2026-07-27T04:46:56.919002+00:00',
      });

      expect(receta.items, isEmpty);
      expect(receta.codigoReceta, 'RX-E72F7832');
    });

    test('fecha de emisión ausente no aborta el parseo', () {
      expect(RecetaModel.fromJson({'id': 'x'}).fechaEmision, isA<DateTime>());
    });
  });

  test('una consulta con receta SD-153 embebida se parsea entera', () {
    final consulta = ConsultaModel.fromJson({
      'id': '7b522b9d-bbf2-49ba-a7cd-d6d8d4945d84',
      'paciente_id': 'dfc57fd2-06bf-47af-b424-61e9187f7c34',
      'doctor_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      'cita_id': null,
      'fecha': '2026-07-27T11:02:20+00:00',
      'motivo_consulta': 'Dolor',
      'temp_condiciones': <String>[],
      'documentos_clinicos': <Map<String, dynamic>>[],
      'recetas': [
        {
          'id': '9c59bbe1-e3ff-4a93-ab0e-79f1441eb28b',
          'titulo': null,
          'medicina_id': null,
          'dosis': null,
          'frecuencia': null,
          'indicaciones': null,
          'duracion': null,
          'created_at': '2026-07-27T11:02:20.659071+00:00',
          'codigo_receta': 'RX-2026-00014',
        },
      ],
    });

    expect(consulta.recetas, hasLength(1));
    expect(consulta.recetas.single.codigoReceta, 'RX-2026-00014');
    expect(consulta.tieneRecetas, isTrue);
  });
}
