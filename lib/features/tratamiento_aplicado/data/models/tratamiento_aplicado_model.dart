import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class TratamientoAplicadoModel extends TratamientoAplicado {
  TratamientoAplicadoModel({
    super.id,
    required super.tratamientoId,
    super.tratamientoPadreId,
    required super.esContinuo,
    required super.estaTerminado,
    super.consultaId,
    super.dienteId,
    super.superficie,
    super.precioAplicado,
    super.notas,
    super.estado,
    super.nombreTratamiento,
    super.claveOdontograma,
    super.fechaAplicacion,
  });

  factory TratamientoAplicadoModel.fromJson(Map<String, dynamic> json) {
    final tratamiento = json['tratamiento'];
    final catalogo = tratamiento is Map
        ? Map<String, dynamic>.from(tratamiento)
        : json;
    return TratamientoAplicadoModel(
      id: json['id'] as String?,
      tratamientoId: json['tratamiento_id'] ?? json['tratamientoId'],
      tratamientoPadreId:
          json['tratamiento_padre_id'] ?? json['tratamientoPadreId'],
      esContinuo: json['es_continuo'] ?? json['esContinuo'] ?? false,
      estaTerminado: json['esta_terminado'] ?? json['estaTerminado'] ?? false,
      consultaId: json['consulta_id'] ?? json['consultaId'],
      dienteId: json['diente_id'] ?? json['dienteId'],
      superficie: _parseSuperficie(json['superficie']),
      precioAplicado: _toDouble(
        json['precio_aplicado'] ?? json['precioAplicado'],
      ),
      notas: json['notas'],
      estado: EstadoTratamientoAplicado.values.firstWhere(
        (estado) => estado.name == json['estado'],
        orElse: () => EstadoTratamientoAplicado.aplicado,
      ),
      nombreTratamiento: catalogo['nombre'] as String?,
      claveOdontograma:
          catalogo['clave_odontograma'] as String? ??
          catalogo['claveOdontograma'] as String?,
      fechaAplicacion: _parseFecha(
        json['fecha_aplicacion'] ?? json['created_at'],
      ),
    );
  }

  static double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    return (raw as num).toDouble();
  }

  static DateTime? _parseFecha(dynamic raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  /// El enum `tipo_superficie` en BD es minúscula; el getter `name` del enum
  /// devuelve capitalizado, por eso comparamos sin distinguir mayúsculas.
  static TipoSuperficie? _parseSuperficie(dynamic raw) {
    if (raw == null) return null;
    final valor = raw.toString().toLowerCase();
    for (final tipo in TipoSuperficie.values) {
      if (tipo.name.toLowerCase() == valor) return tipo;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'tratamiento_id': tratamientoId,
      'tratamiento_padre_id': tratamientoPadreId,
      'es_continuo': esContinuo,
      'esta_terminado': estaTerminado,
      'consulta_id': consultaId,
      'diente_id': dienteId,
      // El enum de BD es minúscula.
      'superficie': superficie?.name.toLowerCase(),
      'precio_aplicado': precioAplicado,
      'notas': notas,
      'estado': estado.name,
      'fecha_aplicacion': fechaAplicacion?.toIso8601String(),
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
