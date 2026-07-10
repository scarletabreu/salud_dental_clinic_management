import 'package:salud_dental_clinic_management/core/domain/repositories/contacto_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/contacto_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';

class ContactoRepositoryImpl implements ContactoRepository {
  final ContactoRemoteDataSource remoteDataSource;

  ContactoRepositoryImpl(this.remoteDataSource);

  @override
  Future<Contacto?> getContactoByPersonaId(String personaId) {
    return runGuarded(
      () => remoteDataSource.fetchContactoByPersonaId(personaId),
      context: 'obtener el contacto',
    );
  }

  @override
  Future<void> createContacto(String personaId, Contacto contacto) {
    return runGuarded(
      () => remoteDataSource.createContacto(personaId, _toModel(contacto)),
      context: 'crear el contacto',
    );
  }

  @override
  Future<void> updateContacto(Contacto contacto) {
    return runGuarded(
      () => remoteDataSource.updateContacto(_toModel(contacto)),
      context: 'actualizar el contacto',
    );
  }

  @override
  Future<void> deleteContacto(String id) {
    return runGuarded(
      () => remoteDataSource.deleteContacto(id),
      context: 'eliminar el contacto',
    );
  }

  ContactoModel _toModel(Contacto contacto) {
    return ContactoModel(
      id: contacto.id,
      email: contacto.email,
      numeroTelefono: contacto.numeroTelefono,
      direccion: contacto.direccion,
    );
  }
}
