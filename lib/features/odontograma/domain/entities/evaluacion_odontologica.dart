import 'package:flutter/painting.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Tintas del formulario en papel, tal como se imprimen. Los doctores solo
/// escriben en rojo y azul; el negro queda reservado para estados acordados
/// fuera de las claves.
const Color kTintaRoja = Color(0xFFC81E1E);
const Color kTintaAzul = Color(0xFF1D4ED8);
const Color kTintaNegra = Color(0xFF1F2937);

/// Qué tinta usa una clave. El dato clínico es *cuál* de las tres, no el valor
/// RGB: sobre papel oscuro esas mismas tintas se dibujan con otra luminancia
/// para seguir siendo legibles sin dejar de ser «la roja» y «la azul».
enum TintaClinica { roja, azul, negra }

extension TintaClinicaX on TintaClinica {
  Color get impresa => switch (this) {
    TintaClinica.roja => kTintaRoja,
    TintaClinica.azul => kTintaAzul,
    TintaClinica.negra => kTintaNegra,
  };
}

/// Trazo con el que se dibuja un hallazgo sobre el glifo del diente. Reproduce
/// la columna de símbolos de las CLAVES del formulario.
enum MarcaClinica {
  /// Superficie sombreada por completo (Cariada, Restaurada).
  relleno,

  /// Rayado diagonal `///` (Extracción indicada).
  rayado,

  /// Aspa `X` sobre la pieza (Pérdida).
  equis,

  /// Círculo con punto central `⊙` (Pulpectomía · Pulpotomía).
  circuloPunto,

  /// Guion `-` atravesando la pieza (No erupcionado).
  guion,

  /// Asterisco para los estados acordados que no están en el papel.
  asterisco,
}

/// Claves del formulario físico, en su orden y con su redacción original.
enum EstadoClinicoDental {
  cariada,
  restaurada,
  extraccionIndicada,
  perdida,
  pulpectomiaPulpotomia,
  noErupcionado,
  otro,
}

extension EstadoClinicoDentalX on EstadoClinicoDental {
  String get dbValue => switch (this) {
    EstadoClinicoDental.cariada => 'cariada',
    EstadoClinicoDental.restaurada => 'restaurada',
    EstadoClinicoDental.extraccionIndicada => 'extraccion_indicada',
    EstadoClinicoDental.perdida => 'perdida',
    EstadoClinicoDental.pulpectomiaPulpotomia => 'pulpectomia_pulpotomia',
    EstadoClinicoDental.noErupcionado => 'no_erupcionado',
    EstadoClinicoDental.otro => 'otro',
  };

  String get label => switch (this) {
    EstadoClinicoDental.cariada => 'Cariada',
    EstadoClinicoDental.restaurada => 'Restaurada',
    EstadoClinicoDental.extraccionIndicada => 'Extracción indicada',
    EstadoClinicoDental.perdida => 'Pérdida',
    EstadoClinicoDental.pulpectomiaPulpotomia => 'Pulpectomía · Pulpotomía',
    EstadoClinicoDental.noErupcionado => 'No erupcionado',
    EstadoClinicoDental.otro => 'Otro',
  };

  MarcaClinica get marca => switch (this) {
    EstadoClinicoDental.cariada => MarcaClinica.relleno,
    EstadoClinicoDental.restaurada => MarcaClinica.relleno,
    EstadoClinicoDental.extraccionIndicada => MarcaClinica.rayado,
    EstadoClinicoDental.perdida => MarcaClinica.equis,
    EstadoClinicoDental.pulpectomiaPulpotomia => MarcaClinica.circuloPunto,
    EstadoClinicoDental.noErupcionado => MarcaClinica.guion,
    EstadoClinicoDental.otro => MarcaClinica.asterisco,
  };

  TintaClinica get tintaClinica => switch (this) {
    EstadoClinicoDental.restaurada => TintaClinica.azul,
    EstadoClinicoDental.noErupcionado => TintaClinica.azul,
    EstadoClinicoDental.otro => TintaClinica.negra,
    _ => TintaClinica.roja,
  };

  /// Color de la clave sobre papel blanco. En pantalla se resuelve contra la
  /// paleta del tema, que remapea [tintaClinica] al mismo rol en otro fondo.
  Color get tinta => tintaClinica.impresa;

  /// Caries y restauraciones se anotan sobre superficies concretas; el resto
  /// de las claves afectan a la pieza entera.
  bool get esPorSuperficie =>
      this == EstadoClinicoDental.cariada ||
      this == EstadoClinicoDental.restaurada;

  static EstadoClinicoDental? fromDb(String? value) {
    for (final estado in EstadoClinicoDental.values) {
      if (estado.dbValue == value) return estado;
    }
    return null;
  }
}

