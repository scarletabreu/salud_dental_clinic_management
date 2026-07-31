/// Las reglas que hacen sonar las alertas clínicas, tal y como el doctor las
/// edita (HFX-CLIN-006).
///
/// Un umbral clínico es una decisión médica, no una constante del programa.
/// Hasta este ticket vivían en una migración, así que moverlos exigía un
/// despliegue: la garantía más segura de que se quedaran desactualizados. Aquí
/// el doctor los edita y la base guarda una versión nueva firmada.
///
/// El vocabulario —severidad y acción— es el mismo que usa la alerta emitida,
/// y se importa de allí a propósito: si la pantalla de ajustes tradujera
/// `documentar` de otra forma que la consulta, el doctor configuraría una cosa
/// y vería otra.
library;

import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';

enum TipoRegla {
  /// Un signo vital fuera de un rango que la clínica considera crítico.
  valorCritico('valor_critico', 'Valor crítico'),

  /// Una condición del paciente combinada con signos vitales alterados.
  combinacionCondicionSigno('combinacion_condicion_signo', 'Condición y signos'),

  /// Un dato que la consulta no puede cerrar sin haber registrado.
  requisitoDato('requisito_dato', 'Dato obligatorio'),

  /// Fuera del rango físicamente posible. Sale del catálogo, no de un umbral.
  rangoImposible('rango_imposible', 'Rango imposible'),

  /// Dos medidas que no pueden coexistir, como una diastólica por encima de la
  /// sistólica.
  relacionImposible('relacion_imposible', 'Relación imposible');

  const TipoRegla(this.dbValue, this.etiqueta);
  final String dbValue;
  final String etiqueta;

  static TipoRegla porValor(String? valor) => TipoRegla.values.firstWhere(
    (t) => t.dbValue == valor,
    orElse: () => TipoRegla.valorCritico,
  );
}

enum EstadoRegla {
  pendienteAprobacion('pendiente_aprobacion', 'Sin aprobar'),
  aprobada('aprobada', 'En vigor'),
  retirada('retirada', 'Retirada');

  const EstadoRegla(this.dbValue, this.etiqueta);
  final String dbValue;
  final String etiqueta;

  static EstadoRegla porValor(String? valor) => EstadoRegla.values.firstWhere(
    (e) => e.dbValue == valor,
    orElse: () => EstadoRegla.pendienteAprobacion,
  );
}

/// Un signo vigilado con sus límites. Al menos uno de los dos debe existir: un
/// signo sin límite no vigila nada, y la base lo rechaza.
class UmbralSigno {
  final String codigo;
  final num? minimo;
  final num? maximo;

  const UmbralSigno({required this.codigo, this.minimo, this.maximo});

  bool get tieneLimite => minimo != null || maximo != null;

  bool get esCoherente =>
      tieneLimite && (minimo == null || maximo == null || minimo! <= maximo!);

  Map<String, dynamic> toJson() => {
    'codigo': codigo,
    if (minimo != null) 'min': minimo,
    if (maximo != null) 'max': maximo,
  };

  factory UmbralSigno.fromJson(Map<String, dynamic> json) => UmbralSigno(
    codigo: json['codigo'] as String? ?? '',
    minimo: json['min'] as num?,
    maximo: json['max'] as num?,
  );

  UmbralSigno copyWith({
    String? codigo,
    num? minimo,
    num? maximo,
    bool limpiarMinimo = false,
    bool limpiarMaximo = false,
  }) => UmbralSigno(
    codigo: codigo ?? this.codigo,
    minimo: limpiarMinimo ? null : (minimo ?? this.minimo),
    maximo: limpiarMaximo ? null : (maximo ?? this.maximo),
  );
}

/// Los parámetros de una regla, ya interpretados.
///
/// La base los guarda como JSON libre porque cada tipo de regla necesita una
/// forma distinta. La pantalla no puede trabajar con un mapa suelto: escribir
/// `minimo` donde la base espera `min` no falla, deja la regla muda.
class ParametrosRegla {
  /// Signo vigilado en las reglas de valor crítico y de dato obligatorio.
  final String? codigoSigno;

  /// Límites del signo en una regla de valor crítico.
  final num? minimo;
  final num? maximo;

  /// Condición del paciente que activa una regla de combinación.
  final String? condicion;

  /// Signos vigilados en una regla de combinación.
  final List<UmbralSigno> signos;

  /// Franja etaria a la que se limita la regla, si la hay.
  final num? edadMinimaAnios;
  final num? edadMaximaAnios;

  /// Lo que vino de la base y esta clase no interpreta. Se conserva para no
  /// perderlo al volver a publicar: una regla que el programa no sabe editar
  /// no debe salir mutilada de una pantalla de edición.
  final Map<String, dynamic> extras;

  const ParametrosRegla({
    this.codigoSigno,
    this.minimo,
    this.maximo,
    this.condicion,
    this.signos = const [],
    this.edadMinimaAnios,
    this.edadMaximaAnios,
    this.extras = const {},
  });

  static const _clavesConocidas = {
    'codigo',
    'min',
    'max',
    'condicion',
    'signos',
    'edad_min_anios',
    'edad_max_anios',
  };

