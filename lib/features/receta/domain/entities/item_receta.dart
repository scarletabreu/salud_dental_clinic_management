import 'dart:math' as math;

/// Un renglón de la receta (HFX-CLIN-003).
///
/// Dosis, frecuencia y duración eran texto libre: "1 cada 8h por 5 días" y
/// "una cada ocho horas" eran datos distintos para el sistema, nadie podía
/// comprobar si la cantidad despachada alcanzaba, y dos marcas del mismo
/// principio activo pasaban sin ruido. Ahora el renglón lleva sus valores
/// estructurados; los campos de texto se conservan porque el PDF y el detalle
/// los imprimen tal cual.
class ItemReceta {
  final String? id;
  final String? medicamentoId;
  final String nombreMedicamento;

  /// Del catálogo de medicinas. `null` significa "no lo sabemos", y eso es
  /// distinto de "no hay conflicto".
  final String? principioActivo;

  final String presentacionConcentracion;
  final String viaAdministracion;
  final String? indicacionesEspecificas;

  // Renglón estructurado.
  final double? dosisCantidad;
  final String dosisUnidad;
  final double? frecuenciaHoras;
  final int? duracionDias;
  final double? cantidadTotal;

  /// Justificación clínica de este medicamento cuando el paciente tiene una
  /// contraindicación relativa. Es por renglón: una nota general de la receta
  /// no explica por qué se indicó *este* fármaco.
  final String? justificacionRiesgo;

  // Texto tal como se imprime.
  final String dosis;
  final String frecuencia;
  final String duracion;
  final String cantidadIndicada;

  const ItemReceta({
    this.id,
    this.medicamentoId,
    required this.nombreMedicamento,
    this.principioActivo,
    this.presentacionConcentracion = '',
    required this.dosis,
    this.viaAdministracion = 'vía oral',
    required this.frecuencia,
    required this.duracion,
    this.cantidadIndicada = '',
    this.indicacionesEspecificas,
    this.dosisCantidad,
    this.dosisUnidad = '',
    this.frecuenciaHoras,
    this.duracionDias,
    this.cantidadTotal,
    this.justificacionRiesgo,
  });

  /// Construye el renglón desde los valores estructurados y redacta el texto
  /// que se imprime, para que ambos digan siempre lo mismo.
  factory ItemReceta.estructurado({
    String? id,
    String? medicamentoId,
    required String nombreMedicamento,
    String? principioActivo,
    String presentacionConcentracion = '',
    required double dosisCantidad,
    required String dosisUnidad,
    required String viaAdministracion,
    required double frecuenciaHoras,
    required int duracionDias,
    required double cantidadTotal,
    String? indicacionesEspecificas,
    String? justificacionRiesgo,
  }) {
    return ItemReceta(
      id: id,
      medicamentoId: medicamentoId,
      nombreMedicamento: nombreMedicamento,
      principioActivo: principioActivo,
      presentacionConcentracion: presentacionConcentracion,
      viaAdministracion: viaAdministracion,
      indicacionesEspecificas: indicacionesEspecificas,
      justificacionRiesgo: justificacionRiesgo,
      dosisCantidad: dosisCantidad,
      dosisUnidad: dosisUnidad,
      frecuenciaHoras: frecuenciaHoras,
      duracionDias: duracionDias,
      cantidadTotal: cantidadTotal,
      dosis: '${formatearNumero(dosisCantidad)} $dosisUnidad'.trim(),
      frecuencia: 'cada ${formatearNumero(frecuenciaHoras)} horas',
      duracion: '$duracionDias ${duracionDias == 1 ? 'día' : 'días'}',
      cantidadIndicada: '${formatearNumero(cantidadTotal)} $dosisUnidad'.trim(),
    );
  }

  static String formatearNumero(double valor) => valor == valor.roundToDouble()
      ? valor.round().toString()
      : valor.toString();

  bool get estaEstructurado =>
      dosisCantidad != null &&
      dosisCantidad! > 0 &&
      dosisUnidad.trim().isNotEmpty &&
      viaAdministracion.trim().isNotEmpty &&
      frecuenciaHoras != null &&
      frecuenciaHoras! > 0 &&
      duracionDias != null &&
      duracionDias! > 0 &&
      cantidadTotal != null &&
      cantidadTotal! > 0;

  /// Cuántas unidades hacen falta para cumplir la pauta indicada.
  double? get cantidadEsperada {
    final dosis = dosisCantidad;
    final frecuencia = frecuenciaHoras;
    final dias = duracionDias;
    if (dosis == null || frecuencia == null || dias == null) return null;
    if (frecuencia <= 0) return null;
    return (24 / frecuencia).ceil() * dias * dosis;
  }

  /// Misma regla que aplica el servidor al emitir: lo que se despacha tiene que
  /// alcanzar para la pauta y no duplicarla.
  bool get cantidadEsCoherente {
    final esperada = cantidadEsperada;
    final total = cantidadTotal;
    if (esperada == null || total == null) return true;
    return total >= esperada && total <= esperada * 2;
  }

