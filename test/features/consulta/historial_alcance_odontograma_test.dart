import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_repository_impl.dart';

class _DatasourceHistorial implements ConsultaRemoteDatasource {
  final List<Map<String, dynamic>> consultas;
  final Map<String, Map<String, List<Map<String, dynamic>>>> generales;

  _DatasourceHistorial({required this.consultas, required this.generales});

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByPaciente(
    String pacienteId,
  ) async => consultas;

  @override
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
  fetchGeneralesConsultas(List<String> consultaIds) async => generales;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Map<String, dynamic> _tratamiento({
  required String id,
  required String nombre,
  required String alcance,
  String? superficie,
}) => {
  'id': id,
  'tratamiento_id': 'catalogo-$id',
  'consulta_id': 'consulta-1',
  'diente_id': 'diente-16',
  'es_continuo': false,
  'esta_terminado': true,
  'estado': 'aplicado',
  'superficie': superficie,
  'tratamiento': {
    'nombre': nombre,
    'alcance': alcance,
    'clave_odontograma': null,
  },
};

void main() {
  test(
    'el historial adjunta en lote lo general para que llegue al PDF',
    () async {
      final generalHistorico = _tratamiento(
        id: 'ta-blanqueamiento',
        nombre: 'Blanqueamiento dental',
        alcance: 'arcada',
        superficie: 'vestibular',
      );
      final puntual = _tratamiento(
        id: 'ta-reconstruccion',
        nombre: 'Reconstrucción dental',
        alcance: 'puntual',
        superficie: 'oclusal',
      );
      final fila = <String, dynamic>{
        'id': 'consulta-1',
        'paciente_id': 'paciente-1',
        'doctor_id': 'doctor-1',
        'fecha': '2026-07-30T10:00:00Z',
        'odontograma': {
          'id': 'odontograma-1',
          'consulta_id': 'consulta-1',
          'dientes': [
            {
              'id': 'diente-16',
              'odontograma_id': 'odontograma-1',
              'fdi_code': 16,
              'tratamientos_aplicados_ids': [
                'ta-blanqueamiento',
                'ta-reconstruccion',
              ],
              'tratamientos': [generalHistorico, puntual],
              'diagnosis': <Map<String, dynamic>>[],
            },
          ],
        },
      };
      final datasource = _DatasourceHistorial(
        consultas: [fila],
        generales: {
          'consulta-1': {
            'tratamientos': [generalHistorico],
            'diagnosticos': <Map<String, dynamic>>[],
          },
        },
      );

      final historial = await ConsultaRepositoryImpl(
        remoteDataSource: datasource,
      ).getHistorialPaciente('paciente-1');

      final consulta = historial.single;
      expect(
        consulta.tratamientosGenerales.single.nombreTratamiento,
        'Blanqueamiento dental',
      );
      final diente = consulta.odontograma!.dientes.single;
      expect(
        diente.tratamientos.single.nombreTratamiento,
        'Reconstrucción dental',
      );
      expect(diente.tratamientosAplicadosIds, ['ta-reconstruccion']);
    },
  );
}
