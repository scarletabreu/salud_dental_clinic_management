import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/enums/tipo_suplidor.dart';

class Suplidor {
  final String id;
  final String nombre;
  final TipoSuplidor tipoSuplidor;
  final List<Contacto> contactos;
  final String summary;

  Suplidor({
    required this.id,
    required this.nombre,
    required this.tipoSuplidor,
    required this.contactos,
    required this.summary,
  });

  Suplidor copyWith({
    String? id,
    String? nombre,
    TipoSuplidor? tipoSuplidor,
    List<Contacto>? contactos,
    String? summary,
  }) {
    return Suplidor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoSuplidor: tipoSuplidor ?? this.tipoSuplidor,
      contactos: contactos ?? this.contactos,
      summary: summary ?? this.summary,
    );
  }
}
