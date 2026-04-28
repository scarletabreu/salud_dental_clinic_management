import 'package:salud_dental_clinic_management/core/data/datasources/contacto_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/contacto_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

class ContactoRepositoryImpl implements ContactoRepository {
  final ContactoRemoteDataSource remoteDataSource;

  ContactoRepositoryImpl(this.remoteDataSource);

  @override
  Future<Contacto?> getContactoByPersonaId(String personaId) async {
    return await remoteDataSource.fetchContactoByPersonaId(personaId);
  }

  @override
  Future<void> createContacto(String personaId, Contacto contacto) async {
    final model = _toModel(contacto);
    await remoteDataSource.createContacto(personaId, model);
  }

  @override
  Future<void> updateContacto(Contacto contacto) async {
    final model = _toModel(contacto);
    await remoteDataSource.updateContacto(model);
  }

  @override
  Future<void> deleteContacto(String id) async {
    await remoteDataSource.deleteContacto(id);
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
