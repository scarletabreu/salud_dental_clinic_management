import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';

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
  const PreFacturaCargada(this.cuenta);
}

class PreFacturaError extends PreFacturaState {
  final String mensaje;
  const PreFacturaError(this.mensaje);
}
