import 'package:salud_dental_clinic_management/core/domain/entities/contacto.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/enums/tipo_suplidor.dart';

class Suplidor {
  final String id;
  final String nombre;
  final TipoSuplidor tipoSuplidor;
  final Contacto contacto;
  final String summary;

  Suplidor({
    required this.id,
    required this.nombre,
    required this.tipoSuplidor,
    required this.contacto,
    required this.summary,
  });

  Suplidor copyWith({
    String? id,
    String? nombre,
    TipoSuplidor? tipoSuplidor,
    Contacto? contacto,
    String? summary,
  }) {
    return Suplidor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoSuplidor: tipoSuplidor ?? this.tipoSuplidor,
      contacto: contacto ?? this.contacto,
      summary: summary ?? this.summary,
    );
  }
}
