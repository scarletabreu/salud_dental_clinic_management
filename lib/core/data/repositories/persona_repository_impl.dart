import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';

class PersonaRepositoryImpl implements PersonaRepository {
  final PersonaRemoteDataSource remoteDataSource;

  PersonaRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Persona>> getPersonas() async {
    return await remoteDataSource.fetchActivePersonas();
  }

  @override
  Future<Persona> getPersonaById(String id) async {
    return await remoteDataSource.fetchPersonaById(id);
  }

  @override
  Future<void> createPersona(Persona persona) async {
    final model = _toModel(persona);
    await remoteDataSource.createPersona(model);
  }

  @override
  Future<void> updatePersona(Persona persona) async {
    final model = _toModel(persona);
    await remoteDataSource.updatePersona(model);
  }

  @override
  Future<void> deletePersona(String id) async {
    await remoteDataSource.deactivatePersona(id);
  }

  PersonaModel _toModel(Persona persona) {
    return PersonaModel(
      id: persona.id,
      nombre: persona.nombre,
      apellido: persona.apellido,
      birthDate: persona.birthDate,
      govID: persona.govID,
      contacto: persona.contacto,
      estatus: persona.estatus,
    );
  }
}
