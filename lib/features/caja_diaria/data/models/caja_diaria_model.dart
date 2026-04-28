import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';

class CajaDiariaModel extends CajaDiaria {
  CajaDiariaModel({
    required super.id,
    required super.fecha,
    required super.montoApertura,
    required super.montoCierre,
    required super.montoEsperado,
    required super.montoReal,
    required super.cerrada,
  });

  factory CajaDiariaModel.fromJson(Map<String, dynamic> json) {
    return CajaDiariaModel(
      id: json['id'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      montoApertura: (json['montoApertura'] as num).toDouble(),
      montoCierre: (json['montoCierre'] as num).toDouble(),
      montoEsperado: (json['montoEsperado'] as num).toDouble(),
      montoReal: (json['montoReal'] as num).toDouble(),
      cerrada: json['cerrada'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'montoApertura': montoApertura,
      'montoCierre': montoCierre,
      'montoEsperado': montoEsperado,
      'montoReal': montoReal,
      'cerrada': cerrada,
    };
  }
}
