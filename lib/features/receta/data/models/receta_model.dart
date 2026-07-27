import 'package:salud_dental_clinic_management/features/receta/data/models/tem_receta_model.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';

class RecetaModel extends Receta {
  const RecetaModel({
    super.id,
    required super.codigoReceta,
    required super.consultaId,
    required super.pacienteId,
    super.doctorId,
    super.doctorNombre,
    required super.fechaEmision,
    required super.items,
    super.indicacionesGenerales,
    super.justificacionContraindicaciones,
    super.estado,
    super.motivoAnulacion,
    super.recetaReemplazadaId,
  });

  factory RecetaModel.fromJson(Map<String, dynamic> json) {
    // Manejo de retrocompatibilidad si viene una fila antigua con 1 solo medicamento
    final itemsRaw = json['items_receta'] as List?;
    final List<ItemReceta> itemsList;

    if (itemsRaw != null && itemsRaw.isNotEmpty) {
      itemsList = itemsRaw
          .map((i) => ItemRecetaModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } else if (json['titulo'] != null) {
      // Fila heredada de la versión vieja
      itemsList = [ItemRecetaModel.fromJson(json)];
    } else {
      itemsList = const [];
    }

    String? doctorNombreCalc;
    try {
      final docObj = json['doctor'];
      if (docObj != null && docObj['usuarios'] != null) {
        final p = docObj['usuarios']['personas'];
        if (p != null) {
          doctorNombreCalc = 'Dr. ${p['nombre']} ${p['apellido']}'.trim();
        }
      }
    } catch (_) {}

    return RecetaModel(
      id: json['id'] as String?,
      codigoReceta: (json['codigo_receta'] ?? 'RX-LEGACY') as String,
      consultaId: (json['consulta_id'] ?? '') as String,
      pacienteId: (json['paciente_id'] ?? '') as String,
      doctorId: json['doctor_id'] as String?,
      doctorNombre: doctorNombreCalc,
      fechaEmision: DateTime.parse(
        json['fecha_emision'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ).toLocal(),
      items: itemsList,
      indicacionesGenerales: json['indicaciones_generales'] as String?,
      justificacionContraindicaciones:
          json['justificacion_contraindicaciones'] as String?,
      estado: _parseEstado(json['estado']),
      motivoAnulacion: json['motivo_anulacion'] as String?,
      recetaReemplazadaId: json['receta_reemplazada_id'] as String?,
    );
  }

  static EstadoReceta _parseEstado(dynamic estado) {
    if (estado == 'anulada') return EstadoReceta.anulada;
    if (estado == 'reemplazada') return EstadoReceta.reemplazada;
    return EstadoReceta.activa;
  }

  Map<String, dynamic> toCabeceraJson() {
    return {
      if (id != null && id!.length == 36) 'id': id,
      'consulta_id': consultaId,
      'paciente_id': pacienteId,
      'doctor_id': doctorId,
      'fecha_emision': fechaEmision.toIso8601String(),
      'indicaciones_generales': indicacionesGenerales,
      'justificacion_contraindicaciones': justificacionContraindicaciones,
      'estado': estado.name,
      'motivo_anulacion': motivoAnulacion,
      'receta_reemplazada_id': recetaReemplazadaId,
    };
  }

  factory RecetaModel.fromEntity(Receta receta) {
    return RecetaModel(
      id: receta.id,
      codigoReceta: receta.codigoReceta,
      consultaId: receta.consultaId,
      pacienteId: receta.pacienteId,
      doctorId: receta.doctorId,
      doctorNombre: receta.doctorNombre,
      fechaEmision: receta.fechaEmision,
      items: receta.items,
      indicacionesGenerales: receta.indicacionesGenerales,
      justificacionContraindicaciones: receta.justificacionContraindicaciones,
      estado: receta.estado,
      motivoAnulacion: receta.motivoAnulacion,
      recetaReemplazadaId: receta.recetaReemplazadaId,
    );
  }
}