/// Un hallazgo anotado sobre una pieza. `superficies` vacío significa que la
/// clave se aplica a la pieza completa, como la `X` o el `-` del papel.
class HallazgoDental {
  final EstadoClinicoDental estado;
  final Set<TipoSuperficie> superficies;
  final String? detalle;

  const HallazgoDental({
    required this.estado,
    this.superficies = const {},
    this.detalle,
  });

  bool get esPiezaCompleta => superficies.isEmpty;

  HallazgoDental copyWith({
    Set<TipoSuperficie>? superficies,
    String? detalle,
  }) => HallazgoDental(
    estado: estado,
    superficies: superficies ?? this.superficies,
    detalle: detalle ?? this.detalle,
  );

  /// Lo que este hallazgo sigue aportando frente a [vigentes], o `null` si ya
  /// no aporta nada.
  ///
  /// Comparar solo por clave escondía lesiones: una caries anotada hoy en
  /// mesial borraba de la capa histórica la caries previa en distal, y el
  /// doctor dejaba de ver una lesión que sigue en la boca. La resta es por
  /// superficie, y solo una anotación de pieza completa tapa a otra igual.
  HallazgoDental? menos(Iterable<HallazgoDental> vigentes) {
    final mismaClave = vigentes.where((v) => v.estado == estado);
    if (mismaClave.isEmpty) return this;

    // Una clave vigente sobre la pieza entera cubre cualquier superficie.
    if (mismaClave.any((v) => v.esPiezaCompleta)) return null;
    // …pero una clave vigente por superficie no cubre la pieza entera.
    if (esPiezaCompleta) return this;

    final cubiertas = {for (final v in mismaClave) ...v.superficies};
    final restantes = superficies.where((s) => !cubiertas.contains(s)).toSet();
    return restantes.isEmpty ? null : copyWith(superficies: restantes);
  }

  Map<String, dynamic> toJson() => {
    'estado': estado.dbValue,
    if (superficies.isNotEmpty)
      'superficies': [for (final s in _ordenadas) s.dbValue],
    if (detalle != null && detalle!.trim().isNotEmpty)
      'detalle': detalle!.trim(),
  };

  List<TipoSuperficie> get _ordenadas =>
      TipoSuperficie.values.where(superficies.contains).toList();

