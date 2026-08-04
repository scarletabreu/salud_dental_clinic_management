/// Signos vitales estructurados (HFX-CLIN-003).
///
/// Antes eran cinco enteros sueltos: no se sabía en qué unidad llegaban, quién
/// los midió, cuándo ni de dónde salieron, y un valor imposible entraba igual
/// que uno correcto. Ahora cada medición es una fila con su contexto, y los
/// límites que la validan son de posibilidad física —no umbrales clínicos, que
/// viven en `reglas_clinicas` y requieren aprobación del dueño clínico.
library;

/// Espejo de `public.catalogo_signos_vitales`. Si cambia allá, cambia aquí: la
/// pantalla avisa antes de enviar, la base rechaza igual si alguien la saltea.
enum TipoSignoVital {
  presionSistolica('presion_sistolica', 'Presión sistólica', 'mmHg', 30, 300),
  presionDiastolica('presion_diastolica', 'Presión diastólica', 'mmHg', 10, 200),
  pulso('pulso', 'Pulso', 'lpm', 10, 300),
  temperatura('temperatura', 'Temperatura', '°C', 25, 45, decimales: 1),
  saturacionO2('saturacion_o2', 'Saturación de oxígeno', '%', 10, 100),
  frecuenciaRespiratoria(
    'frecuencia_respiratoria',
    'Frecuencia respiratoria',
    'rpm',
    4,
    80,
  ),
  dolor('dolor', 'Dolor referido', '/10', 0, 10),
  peso('peso', 'Peso', 'kg', 0.5, 400, decimales: 1),
  talla('talla', 'Talla', 'cm', 20, 260, decimales: 1);

  const TipoSignoVital(
    this.codigo,
    this.etiqueta,
    this.unidad,
    this.minimoPosible,
    this.maximoPosible, {
    this.decimales = 0,
  });

  final String codigo;
  final String etiqueta;
  final String unidad;
  final double minimoPosible;
  final double maximoPosible;
  final int decimales;

  bool esPosible(num valor) =>
      valor >= minimoPosible && valor <= maximoPosible;

  String get rangoPosible {
    String fmt(double v) => decimales == 0
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(decimales);
    return '${fmt(minimoPosible)}–${fmt(maximoPosible)} $unidad';
  }

  static TipoSignoVital? porCodigo(String codigo) {
    for (final tipo in TipoSignoVital.values) {
      if (tipo.codigo == codigo) return tipo;
    }
    return null;
  }
}

/// De dónde sale el dato. Un valor referido por el paciente no tiene el mismo
/// peso clínico que uno medido en consulta.
enum OrigenSignoVital {
  medido('medido', 'Medido en consulta'),
  referido('referido', 'Referido por el paciente'),
  dispositivo('dispositivo', 'Tomado por un dispositivo');

  const OrigenSignoVital(this.dbValue, this.etiqueta);
  final String dbValue;
  final String etiqueta;

  static OrigenSignoVital porvalor(String? valor) => OrigenSignoVital.values
      .firstWhere((o) => o.dbValue == valor, orElse: () => medido);
}

/// Estado de validación de la medición. `confirmadoPorDoctor` es lo que deja el
/// doctor cuando el valor es extremo pero real.
enum EstadoValidacionSigno {
  valido('valido'),
  confirmadoPorDoctor('confirmado_por_doctor'),
  descartado('descartado');

  const EstadoValidacionSigno(this.dbValue);
  final String dbValue;

  static EstadoValidacionSigno porValor(String? valor) =>
      EstadoValidacionSigno.values.firstWhere(
        (e) => e.dbValue == valor,
        orElse: () => valido,
      );
}

class MedicionSignoVital {
  final String? id;
  final TipoSignoVital tipo;
  final double valor;
  final String unidad;
  final DateTime? medidoEn;
  final String? medidoPor;
  final OrigenSignoVital origen;
  final String? observacion;
  final EstadoValidacionSigno estadoValidacion;

  MedicionSignoVital({
    this.id,
    required this.tipo,
    required this.valor,
    String? unidad,
    this.medidoEn,
    this.medidoPor,
    this.origen = OrigenSignoVital.medido,
    this.observacion,
    this.estadoValidacion = EstadoValidacionSigno.valido,
  }) : unidad = unidad ?? tipo.unidad;

