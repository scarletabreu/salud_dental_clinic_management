/// Alerta emitida por el motor de reglas clínicas (HFX-CLIN-003).
///
/// El sistema no diagnostica: cruza el dato guardado con una regla aprobada y
/// dice qué lo activó, qué severidad tiene y qué acción exige. La decisión
/// clínica sigue siendo del doctor, pero deja de ser silenciosa.
library;

enum SeveridadAlerta {
  informativa('informativa', 'Informativa'),
  advertencia('advertencia', 'Advertencia'),
  critica('critica', 'Crítica'),
  absoluta('absoluta', 'Bloqueante');

  const SeveridadAlerta(this.dbValue, this.etiqueta);
  final String dbValue;
  final String etiqueta;

  static SeveridadAlerta porValor(String? valor) => SeveridadAlerta.values
      .firstWhere((s) => s.dbValue == valor, orElse: () => advertencia);
}

/// Qué se le pide al doctor. Ninguna acción reemplaza su criterio; lo que
/// cambia es si puede seguir sin dejar constancia.
enum AccionAlerta {
  advertir('advertir', 'Advertencia', 'Tenlo presente durante la atención.'),
  confirmar('confirmar', 'Requiere confirmación', 'Confirma que lo revisaste.'),
  documentar(
    'documentar',
    'Requiere acción documentada',
    'Describe qué decidiste y por qué antes de cerrar.',
  ),
  bloquearElectivo(
    'bloquear_electivo',
    'Tratamiento electivo bloqueado',
    'No procede un tratamiento electivo con este hallazgo.',
  ),
  referir(
    'referir',
    'Sugiere referencia',
    'Valora referir o activar el protocolo de emergencia.',
  );

  const AccionAlerta(this.dbValue, this.etiqueta, this.indicacion);
  final String dbValue;
  final String etiqueta;
  final String indicacion;

  /// Una alerta que solo advierte no detiene el cierre; el resto sí, hasta que
  /// quede confirmada o documentada.
  bool get bloqueaCierre => this != AccionAlerta.advertir;

  bool get exigeJustificacion =>
      this == AccionAlerta.documentar ||
      this == AccionAlerta.bloquearElectivo ||
      this == AccionAlerta.referir;

  static AccionAlerta porValor(String? valor) => AccionAlerta.values
      .firstWhere((a) => a.dbValue == valor, orElse: () => advertir);
}

enum EstadoAlerta {
  pendiente('pendiente'),
  confirmada('confirmada'),
  documentada('documentada'),
  obsoleta('obsoleta');

  const EstadoAlerta(this.dbValue);
  final String dbValue;

  static EstadoAlerta porValor(String? valor) => EstadoAlerta.values
      .firstWhere((e) => e.dbValue == valor, orElse: () => pendiente);
}

class AlertaClinica {
  final String id;
  final String reglaCodigo;
  final SeveridadAlerta severidad;
  final AccionAlerta accion;
  final String mensaje;

  /// El dato exacto que la disparó: `{codigo, valor, min, max}` o
  /// `{condicion, codigo, valor}`. Es lo que hace la alerta explicable.
  final Map<String, dynamic> disparador;

  final EstadoAlerta estado;
  final String? justificacion;

  const AlertaClinica({
    required this.id,
    required this.reglaCodigo,
    required this.severidad,
    required this.accion,
    required this.mensaje,
    this.disparador = const {},
    this.estado = EstadoAlerta.pendiente,
    this.justificacion,
  });

  bool get estaPendiente => estado == EstadoAlerta.pendiente;

  bool get bloqueaCierre => estaPendiente && accion.bloqueaCierre;

  AlertaClinica copyWith({EstadoAlerta? estado, String? justificacion}) =>
      AlertaClinica(
        id: id,
        reglaCodigo: reglaCodigo,
        severidad: severidad,
        accion: accion,
        mensaje: mensaje,
        disparador: disparador,
        estado: estado ?? this.estado,
        justificacion: justificacion ?? this.justificacion,
      );

  factory AlertaClinica.fromJson(Map<String, dynamic> json) => AlertaClinica(
    id: json['id'] as String? ?? '',
    reglaCodigo: (json['regla'] ?? json['regla_codigo']) as String? ?? '',
    severidad: SeveridadAlerta.porValor(json['severidad'] as String?),
    accion: AccionAlerta.porValor(json['accion'] as String?),
    mensaje: json['mensaje'] as String? ?? '',
    disparador: (json['disparador'] as Map?)?.cast<String, dynamic>() ?? const {},
    estado: EstadoAlerta.porValor(json['estado'] as String?),
    justificacion: json['justificacion'] as String?,
  );

  static List<AlertaClinica> listaFromJson(Object? valor) {
    if (valor is! List) return const [];
    return [
      for (final fila in valor)
        if (fila is Map) AlertaClinica.fromJson(fila.cast<String, dynamic>()),
    ];
  }
}
