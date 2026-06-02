import "package:salud_dental_clinic_management/core/domain/entities/persona.dart";

abstract class PersonaRepository {
  Future<List<Persona>> getPersonas();

  Future<Persona> getPersonaById(String id);

  Future<Persona> createPersona(Persona persona);

  Future<void> updatePersona(Persona persona);

  Future<void> deletePersona(String id);

  Future<List<Persona>> searchPersonas(String query);

}
