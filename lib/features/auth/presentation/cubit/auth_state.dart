// lib/features/auth/presentation/cubit/auth_state.dart

import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart'; // Tu clase base

class AuthState extends Equatable {
  final bool isAuthenticated;
  final Usuario? usuario; // Aquí cae cualquier modelo hijo

  const AuthState({
    this.isAuthenticated = false,
    this.usuario,
  });

  // El "Secreto" del ticket: Un getter directo para que la UI no tenga que adivinar el rol
  RolUsuario? get rol => usuario?.rol;

  // Estado inicial limpio
  //factory AuthState.initial() => const AuthState();

  //Inicial para development
  factory AuthState.initial() {
    return AuthState(
      isAuthenticated: true, // Forzamos que esté autenticado
      usuario: AdminModel(
        id: 'mock-admin-uuid',
        nombre: 'Desarrollador',
        apellido: 'Local',
        govID: '000-0000000-0',
        contactos: [],
        birthDate: DateTime(2006),
        estatus: EstatusPersona.activo,
        passwordHash: "aura",
        departamento: "dev",
        username: 'admin_dev',
        // Agrega aquí los campos obligatorios adicionales que requiera tu constructor de AdminModel
      ),
    );
  }

  AuthState copyWith({
    bool? isAuthenticated,
    Usuario? usuario,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      usuario: usuario ?? this.usuario,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, usuario];
}