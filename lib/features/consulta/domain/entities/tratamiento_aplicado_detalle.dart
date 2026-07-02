import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// Vista de solo lectura de un tratamiento aplicado enriquecido con el nombre
/// del catálogo. El odontograma de la consulta referencia los tratamientos por
/// id (`dientes.tratamientos_aplicados_ids`); este tipo une ese id con su
/// nombre y su precio congelado para poder auditar la consulta.
class TratamientoAplicadoDetalle {
  final String nombre;
  final TratamientoAplicado tratamiento;

  const TratamientoAplicadoDetalle({
    required this.nombre,
    required this.tratamiento,
  });

  double? get precio => tratamiento.precioAplicado;
}
