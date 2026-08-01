import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auth/data/repositories/usuario_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Defecto D2 (QA 1 ago 2026). La pantalla de Perfiles moría entera —«more than
/// one relationship was found for 'admins' and 'doctores'», o cualquier fila
/// incompleta— y dejaba sin administrar a todo el personal. Ahora lo que falla
/// se convierte en un aviso y el resto se lista igual.
class _DatasourceFalso extends Fake implements UsuarioRemoteDataSource {
  _DatasourceFalso({this.porTabla = const {}, this.errores = const {}});

  final Map<String, List<dynamic>> porTabla;
  final Map<String, Object> errores;
  final selects = <String, String>{};

  @override
  Future<List<dynamic>?> getPerfilesPorTabla({
    required String tabla,
    required String selectColumns,
  }) async {
    selects[tabla] = selectColumns;
    final error = errores[tabla];
    if (error != null) throw error;
    return porTabla[tabla] ?? const [];
  }
}

Map<String, dynamic> _filaDoctor(String id, String nombre) => {
  'id': id,
  'especialidad': 'General',
  'usuarios': {
    'id': id,
    'username': nombre.toLowerCase(),
    'personas': {
      'id': id,
      'nombre': nombre,
      'apellido': 'Apellido',
      'fecha_nacimiento': '1990-01-01',
      'cedula': '001-0000000-0',
      'estatus': 'activo',
      'persona_contactos': const [],
    },
  },
};

void main() {
  test('el embed de admins nombra la restricción para evitar la ambigüedad', () async {
    final datasource = _DatasourceFalso();
    await UsuarioRepositoryImpl(datasource).getUsuarios();

    expect(
      datasource.selects['admins'],
      contains('doctores!admins_id_doctores_fkey'),
      reason:
          'sin la pista de restricción, PostgREST ve dos caminos admins↔doctores '
          '(el directo y el m2m vía auditoria_correcciones_clinicas)',
    );
  });

  test('si falla la lectura de un rol, los demás se listan igual', () async {
    final datasource = _DatasourceFalso(
      porTabla: {
        'doctores': [_filaDoctor('d1', 'Ada')],
      },
      errores: {
        'admins': const PostgrestException(
          message:
              "more than one relationship was found for 'admins' and 'doctores'",
          code: 'PGRST201',
        ),
      },
    );

    final listado = await UsuarioRepositoryImpl(datasource).getUsuarios();

    expect(listado.perfiles.map((u) => u.nombre), ['Ada']);
    expect(listado.avisos, hasLength(1));
    expect(listado.avisos.single.rol, RolUsuario.admin);
    expect(listado.avisos.single.esSeccionCompleta, isTrue);
    expect(
      listado.avisos.single.detalle,
      contains('more than one relationship'),
    );
  });

  test('una fila corrupta se aísla en su propio aviso', () async {
    final datasource = _DatasourceFalso(
      porTabla: {
        'doctores': [
          _filaDoctor('d1', 'Ada'),
          // Sin `personas`: el mapper revienta al leer la fecha de nacimiento.
          {
            'id': 'd2',
            'especialidad': 'General',
            'usuarios': {'id': 'd2', 'username': 'roto'},
          },
          _filaDoctor('d3', 'Beto'),
        ],
      },
    );

    final listado = await UsuarioRepositoryImpl(datasource).getUsuarios();

    expect(listado.perfiles.map((u) => u.nombre), ['Ada', 'Beto']);
    expect(listado.avisos, hasLength(1));
    expect(listado.avisos.single.id, 'd2');
    expect(listado.avisos.single.titulo, 'roto');
    expect(listado.avisos.single.esSeccionCompleta, isFalse);
  });

  test('sin fallos no hay avisos', () async {
    final datasource = _DatasourceFalso(
      porTabla: {
        'doctores': [_filaDoctor('d1', 'Ada')],
      },
    );

    final listado = await UsuarioRepositoryImpl(datasource).getUsuarios();

    expect(listado.perfiles, hasLength(1));
    expect(listado.tieneAvisos, isFalse);
  });
}