  /// Lo que impediría emitir este renglón, dicho antes de intentarlo.
  List<String> validar() {
    final problemas = <String>[];
    final nombre = nombreMedicamento.trim().isEmpty
        ? 'el medicamento'
        : nombreMedicamento.trim();

    if (dosisCantidad == null || dosisCantidad! <= 0) {
      problemas.add('Falta la dosis de $nombre.');
    }
    if (dosisUnidad.trim().isEmpty) {
      problemas.add('Falta la unidad de la dosis de $nombre.');
    }
    if (viaAdministracion.trim().isEmpty) {
      problemas.add('Falta la vía de administración de $nombre.');
    }
    if (frecuenciaHoras == null ||
        frecuenciaHoras! <= 0 ||
        frecuenciaHoras! > 168) {
      problemas.add('La frecuencia de $nombre debe estar entre 1 y 168 horas.');
    }
    if (duracionDias == null || duracionDias! <= 0 || duracionDias! > 365) {
      problemas.add('La duración de $nombre debe estar entre 1 y 365 días.');
    }
    if (cantidadTotal == null || cantidadTotal! <= 0) {
      problemas.add('Falta la cantidad total a despachar de $nombre.');
    } else if (!cantidadEsCoherente) {
      problemas.add(
        'La cantidad de $nombre (${formatearNumero(cantidadTotal!)}) no cuadra '
        'con la pauta indicada (se esperaban '
        '~${formatearNumero(cantidadEsperada!)}).',
      );
    }
    return problemas;
  }

  /// Clave con la que se detecta la duplicidad: el principio activo cuando el
  /// catálogo lo conoce, y si no, el propio medicamento.
  String get claveDuplicidad {
    final principio = principioActivo?.trim().toLowerCase();
    if (principio != null && principio.isNotEmpty) return 'pa:$principio';
    final id = medicamentoId?.trim();
    if (id != null && id.isNotEmpty) return 'med:$id';
    return 'nom:${nombreMedicamento.trim().toLowerCase()}';
  }

  /// `true` cuando no se puede afirmar nada sobre interacciones porque el
  /// catálogo no tiene el principio activo. No es lo mismo que "sin riesgo".
  bool get informacionInsuficiente =>
      principioActivo == null || principioActivo!.trim().isEmpty;

  /// Renglones que repiten medicamento o principio activo dentro de una receta.
  static List<ItemReceta> duplicados(List<ItemReceta> items) {
    final vistos = <String>{};
    final repetidos = <ItemReceta>[];
    for (final item in items) {
      if (!vistos.add(item.claveDuplicidad)) repetidos.add(item);
    }
    return repetidos;
  }

  /// Cantidad sugerida para la pauta: es lo que la pantalla propone para que el
  /// doctor no tenga que calcularla.
  static double? sugerirCantidad({
    double? dosisCantidad,
    double? frecuenciaHoras,
    int? duracionDias,
  }) {
    if (dosisCantidad == null ||
        frecuenciaHoras == null ||
        duracionDias == null) {
      return null;
    }
    if (dosisCantidad <= 0 || frecuenciaHoras <= 0 || duracionDias <= 0) {
      return null;
    }
    final total = (24 / frecuenciaHoras).ceil() * duracionDias * dosisCantidad;
    return math.max(1, total.ceil()).toDouble();
  }

  ItemReceta copyWith({
    String? id,
    String? medicamentoId,
    String? nombreMedicamento,
    String? principioActivo,
    String? presentacionConcentracion,
    String? dosis,
    String? viaAdministracion,
    String? frecuencia,
    String? duracion,
    String? cantidadIndicada,
    String? indicacionesEspecificas,
    double? dosisCantidad,
    String? dosisUnidad,
    double? frecuenciaHoras,
    int? duracionDias,
    double? cantidadTotal,
    String? justificacionRiesgo,
  }) {
    return ItemReceta(
      id: id ?? this.id,
      medicamentoId: medicamentoId ?? this.medicamentoId,
      nombreMedicamento: nombreMedicamento ?? this.nombreMedicamento,
      principioActivo: principioActivo ?? this.principioActivo,
      presentacionConcentracion:
          presentacionConcentracion ?? this.presentacionConcentracion,
      dosis: dosis ?? this.dosis,
      viaAdministracion: viaAdministracion ?? this.viaAdministracion,
      frecuencia: frecuencia ?? this.frecuencia,
      duracion: duracion ?? this.duracion,
      cantidadIndicada: cantidadIndicada ?? this.cantidadIndicada,
      indicacionesEspecificas:
          indicacionesEspecificas ?? this.indicacionesEspecificas,
      dosisCantidad: dosisCantidad ?? this.dosisCantidad,
      dosisUnidad: dosisUnidad ?? this.dosisUnidad,
      frecuenciaHoras: frecuenciaHoras ?? this.frecuenciaHoras,
      duracionDias: duracionDias ?? this.duracionDias,
      cantidadTotal: cantidadTotal ?? this.cantidadTotal,
      justificacionRiesgo: justificacionRiesgo ?? this.justificacionRiesgo,
    );
  }
}
