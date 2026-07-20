import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuota/domain/entities/cuota.dart';

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
  const PreFacturaCargada(this.cuenta, {this.cuotas = const []});
}

class PreFacturaError extends PreFacturaState {
  final String mensaje;
  const PreFacturaError(this.mensaje);
}
