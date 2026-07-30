import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/capacidades_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/admin.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

/// Contrato de capacidades de HFX-CLIN-000.
///
/// Antes las pantallas preguntaban `rol == RolUsuario.doctor`, y eso dejaba al
/// administrador fuera de todo lo clínico aunque el dominio lo declare
/// `Admin extends Doctor`. Estas pruebas fijan la tabla acordada con la clínica
/// y, sobre todo, la distinción que más fácil se pierde: ver la agenda de todos
/// no es poder firmar por todos.
Admin _admin({String id = 'admin-1'}) => Admin(
  id: id,
  nombre: 'Ada',
  apellido: 'Directora',
  birthDate: DateTime(1980),
  govID: '001',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'ada',
  passwordHash: '',
  assistants: const [],
  specialty: 'Ortodoncia',
  departamento: 'Dirección',
);

Doctor _doctor({String id = 'doctor-1'}) => Doctor(
  id: id,
  nombre: 'Beto',
  apellido: 'Clínico',
  birthDate: DateTime(1985),
  govID: '002',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'beto',
  passwordHash: '',
  assistants: const [],
  specialty: 'Endodoncia',
);

Asistente _asistente({String id = 'asistente-1'}) => Asistente(
  id: id,
  nombre: 'Cami',
  apellido: 'Recepción',
  birthDate: DateTime(1998),
  govID: '003',
  contactos: const [],
  estatus: EstatusPersona.activo,
  username: 'cami',
  passwordHash: '',
  shift: 'matutino',
);

void main() {
  group('capacidades por rol', () {
    test('el administrador ejerce clínica igual que el doctor', () {
      expect(RolUsuario.admin.tiene(Capacidad.ejercerClinica), isTrue);
      expect(RolUsuario.doctor.tiene(Capacidad.ejercerClinica), isTrue);
      expect(RolUsuario.asistente.tiene(Capacidad.ejercerClinica), isFalse);
    });

    test('el asistente no firma actuaciones ni ve expedientes', () {
      expect(RolUsuario.asistente.tiene(Capacidad.firmarActuacionPropia), isFalse);
      expect(RolUsuario.asistente.tiene(Capacidad.verExpedientes), isFalse);
    });

    test('la agenda completa y la caja son de admin y asistente', () {
      for (final capacidad in [
        Capacidad.gestionarAgendaCompleta,
        Capacidad.gestionarCaja,
        Capacidad.verDatosDeContactoPaciente,
      ]) {
        expect(RolUsuario.admin.tiene(capacidad), isTrue, reason: '$capacidad');
        expect(RolUsuario.asistente.tiene(capacidad), isTrue,
            reason: '$capacidad');
        expect(RolUsuario.doctor.tiene(capacidad), isFalse,
            reason: '$capacidad');
      }
    });

    test('los tres roles pueden registrar llegada y emergencia', () {
      for (final rol in RolUsuario.values) {
        expect(rol.tiene(Capacidad.registrarLlegada), isTrue);
        expect(rol.tiene(Capacidad.registrarEmergencia), isTrue);
      }
    });

    test('administrar personal y corregir lo ajeno son sólo del admin', () {
      for (final capacidad in [
        Capacidad.administrarPersonal,
        Capacidad.corregirRegistroAjeno,
        Capacidad.accederACompras,
      ]) {
        expect(RolUsuario.admin.tiene(capacidad), isTrue, reason: '$capacidad');
        expect(RolUsuario.doctor.tiene(capacidad), isFalse,
            reason: '$capacidad');
        expect(RolUsuario.asistente.tiene(capacidad), isFalse,
            reason: '$capacidad');
      }
    });
  });

  group('capacidades de la sesión', () {
    test('el admin puede atender la cita asignada a su propio UUID', () {
      final estado = AuthState(isAuthenticated: true, usuario: _admin());
      expect(estado.puedeAtenderCitaDe('admin-1'), isTrue);
    });

    test('el admin no puede firmar la cita de otro doctor', () {
      final estado = AuthState(isAuthenticated: true, usuario: _admin());
      // Ve toda la agenda…
      expect(estado.puedeGestionarAgendaCompleta, isTrue);
      // …pero eso no lo autoriza a firmar por otro.
      expect(estado.puedeAtenderCitaDe('doctor-1'), isFalse);
    });

    test('el doctor sólo atiende sus propias citas', () {
      final estado = AuthState(isAuthenticated: true, usuario: _doctor());
      expect(estado.puedeAtenderCitaDe('doctor-1'), isTrue);
      expect(estado.puedeAtenderCitaDe('doctor-2'), isFalse);
      expect(estado.puedeGestionarAgendaCompleta, isFalse);
    });

    test('el asistente no puede iniciar una consulta ni siendo la suya', () {
      final estado = AuthState(isAuthenticated: true, usuario: _asistente());
      expect(estado.puedeEjercerClinica, isFalse);
      expect(estado.puedeAtenderCitaDe('asistente-1'), isFalse);
    });

    test('una cita sin doctor asignado no la atiende nadie', () {
      final estado = AuthState(isAuthenticated: true, usuario: _admin());
      expect(estado.puedeAtenderCitaDe(null), isFalse);
    });

    test('sin sesión no hay ninguna capacidad', () {
      const estado = AuthState();
      expect(estado.puedeEjercerClinica, isFalse);
      expect(estado.puedeGestionarAgendaCompleta, isFalse);
      expect(estado.puedeAtenderCitaDe('admin-1'), isFalse);
    });

    test('el filtro de agenda distingue quién la gestiona de quién ejerce', () {
      // Admin y asistente ven la agenda entera: sin restricción por doctor.
      expect(
        AuthState(isAuthenticated: true, usuario: _admin())
            .doctorIdParaFiltrarAgenda,
        isNull,
      );
      expect(
        AuthState(isAuthenticated: true, usuario: _asistente())
            .doctorIdParaFiltrarAgenda,
        isNull,
      );
      // El doctor ve la suya.
      expect(
        AuthState(isAuthenticated: true, usuario: _doctor())
            .doctorIdParaFiltrarAgenda,
        'doctor-1',
      );
    });
  });
}
