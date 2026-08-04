/// Evidencia de la decisión del paciente sobre un plan (HFX-CLIN-003).
///
/// Hasta ahora aceptar un plan era un cambio de estado hecho por el doctor en
/// su pantalla: no quedaba quién decidió, sobre qué versión del plan ni con qué
/// precios. Un consentimiento conserva las cuatro cosas.
library;

enum MetodoConsentimiento {
  verbalPresencial('verbal_presencial', 'Verbal, presencial'),
  firmaFisica('firma_fisica', 'Firma física'),
  firmaDigital('firma_digital', 'Firma digital'),
  telefonico('telefonico', 'Telefónico');

  const MetodoConsentimiento(this.dbValue, this.etiqueta);
  final String dbValue;
  final String etiqueta;

  static MetodoConsentimiento porValor(String? valor) =>
      MetodoConsentimiento.values.firstWhere(
        (m) => m.dbValue == valor,
        orElse: () => verbalPresencial,
      );
}

class ConsentimientoPlan {
  final String? id;
  final String planId;

  /// Versión del plan que el paciente vio. Cambiar actividades o precios sube
  /// la versión y deja este consentimiento sin efecto.
  final int versionPlan;

  final bool aceptado;
  final double totalAceptado;
  final String personaAcepta;

  /// `titular` cuando decide el propio paciente; si no, quién y en qué calidad.
  final String relacionConPaciente;

  final MetodoConsentimiento metodo;
  final String? motivoRechazo;
  final DateTime? fecha;

  const ConsentimientoPlan({
    this.id,
    required this.planId,
    required this.versionPlan,
    required this.aceptado,
    this.totalAceptado = 0,
    required this.personaAcepta,
    this.relacionConPaciente = 'titular',
    this.metodo = MetodoConsentimiento.verbalPresencial,
    this.motivoRechazo,
    this.fecha,
  });

  factory ConsentimientoPlan.fromRpc(Map<String, dynamic> json) =>
      ConsentimientoPlan(
        id: json['consentimiento_id']?.toString(),
        planId: json['plan_id']?.toString() ?? '',
        versionPlan: (json['version_plan'] as num?)?.toInt() ?? 1,
        aceptado: json['decision'] == 'aceptado',
        totalAceptado: (json['total_aceptado'] as num?)?.toDouble() ?? 0,
        personaAcepta: json['persona_acepta']?.toString() ?? '',
        relacionConPaciente:
            json['relacion_con_paciente']?.toString() ?? 'titular',
        metodo: MetodoConsentimiento.porValor(json['metodo']?.toString()),
        motivoRechazo: json['motivo_rechazo']?.toString(),
        fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      );
}
