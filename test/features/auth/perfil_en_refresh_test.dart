import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// MU-5 · El perfil se recarga al renovarse el token (~1 h): un rol quitado o
/// un usuario desactivado deja de operar en el siguiente refresh, sin
/// necesidad de publicar `usuarios` por realtime. Un fallo transitorio de red
/// durante el refresh NO cierra la sesión.

supabase.Session _sesion(String uuid) => supabase.Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: supabase.User(
    id: uuid,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-08-04T00:00:00Z',
  ),
);

Usuario _admin(String id) => Admin(
  id: id,
  nombre: 'Alma',
  apellido: 'Dirección',
  birthDate: DateTime(1978, 4, 12),
  govID: '402-0000000-1',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: 'alma',
  specialty: 'General',
  assistants: const [],
  departamento: 'Dirección',
);

Usuario _asistente(String id) => Asistente(
  id: id,
  nombre: 'Rita',
  apellido: 'Recepción',
  birthDate: DateTime(1995, 2, 18),
  govID: '402-0000000-2',
  contactos: const <Contacto>[],
  estatus: EstatusPersona.activo,
  username: 'rita',
  shift: 'matutino',
);

class _UsuarioRepoFalso extends Fake implements UsuarioRepository {
  final eventos = StreamController<supabase.AuthState>.broadcast();
  Usuario? perfil;
  Object? errorPerfil;
  int lecturasDePerfil = 0;

  @override
  Stream<supabase.AuthState> get onAuthStateChange => eventos.stream;

  @override
  Future<Usuario?> getPerfilPorUuid(String uuid) async {
    lecturasDePerfil++;
    final e = errorPerfil;
    if (e != null) throw e;
    return perfil;
  }
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late _UsuarioRepoFalso repo;
  late AuthCubit cubit;

  setUp(() {
    repo = _UsuarioRepoFalso()..perfil = _admin('u1');
    cubit = AuthCubit(usuarioRepository: repo);
  });

  tearDown(() async {
    await cubit.close();
    await repo.eventos.close();
  });

  Future<void> emitir(supabase.AuthChangeEvent evento) async {
    repo.eventos.add(supabase.AuthState(evento, _sesion('u1')));
    await _asentar();
  }

  test('un signedIn repetido con el mismo uuid no recarga el perfil',
      () async {
    await emitir(supabase.AuthChangeEvent.signedIn);
    expect(repo.lecturasDePerfil, 1);

    await emitir(supabase.AuthChangeEvent.signedIn);
    expect(repo.lecturasDePerfil, 1, reason: 'mismo uuid: no hay que recargar');
  });

  test('el refresh de token recarga el perfil y propaga el cambio de rol',
      () async {
    await emitir(supabase.AuthChangeEvent.signedIn);
    expect(cubit.state.usuario, isA<Admin>());

    // El dueño le cambió el perfil operativo en otra sesión.
    repo.perfil = _asistente('u1');
    await emitir(supabase.AuthChangeEvent.tokenRefreshed);

    expect(repo.lecturasDePerfil, 2);
    expect(
      cubit.state.usuario,
      isA<Asistente>(),
      reason: 'el rol vigente en la base debe reflejarse tras el refresh',
    );
  });

  test('el usuario desactivado pierde la sesión en el siguiente refresh',
      () async {
    await emitir(supabase.AuthChangeEvent.signedIn);
    expect(cubit.state.isAuthenticated, isTrue);

    repo.perfil = null; // el perfil operativo dejó de resolver
    await emitir(supabase.AuthChangeEvent.tokenRefreshed);

    expect(cubit.state.isAuthenticated, isFalse);
  });

  test('un fallo transitorio durante el refresh no cierra la sesión',
      () async {
    await emitir(supabase.AuthChangeEvent.signedIn);
    expect(cubit.state.isAuthenticated, isTrue);

    repo.errorPerfil = const NetworkFailure();
    await emitir(supabase.AuthChangeEvent.tokenRefreshed);

    expect(
      cubit.state.isAuthenticated,
      isTrue,
      reason: 'una caída de red en el refresh no puede desloguear a nadie',
    );
    expect(cubit.state.usuario, isA<Admin>());
  });
}
