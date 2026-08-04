import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/estado_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/enums/frecuencia_cuota.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/repositories/cuota_repository.dart';

class GenerarPlanDeCuotas {
  final CuotaRepository _repository;

  GenerarPlanDeCuotas(this._repository);

  List<Cuota> previsualizar({
    required Cuenta cuenta,
    required int numCuotas,
    required DateTime fechaPrimera,
    required FrecuenciaCuota frecuencia,
  }) {
    final cuentaId = cuenta.id;
    if (cuentaId == null) {
      throw const ValidationFailure(
        'La cuenta no tiene un identificador válido.',
      );
    }
    if (numCuotas < 2 || numCuotas > 36) {
      throw const ValidationFailure('El plan debe tener entre 2 y 36 cuotas.');
    }

    final saldoCentavos = (cuenta.balancePendiente * 100).round();
    if (saldoCentavos <= 0) {
      throw const ValidationFailure('Esta cuenta ya está saldada.');
    }
    if (saldoCentavos < numCuotas) {
      throw const ValidationFailure(
        'El saldo es demasiado bajo para la cantidad de cuotas elegida.',
      );
    }

    final primera = DateTime(
      fechaPrimera.year,
      fechaPrimera.month,
      fechaPrimera.day,
    );
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    if (primera.isBefore(hoySinHora)) {
      throw const ValidationFailure(
        'La primera fecha de pago no puede estar en el pasado.',
      );
    }

    final baseCentavos = saldoCentavos ~/ numCuotas;
    final ultimoCentavos = saldoCentavos - baseCentavos * (numCuotas - 1);

    return List.generate(numCuotas, (indice) {
      final centavos = indice == numCuotas - 1 ? ultimoCentavos : baseCentavos;
      return Cuota(
        cuentaId: cuentaId,
        monto: centavos / 100,
        fechaVencimiento: frecuencia.fechaDesde(primera, indice),
        estado: EstadoCuota.pendiente,
      );
    });
  }

  Future<List<Cuota>> call({
    required Cuenta cuenta,
    required int numCuotas,
    required DateTime fechaPrimera,
    required FrecuenciaCuota frecuencia,
  }) async {
    final cuotas = previsualizar(
      cuenta: cuenta,
      numCuotas: numCuotas,
      fechaPrimera: fechaPrimera,
      frecuencia: frecuencia,
    );
    await _repository.generarPlanDePagos(cuotas);
    return cuotas;
  }
}
