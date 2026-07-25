import 'package:flutter/material.dart';

enum Denticion { permanente, temporal }

enum EstadoClinicoDental {
  caries,
  restauracion,
  extraccionIndicada,
  piezaPerdida,
  pulpectomiaPulpotomia,
  noErupcionada,
  otro,
}

extension EstadoClinicoDentalX on EstadoClinicoDental {
  String get dbValue => switch (this) {
    EstadoClinicoDental.caries => 'caries',
    EstadoClinicoDental.restauracion => 'restauracion',
    EstadoClinicoDental.extraccionIndicada => 'extraccion_indicada',
    EstadoClinicoDental.piezaPerdida => 'pieza_perdida',
    EstadoClinicoDental.pulpectomiaPulpotomia => 'pulpectomia_pulpotomia',
    EstadoClinicoDental.noErupcionada => 'no_erupcionada',
    EstadoClinicoDental.otro => 'otro',
  };

  String get label => switch (this) {
    EstadoClinicoDental.caries => 'Caries',
    EstadoClinicoDental.restauracion => 'Restauración',
    EstadoClinicoDental.extraccionIndicada => 'Extracción indicada',
    EstadoClinicoDental.piezaPerdida => 'Pieza perdida',
    EstadoClinicoDental.pulpectomiaPulpotomia => 'Pulpectomía / pulpotomía',
    EstadoClinicoDental.noErupcionada => 'No erupcionada',
    EstadoClinicoDental.otro => 'Otro',
  };

  static EstadoClinicoDental? fromDb(String? value) {
    for (final estado in EstadoClinicoDental.values) {
      if (estado.dbValue == value) return estado;
    }
    return null;
  }
}

class HallazgoDental {
  final EstadoClinicoDental estado;
  final String? detalle;

  const HallazgoDental({required this.estado, this.detalle});

  Map<String, dynamic> toJson() => {
    'estado': estado.dbValue,
    if (detalle != null && detalle!.trim().isNotEmpty)
      'detalle': detalle!.trim(),
  };

  factory HallazgoDental.fromJson(Map<String, dynamic> json) {
    return HallazgoDental(
      estado:
          EstadoClinicoDentalX.fromDb(json['estado'] as String?) ??
          EstadoClinicoDental.otro,
      detalle: json['detalle'] as String?,
    );
  }
}

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
    TejidoBlando.pisoBoca => 'Piso de boca',
    TejidoBlando.lengua => 'Lengua',
    TejidoBlando.paladarDuro => 'Paladar duro',
    TejidoBlando.paladarBlando => 'Paladar blando',
  };
}

enum CondicionTejidoBlando { sinAlteracion, conAlteracion }

class EvaluacionTejidoBlando {
  final CondicionTejidoBlando condicion;
  final String? observacion;

  const EvaluacionTejidoBlando({
    this.condicion = CondicionTejidoBlando.sinAlteracion,
    this.observacion,
  });

  Map<String, dynamic> toJson() => {
    'condicion': condicion.name,
    if (observacion != null && observacion!.trim().isNotEmpty)
      'observacion': observacion!.trim(),
  };

  factory EvaluacionTejidoBlando.fromJson(Map<String, dynamic> json) {
    return EvaluacionTejidoBlando(
      condicion: json['condicion'] == CondicionTejidoBlando.conAlteracion.name
          ? CondicionTejidoBlando.conAlteracion
          : CondicionTejidoBlando.sinAlteracion,
      observacion: json['observacion'] as String?,
    );
  }
}

class EntradaLeyendaOdontograma {
  final EstadoClinicoDental estado;
  final Color color;
  final IconData icon;
  final String? etiqueta;

  const EntradaLeyendaOdontograma({
    required this.estado,
    required this.color,
    required this.icon,
    this.etiqueta,
  });

  String get label => etiqueta ?? estado.label;
}

const leyendaOdontogramaPredeterminada = [
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.caries,
    color: Color(0xFFD92D20),
    icon: Icons.circle,
  ),
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.restauracion,
    color: Color(0xFF2563EB),
    icon: Icons.crop_square_rounded,
  ),
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.extraccionIndicada,
    color: Color(0xFFD92D20),
    icon: Icons.close_rounded,
  ),
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.piezaPerdida,
    color: Color(0xFF475467),
    icon: Icons.horizontal_rule_rounded,
  ),
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.pulpectomiaPulpotomia,
    color: Color(0xFF7F56D9),
    icon: Icons.change_history_rounded,
  ),
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.noErupcionada,
    color: Color(0xFF667085),
    icon: Icons.radio_button_unchecked_rounded,
  ),
  EntradaLeyendaOdontograma(
    estado: EstadoClinicoDental.otro,
    color: Color(0xFFF79009),
    icon: Icons.more_horiz_rounded,
  ),
];
