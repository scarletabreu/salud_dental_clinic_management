import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';

class PersonaRepositoryImpl implements PersonaRepository {
  final PersonaRemoteDataSource remoteDataSource;

  PersonaRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Persona>> getPersonas() {
    return runGuarded(
      () => remoteDataSource.fetchActivePersonas(),
      context: 'obtener las personas',
    );
  }

  @override
  Future<List<Persona>> searchPersonas(String query) {
    return runGuarded(
      () => remoteDataSource.searchPersonas(query),
      context: 'buscar personas',
    );
  }

  @override
  Future<Persona> getPersonaById(String id) {
    return runGuarded(
      () => remoteDataSource.fetchPersonaById(id),
      context: 'obtener la persona',
    );
  }

  @override
  Future<Persona> createPersona(Persona persona) {
    return runGuarded(
      () => remoteDataSource.createPersona(_toModel(persona)),
      context: 'crear la persona',
    );
  }

  @override
  Future<void> updatePersona(Persona persona) {
    return runGuarded(
      () => remoteDataSource.updatePersona(_toModel(persona)),
      context: 'actualizar la persona',
    );
  }

  @override
  Future<void> deletePersona(String id) {
    return runGuarded(
      () => remoteDataSource.deactivatePersona(id),
      context: 'eliminar la persona',
    );
  }

  PersonaModel _toModel(Persona persona) {
    return PersonaModel(
      id: persona.id,
      nombre: persona.nombre,
      apellido: persona.apellido,
      birthDate: persona.birthDate,
      govID: persona.govID,
      contactos: persona.contactos,
      estatus: persona.estatus,
    );
  }
}
