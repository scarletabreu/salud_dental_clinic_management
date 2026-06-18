import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/repositories/tratamiento_aplicado_repository.dart';

/// Caso de uso: registrar un tratamiento aplicado dentro de una consulta.
///
/// Congela el precio copiando `tratamiento.costo` del catálogo al momento de
/// aplicar, de modo que cambios futuros al catálogo NO alteren cuentas ya
/// emitidas. La suma de `precioAplicado` de una consulta da la pre-factura.
class RegistrarTratamientoAplicado {
  final TratamientoAplicadoRepository _repository;

  RegistrarTratamientoAplicado(this._repository);

  /// [consultaId] consulta a la que pertenece (facturación).
  /// [tratamiento] entrada del catálogo; de aquí se copia el precio.
  /// [dienteId] uuid del diente; `null` = tratamiento general (p. ej. limpieza).
  /// [superficie] superficie concreta del diente, si aplica.
  /// [notas] justificación clínica (HOTFIX-5).
  Future<void> call({
    required String consultaId,
    required Tratamiento tratamiento,
    String? dienteId,
    TipoSuperficie? superficie,
    bool esContinuo = false,
    String? notas,
  }) async {
    final aplicado = TratamientoAplicado(
      tratamientoId: tratamiento.id ?? '',
      esContinuo: esContinuo,
      estaTerminado: false,
      consultaId: consultaId,
      dienteId: dienteId,
      superficie: superficie,
      precioAplicado: tratamiento.costo,
      notas: notas,
    );

    await _repository.realizarTratamiento(aplicado);
  }
}
