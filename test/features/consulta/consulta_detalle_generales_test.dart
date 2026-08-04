import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Lo registrado sin pieza —una profilaxis, un raspado de cuadrante— solo lo
/// adjunta `getDetalleConsulta`; el listado de consultas nunca lo trae. Como el
/// detalle recibe la consulta **del listado**, sin esta relectura la pantalla
/// abría una consulta de sola limpieza sin rastro de lo que se hizo.
class _ConsultaRepoDoble implements ConsultaRepository {
  final Consulta? detalle;
  int lecturas = 0;

  _ConsultaRepoDoble(this.detalle);

  @override
  Future<Consulta?> getDetalleConsulta(String id) async {
    lecturas++;
    return detalle;
  }

  @override
  Future<HistorialPiezas> getHistorialPiezas(String pacienteId) async =>
      HistorialPiezas.vacio;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _MedicinaRepoDoble implements IMedicinaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _CitaRepoDoble implements CitaRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Consulta _consulta({
  List<TratamientoAplicado> tratamientos = const [],
  List<DiagnosticoAplicado> diagnosticos = const [],
}) => Consulta(
  id: 'c-1',
  pacienteId: 'p-1',
  doctorId: 'd-1',
  fecha: DateTime(2026, 8, 1),
  tratamientosGenerales: tratamientos,
  diagnosticosGenerales: diagnosticos,
);

TratamientoAplicado _general(String nombre, {DateTime? anuladoEn}) =>
    TratamientoAplicado(
      tratamientoId: 't-cat',
      esContinuo: false,
      estaTerminado: true,
      nombreTratamiento: nombre,
      anuladoEn: anuladoEn,
    );

void main() {
  test('relee la consulta para recuperar lo registrado sin pieza', () async {
    final repo = _ConsultaRepoDoble(
      _consulta(tratamientos: [_general('Profilaxis dental')]),
    );
    final cubit = ConsultaDetalleCubit(
      repo,
      _MedicinaRepoDoble(),
      _CitaRepoDoble(),
    );

    // La consulta que llega del listado viene sin generales, como en producción.
    await cubit.cargar(_consulta());

    expect(repo.lecturas, 1);
    expect((cubit.state as ConsultaDetalleListo).generales, [
      'Profilaxis dental',
    ]);
  });

  test('un general anulado no se cuenta como hecho', () async {
    final repo = _ConsultaRepoDoble(
      _consulta(
        tratamientos: [
          _general('Profilaxis dental'),
          _general('Fluorización', anuladoEn: DateTime(2026, 8, 1)),
        ],
      ),
    );
    final cubit = ConsultaDetalleCubit(
      repo,
      _MedicinaRepoDoble(),
      _CitaRepoDoble(),
    );

    await cubit.cargar(_consulta());

    expect((cubit.state as ConsultaDetalleListo).generales, [
      'Profilaxis dental',
    ]);
  });

  test('si la relectura falla el detalle se muestra igual', () async {
    final cubit = ConsultaDetalleCubit(
      _ConsultaRepoDoble(null),
      _MedicinaRepoDoble(),
      _CitaRepoDoble(),
    );

    await cubit.cargar(_consulta());

    expect(cubit.state, isA<ConsultaDetalleListo>());
    expect((cubit.state as ConsultaDetalleListo).generales, isEmpty);
  });
}
