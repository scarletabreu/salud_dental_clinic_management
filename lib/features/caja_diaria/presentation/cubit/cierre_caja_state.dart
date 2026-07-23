import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/resumen_cierre.dart';

abstract class CierreCajaState extends Equatable {
  const CierreCajaState();
  @override
  List<Object?> get props => [];
}

class CierreCajaInitial extends CierreCajaState {}

class CierreCajaLoading extends CierreCajaState {}

class CierreCajaResumenCargado extends CierreCajaState {
  final ResumenCierre resumen;
  final double montoContado;
  final double diferencia;

  const CierreCajaResumenCargado({
    required this.resumen,
    required this.montoContado,
    required this.diferencia,
  });

  bool get hayDescuadre => diferencia != 0;
  bool get esFaltante => diferencia < 0;

  CierreCajaResumenCargado copyWith({
    ResumenCierre? resumen,
    double? montoContado,
  }) {
    final nuevoResumen = resumen ?? this.resumen;
    final nuevoConteo = montoContado ?? this.montoContado;
    return CierreCajaResumenCargado(
      resumen: nuevoResumen,
      montoContado: nuevoConteo,
      diferencia: nuevoConteo - nuevoResumen.montoEsperado,
    );
  }

  @override
  List<Object?> get props => [resumen, montoContado, diferencia];
}

class CierreCajaConfirmando extends CierreCajaState {}

class CierreCajaExito extends CierreCajaState {
  final ResumenCierre resumen;
  final double montoContado;
  final double diferencia;
  final DateTime fechaCierre;

  const CierreCajaExito({
    required this.resumen,
    required this.montoContado,
    required this.diferencia,
    required this.fechaCierre,
  });

  @override
  List<Object?> get props => [resumen, montoContado, diferencia, fechaCierre];
}

class CierreCajaError extends CierreCajaState {
  final String mensaje;
  const CierreCajaError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}
