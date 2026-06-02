import 'package:salud_dental_clinic_management/core/domain/repositories/contacto_repository.dart';
import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/contacto_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

class ContactoRepositoryImpl implements ContactoRepository {
  final ContactoRemoteDataSource remoteDataSource;

  ContactoRepositoryImpl(this.remoteDataSource);

  @override
  Future<Contacto?> getContactoByPersonaId(String personaId) async {
    try {
      return await remoteDataSource.fetchContactoByPersonaId(personaId);
    } catch (e) {
      throw Exception('Error en el repositorio al obtener contacto: $e');
    }
  }

  @override
  Future<void> createContacto(String personaId, Contacto contacto) async {
    try {
      final model = _toModel(contacto);
      await remoteDataSource.createContacto(personaId, model);
    } catch (e) {
      throw Exception('Error en el repositorio al crear contacto: $e');
    }
  }

  @override
  Future<void> updateContacto(Contacto contacto) async {
    try {
      final model = _toModel(contacto);
      await remoteDataSource.updateContacto(model);
    } catch (e) {
      throw Exception('Error en el repositorio al actualizar contacto: $e');
    }
  }

  @override
  Future<void> deleteContacto(String id) async {
    try {
      await remoteDataSource.deleteContacto(id);
    } catch (e) {
      throw Exception('Error en el repositorio al eliminar contacto: $e');
    }
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
