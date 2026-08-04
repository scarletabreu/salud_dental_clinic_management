import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/metodo_pago.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/domain/entities/item_cuenta.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/exceptions/cuenta_exception.dart';

class Cuenta {
  final String? id;
  final String consultaId;

  /// Paciente al que se le factura. La columna existe en `cuentas` desde la
  /// reconciliación con producción, pero el modelo no la leía: por eso el
  /// listado de Cuentas por Cobrar sólo podía titularse con el id de la
  /// consulta.
  final String? pacienteId;
  final DateTime fechaCreacion;
  final DateTime? fechaPago;
  final MetodoPago metodoPago;
  final List<Pago> pagos;
  final String? nota;
  final EstadoCuenta estado;
  final List<ItemCuenta> itemCuentas;

  Cuenta({
    this.id,
    required this.consultaId,
    this.pacienteId,
    required this.fechaCreacion,
    this.fechaPago,
    required this.metodoPago,
    this.pagos = const [],
    this.nota,
    this.estado = EstadoCuenta.abierta,
    this.itemCuentas = const [],
  });

  /// Fuente de verdad: itemCuentas (persistidas). Solo lookup.
  double get montoTotal =>
      itemCuentas.fold(0.0, (sum, item) => sum + item.precioTotal);

  /// Fuente de verdad: tabla `pagos`. Este getter es solo lookup en memoria,
  /// nunca se persiste como columna aparte.
  double get montoPagado => pagos.fold(0.0, (sum, pago) => sum + pago.monto);

  double get balancePendiente => montoTotal - montoPagado;

  // NOTA: se elimina `estadoCuenta` (getter derivado). El campo `estado`
  // es ahora la ÚNICA fuente de verdad del estado de la cuenta, mutado
  // exclusivamente por emitirFactura/cerrarCuenta/cancelar. Los tres
  // consumidores que usaban estadoCuenta deben migrar a leer `estado`.

  Cuenta copyWith({
    String? consultaId,
    DateTime? fechaCreacion,
    DateTime? fechaPago,
    MetodoPago? metodoPago,
    List<Pago>? pagos,
    String? nota,
    EstadoCuenta? estado,
    List<ItemCuenta>? itemCuentas,
  }) {
    return Cuenta(
      id: id,
      consultaId: consultaId ?? this.consultaId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaPago: fechaPago ?? this.fechaPago,
      metodoPago: metodoPago ?? this.metodoPago,
      pagos: pagos ?? List.from(this.pagos),
      itemCuentas: itemCuentas ?? List.from(this.itemCuentas),
      estado: estado ?? this.estado,
      nota: nota ?? this.nota,
    );
  }

  /// ABIERTA -> PENDIENTE
  Cuenta emitirFactura({
    required MetodoPago modoPago,
    required TipoPaciente tipoPaciente,
  }) {
    if (estado != EstadoCuenta.abierta) {
      throw TransicionInvalidaException(estado, EstadoCuenta.pendiente);
    }
    if (tipoPaciente == TipoPaciente.emergencia &&
        modoPago != MetodoPago.contado) {
      throw ModoPagoNoPermitidoException();
    }
    return copyWith(estado: EstadoCuenta.pendiente, metodoPago: modoPago);
  }

  /// Descuento/cargo, requiere autorización de doctor. No cambia estado
  /// ni montos: solo deja constancia en nota (enhance futuro: tabla propia).
  Cuenta aplicarAjuste({
    required double monto,
    required String motivo,
    required String? doctorAutorizaId,
  }) {
    if (estado == EstadoCuenta.saldada || estado == EstadoCuenta.cancelada) {
      throw TransicionInvalidaException(estado, estado);
    }
    if (doctorAutorizaId == null || doctorAutorizaId.isEmpty) {
      throw AjusteRequiereAutorizacionException();
    }
    final notaActualizada =
        '${nota ?? ''}\n[Ajuste ${monto >= 0 ? '+' : ''}$monto por '
                '$doctorAutorizaId] $motivo'
            .trim();
    return copyWith(nota: notaActualizada);
  }

  /// PENDIENTE -> SALDADO
  Cuenta cerrarCuenta() {
    if (estado != EstadoCuenta.pendiente) {
      throw TransicionInvalidaException(estado, EstadoCuenta.saldada);
    }
    if (montoPagado < montoTotal) {
      throw SaldoInsuficienteException();
    }
    return copyWith(estado: EstadoCuenta.saldada, fechaPago: DateTime.now());
  }

  /// ABIERTA/PENDIENTE -> CANCELADA
  Cuenta cancelar({required String motivo}) {
    if (estado == EstadoCuenta.saldada || estado == EstadoCuenta.cancelada) {
      throw TransicionInvalidaException(estado, EstadoCuenta.cancelada);
    }
    return copyWith(
      estado: EstadoCuenta.cancelada,
      nota: '${nota ?? ''}\n[Cancelada] $motivo'.trim(),
    );
  }
}
