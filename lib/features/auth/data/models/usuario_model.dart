import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

class UsuarioModel extends Usuario {
  UsuarioModel({
    super.id,
    required super.username,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
  });

  @override
  RolUsuario get rol => throw UnimplementedError(
    'El rol debe ser implementado por la clase hija',
  );

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'],
      username: json['username'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      birthDate: DateTime.parse(json['birthDate']),
      govID: json['govID'],
      contactos: _parseContactos(json),
      estatus: json['estatus'],
    );
  }

  static List<ContactoModel> _parseContactos(Map<String, dynamic> json) {
    final raw = json['contactos'];

    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map((item) => ContactoModel.fromJson(item))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      return [ContactoModel.fromJson(raw)];
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'username': username};

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
