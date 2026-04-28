import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';

abstract class ContactoRepository {
  Future<Contacto?> getContactoByPersonaId(String personaId);

  Future<void> createContacto(String personaId, Contacto contacto);

  Future<void> updateContacto(Contacto contacto);

  Future<void> deleteContacto(String id);
}
