import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/data/models/perfil_actual_mapper.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

/// El login de cada rol pasa por aquí: `perfil_actual()` devuelve una fila
/// plana y este mapper decide qué identidad de dominio nace de ella. Si un rol
/// se traduce mal, la sesión arranca con capacidades que no le tocan.
Map<String, dynamic> _fila({
  required String rol,
  String? especialidad,
  String? departamento,
  String? turno,
  bool conContacto = true,
}) => {
  'id': '11111111-1111-1111-1111-111111111111',
  'rol': rol,
  'nombre': 'Ada',
  'apellido': 'Santana',
  'fecha_nacimiento': '1985-03-02',
  'cedula': '402-1234567-1',
  'estatus': 'activo',
  'username': 'asantana',
  'telefono': conContacto ? '809-555-0134' : null,
  'email': conContacto ? 'ada@clinica.do' : null,
  'direccion': conContacto ? 'Santo Domingo' : null,
  'especialidad': especialidad,
  'esta_disponible': true,
  'departamento': departamento,
  'turno': turno,
};

void main() {
  test('el admin nace como identidad clínica, no sólo administrativa', () {
    final perfil = PerfilActualMapper.desdeFila(
      _fila(rol: 'admin', especialidad: 'Endodoncia', departamento: 'Clínica'),
    );

    expect(perfil, isA<Admin>());
    // La regla del ticket: `Admin extends Doctor` también en tiempo de
    // ejecución, o el admin no podría ejercer.
    expect(perfil, isA<Doctor>());
    expect(perfil!.rol, RolUsuario.admin);
    expect((perfil as Admin).specialty, 'Endodoncia');
    expect(perfil.departamento, 'Clínica');
    expect(perfil.id, '11111111-1111-1111-1111-111111111111');
    expect(perfil.estatus, EstatusPersona.activo);
  });

  test('el doctor nace clínico y sin datos administrativos', () {
    final perfil = PerfilActualMapper.desdeFila(
      _fila(rol: 'doctor', especialidad: 'Ortodoncia'),
    );

    expect(perfil, isA<Doctor>());
    expect(perfil, isNot(isA<Admin>()));
    expect(perfil!.rol, RolUsuario.doctor);
    expect((perfil as Doctor).specialty, 'Ortodoncia');
    expect(perfil.isAvailable, isTrue);
  });

  test('el asistente nace con turno y sin identidad clínica', () {
    final perfil = PerfilActualMapper.desdeFila(
      _fila(rol: 'asistente', turno: 'matutino'),
    );

    expect(perfil, isA<Asistente>());
    expect(perfil, isNot(isA<Doctor>()));
    expect(perfil!.rol, RolUsuario.asistente);
    expect((perfil as Asistente).shift, 'matutino');
  });

  test('un usuario sin perfil operativo no produce sesión', () {
    // `perfil_actual()` filtra a quien no tiene fila de rol; si aun así
    // llegara una fila sin rol, el login no debe inventar una identidad.
    expect(PerfilActualMapper.desdeFila(_fila(rol: 'ninguno')), isNull);
    expect(PerfilActualMapper.desdeFila(const {'rol': null}), isNull);
  });

  test('ningún rol trae contraseña desde el servidor', () {
    for (final rol in const ['admin', 'doctor', 'asistente']) {
      final perfil = PerfilActualMapper.desdeFila(_fila(rol: rol));
      expect(
        perfil!.passwordHash,
        isEmpty,
        reason: 'la RPC no devuelve password_hash y el mapper no lo inventa',
      );
    }
  });

  test('el contacto principal viaja aplanado y no se fabrica si falta', () {
    final conContacto = PerfilActualMapper.desdeFila(_fila(rol: 'doctor'))!;
    expect(conContacto.contactos, hasLength(1));
    expect(conContacto.contactos.single.numeroTelefono, '809-555-0134');
    expect(conContacto.contactos.single.email, 'ada@clinica.do');

    final sinContacto = PerfilActualMapper.desdeFila(
      _fila(rol: 'doctor', conContacto: false),
    )!;
    expect(
      sinContacto.contactos,
      isEmpty,
      reason: 'un contacto vacío se leería en la UI como dato existente',
    );
  });

  test('un perfil inactivo conserva su estatus', () {
    final fila = _fila(rol: 'doctor')..['estatus'] = 'inactivo';
    expect(
      PerfilActualMapper.desdeFila(fila)!.estatus,
      EstatusPersona.inactivo,
    );
  });
}