  factory ParametrosRegla.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ParametrosRegla();
    return ParametrosRegla(
      codigoSigno: json['codigo'] as String?,
      minimo: json['min'] as num?,
      maximo: json['max'] as num?,
      condicion: json['condicion'] as String?,
      signos: [
        for (final signo in (json['signos'] as List? ?? const []))
          if (signo is Map)
            UmbralSigno.fromJson(signo.cast<String, dynamic>()),
      ],
      edadMinimaAnios: json['edad_min_anios'] as num?,
      edadMaximaAnios: json['edad_max_anios'] as num?,
      extras: {
        for (final entrada in json.entries)
          if (!_clavesConocidas.contains(entrada.key))
            entrada.key: entrada.value,
      },
    );
  }

  /// Serializa según el tipo: mandar `signos` en una regla de valor crítico o
  /// `min` en una de combinación no rompe nada, pero deja basura en el
  /// histórico de versiones que después nadie sabe leer.
  Map<String, dynamic> toJson(TipoRegla tipo) {
    final mapa = <String, dynamic>{...extras};

    switch (tipo) {
      case TipoRegla.valorCritico:
        if (codigoSigno != null) mapa['codigo'] = codigoSigno;
        if (minimo != null) mapa['min'] = minimo;
        if (maximo != null) mapa['max'] = maximo;
      case TipoRegla.requisitoDato:
        if (codigoSigno != null) mapa['codigo'] = codigoSigno;
      case TipoRegla.combinacionCondicionSigno:
        if (condicion != null) mapa['condicion'] = condicion;
        mapa['signos'] = [for (final signo in signos) signo.toJson()];
      case TipoRegla.rangoImposible:
      case TipoRegla.relacionImposible:
        break;
    }

    if (edadMinimaAnios != null) mapa['edad_min_anios'] = edadMinimaAnios;
    if (edadMaximaAnios != null) mapa['edad_max_anios'] = edadMaximaAnios;
    return mapa;
  }

  ParametrosRegla copyWith({
    String? codigoSigno,
    num? minimo,
    num? maximo,
    String? condicion,
    List<UmbralSigno>? signos,
    num? edadMinimaAnios,
    num? edadMaximaAnios,
    bool limpiarMinimo = false,
    bool limpiarMaximo = false,
    bool limpiarEdadMinima = false,
    bool limpiarEdadMaxima = false,
  }) => ParametrosRegla(
    codigoSigno: codigoSigno ?? this.codigoSigno,
    minimo: limpiarMinimo ? null : (minimo ?? this.minimo),
    maximo: limpiarMaximo ? null : (maximo ?? this.maximo),
    condicion: condicion ?? this.condicion,
    signos: signos ?? this.signos,
    edadMinimaAnios: limpiarEdadMinima
        ? null
        : (edadMinimaAnios ?? this.edadMinimaAnios),
    edadMaximaAnios: limpiarEdadMaxima
        ? null
        : (edadMaximaAnios ?? this.edadMaximaAnios),
    extras: extras,
  );
}

class ReglaClinica {
  final String id;
  final String codigo;
  final int version;
  final String nombre;
  final String? descripcion;
  final String categoria;
  final TipoRegla tipo;
  final ParametrosRegla parametros;
  final SeveridadAlerta severidad;
  final AccionAlerta accion;
  final EstadoRegla estado;
  final String? fuente;
  final DateTime? aprobadaEn;

  /// Si la clínica puede moverle el umbral. Las reglas de rango y relación
  /// imposible no dependen de un umbral configurable, sino del catálogo de
  /// signos vitales; mostrarlas como editables prometería algo que no es.
  final bool editable;

  const ReglaClinica({
    required this.id,
    required this.codigo,
    required this.version,
    required this.nombre,
    required this.categoria,
    required this.tipo,
    required this.parametros,
    required this.severidad,
    required this.accion,
    required this.estado,
    this.descripcion,
    this.fuente,
    this.aprobadaEn,
    this.editable = false,
  });

  bool get estaEnVigor => estado == EstadoRegla.aprobada;

  ReglaClinica copyWith({
    ParametrosRegla? parametros,
    SeveridadAlerta? severidad,
    AccionAlerta? accion,
  }) => ReglaClinica(
    id: id,
    codigo: codigo,
    version: version,
    nombre: nombre,
    descripcion: descripcion,
    categoria: categoria,
    tipo: tipo,
    parametros: parametros ?? this.parametros,
    severidad: severidad ?? this.severidad,
    accion: accion ?? this.accion,
    estado: estado,
    fuente: fuente,
    aprobadaEn: aprobadaEn,
    editable: editable,
  );
}

/// Un signo vital tal como lo define el catálogo: qué es, en qué unidad se mide
/// y entre qué valores es físicamente posible.
///
/// La pantalla lo necesita para no dejar que el doctor fije un umbral fuera de
/// lo medible —una temperatura máxima de 60 °C no alertaría jamás— y para
/// escribir la unidad al lado del campo.
class SignoVitalCatalogo {
  final String codigo;
  final String etiqueta;
  final String unidad;
  final num minimoPosible;
  final num maximoPosible;
  final int decimales;

  const SignoVitalCatalogo({
    required this.codigo,
    required this.etiqueta,
    required this.unidad,
    required this.minimoPosible,
    required this.maximoPosible,
    this.decimales = 0,
  });

  bool contiene(num valor) => valor >= minimoPosible && valor <= maximoPosible;

  factory SignoVitalCatalogo.fromJson(Map<String, dynamic> json) =>
      SignoVitalCatalogo(
        codigo: json['codigo'] as String? ?? '',
        etiqueta: json['etiqueta'] as String? ?? '',
        unidad: json['unidad'] as String? ?? '',
        minimoPosible: json['minimo_posible'] as num? ?? 0,
        maximoPosible: json['maximo_posible'] as num? ?? 0,
        decimales: (json['decimales'] as num?)?.toInt() ?? 0,
      );
}
