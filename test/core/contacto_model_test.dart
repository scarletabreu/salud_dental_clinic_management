import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';

void main() {
  test('el JSON de contacto solo lleva columnas de la tabla contactos', () {
    final json = ContactoModel(
      email: 'maria@correo.com',
      numeroTelefono: '8297630729',
      direccion: 'Santiago',
      esEmergencia: true,
    ).toJson();

    // `es_emergencia` pertenece a la tabla puente `persona_contactos`; mandarlo
    // aquí hacía que PostgREST rechazara el insert y no se pudiera registrar un
    // paciente nuevo desde el diálogo de citas.
    expect(json.containsKey('es_emergencia'), isFalse);
    expect(json.keys.toSet(), {'email', 'numero_telefono', 'direccion'});
  });
}
