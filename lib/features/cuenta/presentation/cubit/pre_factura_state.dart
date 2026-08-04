import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

sealed class PreFacturaState {
  const PreFacturaState();
}

class PreFacturaInicial extends PreFacturaState {
  const PreFacturaInicial();
}

class PreFacturaCargando extends PreFacturaState {
  const PreFacturaCargando();
}

class PreFacturaCargada extends PreFacturaState {
  final Cuenta cuenta;
  final List<Cuota> cuotas;
  final Consulta? consulta;
  final Paciente? paciente;
  final String? errorDatosRecibo;

  /// ¿Hay caja abierta hoy? (MU-2). `null` cuando no se pudo consultar —rol
  /// sin lectura de caja o fallo puntual—, y en ese caso la pantalla se
  /// comporta como siempre: ofrece cobrar y la base tiene la última palabra
  /// (`tr_validar_pago_caja_abierta`).
  final bool? cajaAbierta;

  const PreFacturaCargada(
    this.cuenta, {
    this.cuotas = const [],
    this.consulta,
    this.paciente,
    this.errorDatosRecibo,
    this.cajaAbierta,
  });

  PreFacturaCargada copyWith({bool? Function()? cajaAbierta}) =>
      PreFacturaCargada(
        cuenta,
        cuotas: cuotas,
        consulta: consulta,
        paciente: paciente,
        errorDatosRecibo: errorDatosRecibo,
        cajaAbierta: cajaAbierta != null ? cajaAbierta() : this.cajaAbierta,
      );

  /// Un recibo necesita a quién se le cobró y qué se le cobró. La consulta no
  /// hace falta: su número vive en la cuenta.
  bool get puedeEmitirRecibo => paciente != null;
}

class PreFacturaError extends PreFacturaState {
  final String mensaje;
  const PreFacturaError(this.mensaje);
}
