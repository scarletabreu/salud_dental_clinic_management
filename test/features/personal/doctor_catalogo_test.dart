import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Filas tal como las devuelve `get_active_doctors()` después de HFX-CLIN-000:
/// sin `password_hash` y con `es_admin`.
List<Map<String, dynamic>> _filas() => [
  {
    'doctor_id': '11111111-1111-1111-1111-111111111111',
    'especialidad': 'Ortodoncia',
    'esta_disponible': true,
    'username': 'bsantana',
    'nombre': 'Bartolomé',
    'apellido': 'Santana',
    'fecha_nacimiento': '1985-03-02',
    'cedula': '402-1234567-1',
    'deleted_at': null,
    'es_admin': false,
  },
  {
    'doctor_id': '22222222-2222-2222-2222-222222222222',
    'especialidad': 'General',
    'esta_disponible': true,
    'username': 'adiaz',
    'nombre': 'Ada',
    'apellido': 'Díaz',
    'fecha_nacimiento': '1979-11-14',
    'cedula': '001-7654321-9',
    'deleted_at': null,
    'es_admin': true,
  },
];

void main() {
  final client = SupabaseClient('https://example.supabase.co', 'test-key');

  DoctorRemoteDatasourceImpl datasource(List<Map<String, dynamic>> filas) =>
      DoctorRemoteDatasourceImpl(
        supabaseClient: client,
        getActiveDoctorsRpc: () async => filas,
      );

  test(
    'el administrador aparece en el catálogo de doctores agendables',
    () async {
      final doctores = await datasource(_filas()).fetchActiveDoctores();

      expect(doctores, hasLength(2));
      expect(
        doctores.map((d) => d.id),
        containsAll(<String>['22222222-2222-2222-2222-222222222222']),
        reason: 'un admin es un doctor: debe poder recibir citas',
      );

      final admin = doctores.firstWhere(
        (d) => d.id == '22222222-2222-2222-2222-222222222222',
      );
      expect(admin.specialty, 'General');
      expect(admin.nombre, 'Ada');
      expect(admin.estatus, EstatusPersona.activo);
    },
  );

  test('el catálogo no trae contraseñas del servidor', () async {
    final doctores = await datasource(_filas()).fetchActiveDoctores();

    expect(doctores, hasLength(2));
    expect(
      _filas(),
      everyElement(isNot(contains('password_hash'))),
      reason: 'la RPC no debe exponer credenciales al catálogo clínico',
    );
  });

  test('un doctor dado de baja llega marcado como inactivo', () async {
    final filas = _filas();
    filas.first['deleted_at'] = '2026-07-01T10:00:00Z';

    final doctores = await datasource(filas).fetchActiveDoctores();

    expect(doctores.first.estatus, EstatusPersona.inactivo);
  });
}
