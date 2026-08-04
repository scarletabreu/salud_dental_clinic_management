import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/models/consulta_model.dart';

void main() {
  test('parsea consulta con documento clínico sin fecha_creacion (esquema real)', () {
    // Forma real del embed del listado: documentos_clinicos trae created_at,
    // no fecha_creacion (columna que no existe en la BD).
    final json = {
      'id': '16aa693d-f9d2-46c0-9e63-43a49994d148',
      'paciente_id': 'dfc57fd2-06bf-47af-b424-61e9187f7c34',
      'doctor_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      'cita_id': null,
      'fecha': '2026-06-11T19:52:21+00:00',
      'motivo_consulta': 'Dolor',
      'temp_condiciones': <String>[],
      'recetas': <Map<String, dynamic>>[],
      'documentos_clinicos': [
        {
          'id': '3363469b-21ee-4eac-a61c-6bfe2ce757b3',
          'paciente_id': 'dfc57fd2-06bf-47af-b424-61e9187f7c34',
          'consulta_id': '16aa693d-f9d2-46c0-9e63-43a49994d148',
          'descripcion': 'una-experiencia-espectacular.jpg',
          'tipo_documento': 'radiografia',
          'url_archivo': 'https://example.com/doc.jpg',
          'created_at': '2026-06-11T19:52:21.568714+00:00',
          'deleted_at': null,
          'updated_at': '2026-06-11T19:52:21.568714+00:00',
        },
      ],
      'odontograma': [
        {
          'id': '11111111-2222-3333-4444-555555555555',
          'consulta_id': '16aa693d-f9d2-46c0-9e63-43a49994d148',
          'dientes': [
            {
              'id': '66666666-7777-8888-9999-000000000000',
              'odontograma_id': '11111111-2222-3333-4444-555555555555',
              'fdi_code': 11,
              'observaciones': null,
              'tratamientos_aplicados_ids': null,
            },
          ],
        },
      ],
    };

    final consulta = ConsultaModel.fromJson(json);

    expect(consulta.documentosClinicos, hasLength(1));
    expect(
      consulta.documentosClinicos.first.fechaCreacion,
      DateTime.parse('2026-06-11T19:52:21.568714+00:00'),
    );
    expect(consulta.odontograma?.dientes, hasLength(1));
  });
}
