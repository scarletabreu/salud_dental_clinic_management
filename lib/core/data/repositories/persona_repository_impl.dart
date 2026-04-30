import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';

class PersonaRepositoryImpl implements PersonaRepository {
  final PersonaRemoteDataSource remoteDataSource;

  PersonaRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Persona>> getPersonas() async {
    try {
      return await remoteDataSource.fetchActivePersonas();
    } catch (e) {
      throw Exception('Error en el repositorio al obtener personas: $e');
    }
  }

  @override
  Future<Persona> getPersonaById(String id) async {
    try {
      return await remoteDataSource.fetchPersonaById(id);
    } catch (e) {
      throw Exception('Error en el repositorio al obtener persona por ID: $e');
    }
  }

  @override
  Future<void> createPersona(Persona persona) async {
    try {
      final model = _toModel(persona);
      await remoteDataSource.createPersona(model);
    } catch (e) {
      throw Exception('Error en el repositorio al crear persona: $e');
    }
  }

  @override
  Future<void> updatePersona(Persona persona) async {
    try {
      final model = _toModel(persona);
      await remoteDataSource.updatePersona(model);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar persona: $e');
    }
  }

  @override
  Future<void> deletePersona(String id) async {
    try {
      await remoteDataSource.deactivatePersona(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar persona: $e');
    }
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