  factory HallazgoDental.fromJson(Map<String, dynamic> json) {
    final crudas = json['superficies'];
    return HallazgoDental(
      estado:
          EstadoClinicoDentalX.fromDb(json['estado'] as String?) ??
          EstadoClinicoDental.otro,
      superficies: crudas is List
          ? {
              for (final s in crudas)
                if (_superficieDeDb(s?.toString()) case final sup?) sup,
            }
          : const {},
      detalle: json['detalle'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HallazgoDental &&
      other.estado == estado &&
      other.detalle == detalle &&
      other.superficies.length == superficies.length &&
      other.superficies.containsAll(superficies);

  @override
  int get hashCode =>
      Object.hash(estado, detalle, Object.hashAllUnordered(superficies));
}

/// Lo que queda de [historicos] una vez descontado lo que [vigentes] ya anota
/// en firme. La usan la capa tenue del odontodiagrama y el resumen del
/// expediente, para que ambas escondan exactamente lo mismo.
List<HallazgoDental> hallazgosRestantes(
  Iterable<HallazgoDental> historicos,
  Iterable<HallazgoDental> vigentes,
) => [
  for (final historico in historicos)
    if (historico.menos(vigentes) case final restante?) restante,
];

extension TipoSuperficieDb on TipoSuperficie {
  /// El enum `tipo_superficie` de Postgres está en minúscula.
  String get dbValue => name.toLowerCase();
}

TipoSuperficie? _superficieDeDb(String? valor) {
  if (valor == null) return null;
  for (final s in TipoSuperficie.values) {
    if (s.dbValue == valor) return s;
  }
  return null;
}

/// Filas de la tabla «Tejidos Blandos» del formulario, en su orden impreso.
enum TejidoBlando {
  labios,
  carrillos,
  encias,
  pisoBoca,
  lengua,
  paladarDuro,
  paladarBlando,
}

extension TejidoBlandoX on TejidoBlando {
  String get dbValue => switch (this) {
    TejidoBlando.labios => 'labios',
    TejidoBlando.carrillos => 'carrillos',
    TejidoBlando.encias => 'encias',
    TejidoBlando.pisoBoca => 'piso_boca',
    TejidoBlando.lengua => 'lengua',
    TejidoBlando.paladarDuro => 'paladar_duro',
    TejidoBlando.paladarBlando => 'paladar_blando',
  };

  String get label => switch (this) {
    TejidoBlando.labios => 'Labios',
    TejidoBlando.carrillos => 'Carrillos',
    TejidoBlando.encias => 'Encías',
    TejidoBlando.pisoBoca => 'Piso de Boca',
    TejidoBlando.lengua => 'Lengua',
    TejidoBlando.paladarDuro => 'Paladar Duro',
    TejidoBlando.paladarBlando => 'Paladar Blando',
  };

  static TejidoBlando? fromDb(String? value) {
    for (final tejido in TejidoBlando.values) {
      if (tejido.dbValue == value) return tejido;
    }
    return null;
  }
}

/// Contenido clínico del odontodiagrama, independiente del widget que lo
/// dibuja: hallazgos por pieza FDI y la anotación libre de cada tejido blando.
class EvaluacionOdontologica {
  final Map<int, List<HallazgoDental>> hallazgos;
  final Map<TejidoBlando, String> tejidosBlandos;

  const EvaluacionOdontologica({
    this.hallazgos = const {},
    this.tejidosBlandos = const {},
  });

  static const vacia = EvaluacionOdontologica();

  bool get estaVacia => hallazgos.isEmpty && tejidosBlandos.isEmpty;

  int get totalHallazgos =>
      hallazgos.values.fold(0, (suma, lista) => suma + lista.length);

  List<HallazgoDental> de(int fdi) => hallazgos[fdi] ?? const [];

  /// Piezas con al menos un hallazgo, en orden FDI ascendente.
  List<int> get piezasMarcadas => hallazgos.keys.toList()..sort();

  EvaluacionOdontologica conHallazgos(int fdi, List<HallazgoDental> lista) {
    final copia = {
      for (final entry in hallazgos.entries) entry.key: entry.value,
    };
    if (lista.isEmpty) {
      copia.remove(fdi);
    } else {
      copia[fdi] = List.unmodifiable(lista);
    }
    return EvaluacionOdontologica(
      hallazgos: Map.unmodifiable(copia),
      tejidosBlandos: tejidosBlandos,
    );
  }

  /// Aplica o retira una clave sobre una pieza, replicando el gesto del papel:
  /// las claves por superficie se acumulan superficie a superficie y las de
  /// pieza completa se ponen o se quitan de una vez.
  EvaluacionOdontologica alternar(
    int fdi,
    EstadoClinicoDental estado, {
    TipoSuperficie? superficie,
  }) {
    final actuales = [...de(fdi)];
    final indice = actuales.indexWhere((h) => h.estado == estado);

    if (!estado.esPorSuperficie || superficie == null) {
      if (indice >= 0) {
        actuales.removeAt(indice);
      } else {
        actuales.add(HallazgoDental(estado: estado));
      }
      return conHallazgos(fdi, actuales);
    }

    if (indice < 0) {
      actuales.add(HallazgoDental(estado: estado, superficies: {superficie}));
      return conHallazgos(fdi, actuales);
    }

    final previo = actuales[indice];
    final superficies = {...previo.superficies};
    if (!superficies.remove(superficie)) superficies.add(superficie);

    if (superficies.isEmpty) {
      actuales.removeAt(indice);
    } else {
      actuales[indice] = previo.copyWith(superficies: superficies);
    }
    return conHallazgos(fdi, actuales);
  }

  EvaluacionOdontologica sinPieza(int fdi) => conHallazgos(fdi, const []);

  /// Quita de esta evaluación lo que ya aparece igual en [actual], para que la
  /// capa histórica no repita en tenue lo que ya está anotado en firme.
  EvaluacionOdontologica menos(EvaluacionOdontologica actual) {
    final piezas = <int, List<HallazgoDental>>{};
    for (final entry in hallazgos.entries) {
      final restantes = hallazgosRestantes(entry.value, actual.de(entry.key));
      if (restantes.isNotEmpty) piezas[entry.key] = List.unmodifiable(restantes);
    }
    final tejidos = {
      for (final entry in tejidosBlandos.entries)
        if (actual.tejidosBlandos[entry.key] != entry.value)
          entry.key: entry.value,
    };
    return EvaluacionOdontologica(
      hallazgos: Map.unmodifiable(piezas),
      tejidosBlandos: Map.unmodifiable(tejidos),
    );
  }

  /// Consolida varias evaluaciones en una sola. [evaluaciones] llega de la más
  /// reciente a la más antigua y gana la primera que anota cada pieza o tejido,
  /// igual que el resumen del expediente: lo último que dijo el doctor.
  static EvaluacionOdontologica consolidar(
    Iterable<EvaluacionOdontologica> evaluaciones,
  ) {
    final piezas = <int, List<HallazgoDental>>{};
    final tejidos = <TejidoBlando, String>{};
    for (final evaluacion in evaluaciones) {
      evaluacion.hallazgos.forEach(
        (fdi, lista) => piezas.putIfAbsent(fdi, () => lista),
      );
      evaluacion.tejidosBlandos.forEach(
        (tejido, anotacion) => tejidos.putIfAbsent(tejido, () => anotacion),
      );
    }
    return EvaluacionOdontologica(
      hallazgos: Map.unmodifiable(piezas),
      tejidosBlandos: Map.unmodifiable(tejidos),
    );
  }

  EvaluacionOdontologica conTejido(TejidoBlando tejido, String anotacion) {
    final copia = {
      for (final entry in tejidosBlandos.entries) entry.key: entry.value,
    };
    if (anotacion.trim().isEmpty) {
      copia.remove(tejido);
    } else {
      copia[tejido] = anotacion.trim();
    }
    return EvaluacionOdontologica(
      hallazgos: hallazgos,
      tejidosBlandos: Map.unmodifiable(copia),
    );
  }

  Map<String, dynamic> toJson() => {
    'hallazgos': {
      for (final entry in hallazgos.entries)
        if (entry.value.isNotEmpty)
          entry.key.toString(): [for (final h in entry.value) h.toJson()],
    },
    'tejidos_blandos': {
      for (final entry in tejidosBlandos.entries)
        entry.key.dbValue: entry.value,
    },
  };

  factory EvaluacionOdontologica.fromJson(dynamic raw) {
    if (raw is! Map) return vacia;
    final json = Map<String, dynamic>.from(raw);
    return EvaluacionOdontologica(
      hallazgos: Map.unmodifiable(_parseHallazgos(json['hallazgos'])),
      tejidosBlandos: Map.unmodifiable(_parseTejidos(json['tejidos_blandos'])),
    );
  }

  static Map<int, List<HallazgoDental>> _parseHallazgos(dynamic raw) {
    if (raw is! Map) return const {};
    final resultado = <int, List<HallazgoDental>>{};
    for (final entry in raw.entries) {
      final fdi = int.tryParse(entry.key.toString());
      final valor = entry.value;
      if (fdi == null || valor is! List) continue;
      final lista = [
        for (final item in valor)
          if (item is Map)
            HallazgoDental.fromJson(Map<String, dynamic>.from(item)),
      ];
      if (lista.isNotEmpty) resultado[fdi] = List.unmodifiable(lista);
    }
    return resultado;
  }

  static Map<TejidoBlando, String> _parseTejidos(dynamic raw) {
    if (raw is! Map) return const {};
    final resultado = <TejidoBlando, String>{};
    for (final entry in raw.entries) {
      final tejido = TejidoBlandoX.fromDb(entry.key.toString());
      final anotacion = entry.value?.toString().trim() ?? '';
      if (tejido != null && anotacion.isNotEmpty) resultado[tejido] = anotacion;
    }
    return resultado;
  }
}

/// Una fila de las CLAVES. La lista es configurable para que la clínica pueda
/// acordar estados adicionales sin tocar el widget que dibuja el diagrama.
class EntradaLeyendaOdontograma {
  final EstadoClinicoDental estado;
  final Color tinta;
  final MarcaClinica marca;
  final String? etiqueta;

  const EntradaLeyendaOdontograma({
    required this.estado,
    required this.tinta,
    required this.marca,
    this.etiqueta,
  });

  /// Toma tinta y marca de la clave del formulario.
  EntradaLeyendaOdontograma.delFormulario(this.estado, {this.etiqueta})
    : tinta = estado.tinta,
      marca = estado.marca;

  String get label => etiqueta ?? estado.label;
}

/// Las seis claves impresas en el formulario, en su orden original.
final List<EntradaLeyendaOdontograma> leyendaFormularioFisico =
    List.unmodifiable([
      EntradaLeyendaOdontograma.delFormulario(EstadoClinicoDental.cariada),
      EntradaLeyendaOdontograma.delFormulario(EstadoClinicoDental.restaurada),
      EntradaLeyendaOdontograma.delFormulario(
        EstadoClinicoDental.extraccionIndicada,
      ),
      EntradaLeyendaOdontograma.delFormulario(EstadoClinicoDental.perdida),
      EntradaLeyendaOdontograma.delFormulario(
        EstadoClinicoDental.pulpectomiaPulpotomia,
      ),
      EntradaLeyendaOdontograma.delFormulario(
        EstadoClinicoDental.noErupcionado,
      ),
    ]);
