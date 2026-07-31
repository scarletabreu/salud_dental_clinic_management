import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';

abstract class ReglaClinicaRepository {
  /// Reglas no retiradas, en vigor o pendientes de aprobación.
  Future<List<ReglaClinica>> getReglasVigentes();

  /// Catálogo de signos vitales, para acotar los umbrales a lo medible.
  Future<List<SignoVitalCatalogo>> getCatalogoSignosVitales();

  /// Publica una versión nueva de la regla. Devuelve la regla resultante tal
  /// como quedó en la base, no la que la pantalla creía estar enviando.
  Future<ResultadoPublicacion> publicar(ReglaClinica regla, {String? nota});
}

/// Lo que la base confirma tras publicar.
///
/// `sinCambios` distingue "guardado" de "no había nada que guardar": reenviar
/// el formulario sin tocar nada no debe crear una versión nueva, y la pantalla
/// tiene que poder decirlo en vez de fingir un guardado.
class ResultadoPublicacion {
  final String codigo;
  final int version;
  final bool sinCambios;

  const ResultadoPublicacion({
    required this.codigo,
    required this.version,
    required this.sinCambios,
  });
}
