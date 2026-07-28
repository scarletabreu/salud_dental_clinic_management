import 'package:salud_dental_clinic_management/features/receta/data/models/item_receta_model.dart';
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

  /// Lee una fila de `recetas` sin asumir que trae las columnas del formato
  /// antiguo (una medicina por fila).
  ///
  /// La tabla ya convive con el formato de SD-153: una receta es una cabecera
  /// con `codigo_receta` y sus medicinas dentro del jsonb `items_receta`, y
  /// entonces `titulo`, `dosis`, `medicina_id`, etc. quedan NULL por diseño.
  /// Con los casts no-nulos anteriores esas filas lanzaban `TypeError`, y como
  /// el parseo ocurre dentro del guard del repositorio, una sola receta así
  /// tumbaba el listado completo de consultas con un error sin detalle.
  factory RecetaModel.fromJson(Map<String, dynamic> json) {
    final idStr = json['id'] as String?;
    final codigoBruto = json['codigo_receta'] ?? json['codigo'];
    final String codigoFinal;
    if (codigoBruto != null && codigoBruto.toString().trim().isNotEmpty) {
      codigoFinal = codigoBruto.toString().trim();
    } else if (idStr != null && idStr.length >= 8) {
      codigoFinal = 'RX-${idStr.substring(0, 8).toUpperCase()}';
    } else {
      codigoFinal = 'RX-PENDIENTE';
    }

    final itemsRaw = json['items_receta'] as List?;
    final List<ItemReceta> itemsList;

    if (itemsRaw != null && itemsRaw.isNotEmpty) {
      itemsList = itemsRaw
          .map((i) => ItemRecetaModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } else if (json['titulo'] != null || json['nombre_medicamento'] != null) {
      itemsList = [
        ItemRecetaModel(
          nombreMedicamento:
              (json['titulo'] ?? json['nombre_medicamento'] ?? 'Medicamento')
                  as String,
          dosis: (json['dosis'] ?? '') as String,
          viaAdministracion:
              (json['via_administracion'] ?? 'vía oral') as String,
          frecuencia: (json['frecuencia'] ?? '') as String,
          duracion: (json['duracion'] ?? '') as String,
          cantidadIndicada: (json['cantidad_indicada'] ?? '') as String,
          presentacionConcentracion:
              (json['presentacion_concentracion'] ?? '') as String,
          indicacionesEspecificas: json['indicaciones'] as String?,
        ),
      ];
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
      id: idStr,
      codigoReceta: codigoFinal,
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
