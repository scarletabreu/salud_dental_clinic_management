import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

/// Sesión abierta para pruebas de widget.
///
/// Desde HFX-QA-103 hay pantallas cuyo contenido depende de quién ha iniciado
/// sesión —los botones del catálogo, los precios, el desplegable de estado de
/// una cita—, así que montarlas sin un `AuthCubit` encima ya no compila el
/// árbol. Antes daba igual porque nadie preguntaba.
class AuthCubitDoble extends Cubit<AuthState> implements AuthCubit {
  AuthCubitDoble(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Usuario usuarioDePrueba(
  RolUsuario rol, {
  String id = 'usuario-de-prueba',
  String nombre = 'Ada',
  String apellido = 'Prueba',
}) {
  final base = (
    id: id,
    nombre: nombre,
    apellido: apellido,
    birthDate: DateTime(1990, 1, 1),
    govID: '001-0000000-0',
    contactos: const <Contacto>[],
    estatus: EstatusPersona.activo,
    username: 'prueba',
  );

  return switch (rol) {
    RolUsuario.admin => Admin(
      id: base.id,
      nombre: base.nombre,
      apellido: base.apellido,
      birthDate: base.birthDate,
      govID: base.govID,
      contactos: base.contactos,
      estatus: base.estatus,
      username: base.username,
      specialty: 'General',
      departamento: 'Dirección',
      assistants: const [],
    ),
    RolUsuario.doctor => Doctor(
      id: base.id,
      nombre: base.nombre,
      apellido: base.apellido,
      birthDate: base.birthDate,
      govID: base.govID,
      contactos: base.contactos,
      estatus: base.estatus,
      username: base.username,
      specialty: 'General',
      assistants: const [],
    ),
    RolUsuario.asistente => Asistente(
      id: base.id,
      nombre: base.nombre,
      apellido: base.apellido,
      birthDate: base.birthDate,
      govID: base.govID,
      contactos: base.contactos,
      estatus: base.estatus,
      username: base.username,
      shift: 'matutino',
    ),
  };
}

/// `AuthCubit` de mentira con la sesión de un rol concreto ya abierta.
AuthCubit sesionDe(RolUsuario rol, {String id = 'usuario-de-prueba'}) =>
    AuthCubitDoble(
      AuthState(isAuthenticated: true, usuario: usuarioDePrueba(rol, id: id)),
    );

/// Provider listo para envolver el widget bajo prueba.
BlocProvider<AuthCubit> proveedorSesion(
  RolUsuario rol, {
  required Widget child,
  String id = 'usuario-de-prueba',
}) => BlocProvider<AuthCubit>(
  create: (_) => sesionDe(rol, id: id),
  child: child,
);
