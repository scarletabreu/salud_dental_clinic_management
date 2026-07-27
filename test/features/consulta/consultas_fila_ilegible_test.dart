import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_repository_impl.dart';

/// Antes, el listado hacía `.map(ConsultaModel.fromJson)` directo: bastaba una
/// fila con una forma inesperada para que el guard convirtiera el `TypeError`
/// en «Error al obtener las consultas» —sin detalle— y se perdieran todas las
/// consultas legibles. Ahora la fila ilegible se registra y se omite.
class _DatasourceDoble extends Fake implements ConsultaRemoteDatasource {
  _DatasourceDoble(this.filas);

  final List<Map<String, dynamic>> filas;

  @override
  Future<List<Map<String, dynamic>>> fetchConsultas() async => filas;

  @override
  Future<List<Map<String, dynamic>>> fetchConsultasByDoctor(String id) async =>
      filas;
}

Map<String, dynamic> _consultaValida(String id, String fecha) => {
  'id': id,
  'paciente_id': 'dfc57fd2-06bf-47af-b424-61e9187f7c34',
  'doctor_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  'fecha': fecha,
  'motivo_consulta': 'Revisión',
  'temp_condiciones': <String>[],
  'recetas': <Map<String, dynamic>>[],
  'documentos_clinicos': <Map<String, dynamic>>[],
};

void main() {
  tearDown(() => guardConnectivityCheck = null);

  test('una fila ilegible no arrastra a las demás', () async {
    final repo = ConsultaRepositoryImpl(
      remoteDataSource: _DatasourceDoble([
        _consultaValida('c-1', '2026-07-27T11:00:00+00:00'),
        // `fecha` ausente: DateTime.parse(null) lanza dentro del parseo.
        {'id': 'c-rota', 'paciente_id': 'p', 'doctor_id': 'd'},
        _consultaValida('c-2', '2026-07-26T09:00:00+00:00'),
      ]),
    );

    final consultas = await repo.getConsultas();

    expect(consultas.map((c) => c.id), ['c-1', 'c-2']);
  });

  test('getConsultasByDoctor aplica la misma tolerancia', () async {
    final repo = ConsultaRepositoryImpl(
      remoteDataSource: _DatasourceDoble([
        {'id': 'c-rota'},
        _consultaValida('c-3', '2026-07-25T08:00:00+00:00'),
      ]),
    );

    final consultas = await repo.getConsultasByDoctor('doc-1');

    expect(consultas.single.id, 'c-3');
  });

  test('sin filas ilegibles devuelve todo', () async {
    final repo = ConsultaRepositoryImpl(
      remoteDataSource: _DatasourceDoble([
        _consultaValida('c-1', '2026-07-27T11:00:00+00:00'),
        _consultaValida('c-2', '2026-07-26T09:00:00+00:00'),
      ]),
    );

    expect(await repo.getConsultas(), hasLength(2));
  });
}
