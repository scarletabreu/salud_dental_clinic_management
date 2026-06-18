import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

class TratamientoAplicado {
  final String? id;
  final String tratamientoId;
  final String? tratamientoPadreId;
  final bool esContinuo;
  final bool estaTerminado;

  /// Consulta a la que pertenece el tratamiento (facturación por consulta).
  final String? consultaId;

  /// Diente donde se aplicó. `null` = tratamiento general (p. ej. limpieza).
  final String? dienteId;

  /// Superficie concreta del diente, si aplica.
  final TipoSuperficie? superficie;

  /// Precio copiado del catálogo al momento de aplicar (congelado).
  final double? precioAplicado;

  /// Justificación clínica del tratamiento (HOTFIX-5).
  final String? notas;

  TratamientoAplicado({
    this.id,
    required this.tratamientoId,
    this.tratamientoPadreId,
    required this.esContinuo,
    required this.estaTerminado,
    this.consultaId,
    this.dienteId,
    this.superficie,
    this.precioAplicado,
    this.notas,
  });

  TratamientoAplicado copyWith({
    String? tratamientoId,
    String? tratamientoPadreId,
    bool? esContinuo,
    bool? estaTerminado,
    String? consultaId,
    String? dienteId,
    TipoSuperficie? superficie,
    double? precioAplicado,
    String? notas,
  }) {
    return TratamientoAplicado(
      id: id,
      tratamientoId: tratamientoId ?? this.tratamientoId,
      tratamientoPadreId: tratamientoPadreId ?? this.tratamientoPadreId,
      esContinuo: esContinuo ?? this.esContinuo,
      estaTerminado: estaTerminado ?? this.estaTerminado,
      consultaId: consultaId ?? this.consultaId,
      dienteId: dienteId ?? this.dienteId,
      superficie: superficie ?? this.superficie,
      precioAplicado: precioAplicado ?? this.precioAplicado,
      notas: notas ?? this.notas,
    );
  }
}
