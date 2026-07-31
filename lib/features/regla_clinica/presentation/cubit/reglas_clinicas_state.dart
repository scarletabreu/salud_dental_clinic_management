import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';

sealed class ReglasClinicasState {
  const ReglasClinicasState();
}

class ReglasClinicasInicial extends ReglasClinicasState {
  const ReglasClinicasInicial();
}

class ReglasClinicasCargando extends ReglasClinicasState {
  const ReglasClinicasCargando();
}

class ReglasClinicasCargadas extends ReglasClinicasState {
  final List<ReglaClinica> reglas;
  final List<SignoVitalCatalogo> catalogo;

  /// Código de la regla que se está publicando ahora mismo, si la hay. La fila
  /// se bloquea sola en vez de bloquear la pantalla entera: el resto de las
  /// reglas sigue siendo legible mientras una se guarda.
  final String? publicando;

  /// Confirmación de lo último que hizo la base. Se limpia al recargar.
  final String? aviso;

  /// Motivo por el que la base rechazó la última publicación.
  final String? error;

  const ReglasClinicasCargadas({
    required this.reglas,
    required this.catalogo,
    this.publicando,
    this.aviso,
    this.error,
  });

  SignoVitalCatalogo? signo(String? codigo) {
    if (codigo == null) return null;
    for (final s in catalogo) {
      if (s.codigo == codigo) return s;
    }
    return null;
  }

  ReglasClinicasCargadas copyWith({
    List<ReglaClinica>? reglas,
    String? publicando,
    String? aviso,
    String? error,
    bool limpiarPublicando = false,
    bool limpiarMensajes = false,
  }) => ReglasClinicasCargadas(
    reglas: reglas ?? this.reglas,
    catalogo: catalogo,
    publicando: limpiarPublicando ? null : (publicando ?? this.publicando),
    aviso: limpiarMensajes ? null : (aviso ?? this.aviso),
    error: limpiarMensajes ? null : (error ?? this.error),
  );
}

class ReglasClinicasError extends ReglasClinicasState {
  final String mensaje;
  const ReglasClinicasError(this.mensaje);
}