  bool get esPosible => tipo.esPosible(valor);

  String get valorFormateado => tipo.decimales == 0
      ? valor.toStringAsFixed(0)
      : valor.toStringAsFixed(tipo.decimales);

  MedicionSignoVital copyWith({
    String? id,
    double? valor,
    DateTime? medidoEn,
    String? medidoPor,
    OrigenSignoVital? origen,
    String? observacion,
    EstadoValidacionSigno? estadoValidacion,
  }) => MedicionSignoVital(
    id: id ?? this.id,
    tipo: tipo,
    valor: valor ?? this.valor,
    unidad: unidad,
    medidoEn: medidoEn ?? this.medidoEn,
    medidoPor: medidoPor ?? this.medidoPor,
    origen: origen ?? this.origen,
    observacion: observacion ?? this.observacion,
    estadoValidacion: estadoValidacion ?? this.estadoValidacion,
  );

  Map<String, dynamic> toPayload() => {
    'codigo': tipo.codigo,
    'valor': valor,
    'unidad': unidad,
    if (medidoEn != null) 'medido_en': medidoEn!.toUtc().toIso8601String(),
    if (medidoPor != null) 'medido_por': medidoPor,
    'origen': origen.dbValue,
    if (observacion != null && observacion!.trim().isNotEmpty)
      'observacion': observacion!.trim(),
    'estado_validacion': estadoValidacion.dbValue,
  };

  static MedicionSignoVital? fromJson(Map<String, dynamic> json) {
    final tipo = TipoSignoVital.porCodigo(json['codigo'] as String? ?? '');
    final valor = (json['valor'] as num?)?.toDouble();
    if (tipo == null || valor == null) return null;
    return MedicionSignoVital(
      id: json['id'] as String?,
      tipo: tipo,
      valor: valor,
      unidad: json['unidad'] as String?,
      medidoEn: DateTime.tryParse(json['medido_en'] as String? ?? ''),
      medidoPor: json['medido_por'] as String?,
      origen: OrigenSignoVital.porvalor(json['origen'] as String?),
      observacion: json['observacion'] as String?,
      estadoValidacion: EstadoValidacionSigno.porValor(
        json['estado_validacion'] as String?,
      ),
    );
  }
}

/// Un problema de validación previo al envío, con el texto que ve el doctor.
class ProblemaSignoVital {
  final TipoSignoVital? tipo;
  final String mensaje;

  const ProblemaSignoVital({required this.mensaje, this.tipo});

  @override
  String toString() => mensaje;
}

class SignosVitales {
  final List<MedicionSignoVital> mediciones;

  const SignosVitales({this.mediciones = const []});

  /// Construcción desde valores sueltos, que es como los captura el formulario.
  factory SignosVitales.valores({
    num? presionSistolica,
    num? presionDiastolica,
    num? pulso,
    num? temperatura,
    num? saturacionO2,
    num? frecuenciaRespiratoria,
    num? dolor,
    num? peso,
    num? talla,
    OrigenSignoVital origen = OrigenSignoVital.medido,
    DateTime? medidoEn,
    String? medidoPor,
  }) {
    final pares = <TipoSignoVital, num?>{
      TipoSignoVital.presionSistolica: presionSistolica,
      TipoSignoVital.presionDiastolica: presionDiastolica,
      TipoSignoVital.pulso: pulso,
      TipoSignoVital.temperatura: temperatura,
      TipoSignoVital.saturacionO2: saturacionO2,
      TipoSignoVital.frecuenciaRespiratoria: frecuenciaRespiratoria,
      TipoSignoVital.dolor: dolor,
      TipoSignoVital.peso: peso,
      TipoSignoVital.talla: talla,
    };
    return SignosVitales(
      mediciones: [
        for (final par in pares.entries)
          if (par.value != null)
            MedicionSignoVital(
              tipo: par.key,
              valor: par.value!.toDouble(),
              origen: origen,
              medidoEn: medidoEn,
              medidoPor: medidoPor,
            ),
      ],
    );
  }

