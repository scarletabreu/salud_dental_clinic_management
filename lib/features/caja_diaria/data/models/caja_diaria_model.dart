import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';

class CajaDiariaModel extends CajaDiaria {
  CajaDiariaModel({
    super.id,
    required super.fecha,
    required super.montoApertura,
    required super.montoCierre,
    required super.montoEsperado,
    required super.montoReal,
    required super.cerrada,
  });

  factory CajaDiariaModel.fromJson(Map<String, dynamic> json) {
    return CajaDiariaModel(
      id: json['id'] as String?,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      montoApertura: _monto(json, 'monto_apertura', 'montoApertura'),
      montoCierre: _monto(json, 'monto_cierre', 'montoCierre'),
      montoEsperado: _monto(json, 'monto_esperado', 'montoEsperado'),
      montoReal: _monto(json, 'monto_real', 'montoReal'),
      cerrada: json['cerrada'] as bool? ?? false,
    );
  }

  static double _monto(
    Map<String, dynamic> json,
    String snakeCaseKey,
    String camelCaseKey,
  ) {
    final valor = json[snakeCaseKey] ?? json[camelCaseKey];
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fecha': fecha.toIso8601String(),
      'monto_apertura': montoApertura,
      'monto_cierre': montoCierre,
      'monto_esperado': montoEsperado,
      'monto_real': montoReal,
      'cerrada': cerrada,
    };

    if (id != null && id!.contains('-') && id!.length == 36) {
      data['id'] = id;
    }

    return data;
  }
}
