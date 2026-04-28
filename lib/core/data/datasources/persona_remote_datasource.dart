import 'package:salud_dental_clinic_management/core/data/models/persona_model.dart';

abstract class PersonaRemoteDataSource {
  Future<List<PersonaModel>> fetchActivePersonas();
  Future<PersonaModel> fetchPersonaById(String id);
  Future<void> createPersona(PersonaModel persona);
  Future<void> updatePersona(PersonaModel persona);
  Future<void> deactivatePersona(String id);
}
