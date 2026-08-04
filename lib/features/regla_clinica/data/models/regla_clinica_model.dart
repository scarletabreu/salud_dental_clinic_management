import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';

/// Traduce lo que devuelve `reglas_clinicas_vigentes()`.
class ReglaClinicaModel {
  static ReglaClinica fromJson(Map<String, dynamic> json) {
    final tipo = TipoRegla.porValor(json['tipo'] as String?);
    return ReglaClinica(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 1,
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      categoria: json['categoria'] as String? ?? '',
      tipo: tipo,
      parametros: ParametrosRegla.fromJson(
        (json['parametros'] as Map?)?.cast<String, dynamic>(),
      ),
      severidad: SeveridadAlerta.porValor(json['severidad'] as String?),
      accion: AccionAlerta.porValor(json['accion'] as String?),
      estado: EstadoRegla.porValor(json['estado'] as String?),
      fuente: json['fuente'] as String?,
      aprobadaEn: DateTime.tryParse(json['aprobada_en'] as String? ?? ''),
      editable: json['editable'] as bool? ?? false,
    );
  }
}
