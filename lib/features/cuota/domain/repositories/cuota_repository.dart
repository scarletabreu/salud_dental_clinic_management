import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';

abstract class CuotaRepository {
  /// Lectura pura del plan de cuotas. No escribe nada: cualquier rol con
  /// permiso de SELECT sobre `cuotas` puede llamarla.
  Future<List<Cuota>> getCuotasDeCuenta(String cuentaId);

  /// Consolida en la base el estado «vencida» de las cuotas pasadas de fecha.
  ///
  /// Es una **escritura contable** y la base sólo se la permite a quien tiene
  /// capacidad de caja (admin o asistente). Va aparte de la lectura a
  /// propósito: mezclarlas hacía que abrir el Detalle de Cuenta como doctor
  /// muriera con «Capacidad de caja requerida». Se invoca desde los flujos de
  /// cobro, y allí donde el rol no la tenga se ignora en silencio en vez de
  /// tumbar la operación.
  Future<void> marcarCuotasVencidas(String cuentaId);

  Future<void> generarPlanDePagos(List<Cuota> cuotas);
}
