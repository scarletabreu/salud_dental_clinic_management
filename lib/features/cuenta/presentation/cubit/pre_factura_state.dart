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

  const PreFacturaCargada(
    this.cuenta, {
    this.cuotas = const [],
    this.consulta,
    this.paciente,
    this.errorDatosRecibo,
  });

  bool get puedeEmitirRecibo => consulta != null && paciente != null;
}

class PreFacturaError extends PreFacturaState {
  final String mensaje;
  const PreFacturaError(this.mensaje);
}