  bool get estaVacia => mediciones.isEmpty;

  MedicionSignoVital? medicion(TipoSignoVital tipo) {
    for (final m in mediciones) {
      if (m.tipo == tipo) return m;
    }
    return null;
  }

  double? valor(TipoSignoVital tipo) => medicion(tipo)?.valor;

  int? _entero(TipoSignoVital tipo) => valor(tipo)?.round();

  // Accesos históricos: el detalle de consulta y el PDF del expediente los
  // siguen usando y no tienen por qué saber de mediciones.
  int? get presionSistolica => _entero(TipoSignoVital.presionSistolica);
  int? get presionDiastolica => _entero(TipoSignoVital.presionDiastolica);
  int? get pulso => _entero(TipoSignoVital.pulso);
  double? get temperatura => valor(TipoSignoVital.temperatura);
  int? get saturacionO2 => _entero(TipoSignoVital.saturacionO2);

  SignosVitales conMedicion(MedicionSignoVital medicion) => SignosVitales(
    mediciones: [
      for (final m in mediciones)
        if (m.tipo != medicion.tipo) m,
      medicion,
    ],
  );

  SignosVitales sin(TipoSignoVital tipo) =>
      SignosVitales(mediciones: [
        for (final m in mediciones)
          if (m.tipo != tipo) m,
      ]);

  /// Lo que la base rechazaría, dicho antes de enviarlo. Es la misma regla del
  /// servidor: valores imposibles y relaciones imposibles, nada de protocolos.
  List<ProblemaSignoVital> validar() {
    final problemas = <ProblemaSignoVital>[];
    for (final m in mediciones) {
      if (!m.esPosible) {
        problemas.add(
          ProblemaSignoVital(
            tipo: m.tipo,
            mensaje:
                '${m.tipo.etiqueta} ${m.valorFormateado} ${m.unidad} está fuera '
                'del rango físicamente posible (${m.tipo.rangoPosible}).',
          ),
        );
      }
    }

    final sistolica = valor(TipoSignoVital.presionSistolica);
    final diastolica = valor(TipoSignoVital.presionDiastolica);
    if (sistolica != null && diastolica != null && diastolica >= sistolica) {
      problemas.add(
        ProblemaSignoVital(
          tipo: TipoSignoVital.presionDiastolica,
          mensaje:
              'La diastólica (${diastolica.toStringAsFixed(0)}) no puede '
              'igualar ni superar la sistólica '
              '(${sistolica.toStringAsFixed(0)}).',
        ),
      );
    }

    return problemas;
  }

  bool get esValida => validar().isEmpty;

  /// Resumen plano que guarda `consultas.signos_vitales` y leen el detalle y el
  /// PDF. La verdad está en `signos_vitales_consulta`; esto es su proyección.
  Map<String, dynamic> toJson() => {
    for (final m in mediciones) m.tipo.codigo: m.valor,
  };

  List<Map<String, dynamic>> toPayloadMediciones() => [
    for (final m in mediciones) m.toPayload(),
  ];

  /// Acepta tanto el resumen plano histórico (`{"pulso": 80}`) como la lista de
  /// mediciones completas que devuelve el servidor.
  factory SignosVitales.fromJson(Map<String, dynamic> json) {
    final lista = json['mediciones'];
    if (lista is List) {
      return SignosVitales(
        mediciones: [
          for (final fila in lista)
            if (fila is Map<String, dynamic>)
              if (MedicionSignoVital.fromJson(fila) case final m?) m,
        ],
      );
    }

    return SignosVitales(
      mediciones: [
        for (final entrada in json.entries)
          if (TipoSignoVital.porCodigo(entrada.key) case final tipo?)
            if ((entrada.value as num?)?.toDouble() case final valor?)
              MedicionSignoVital(tipo: tipo, valor: valor),
      ],
    );
  }

  factory SignosVitales.fromMediciones(List<Map<String, dynamic>> filas) =>
      SignosVitales(
        mediciones: [
          for (final fila in filas)
            if (MedicionSignoVital.fromJson(fila) case final m?) m,
        ],
      );
}
