import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';

/// Ciclo de vida de una receta (HFX-CLIN-002).
///
/// Mientras la consulta está abierta la receta es un [borrador] mutable. El
/// cierre la [emitida] y desde ahí es un documento entregado al paciente: solo
/// puede [anulada] o [reemplazada], nunca reescribirse. El estado histórico
/// `activa` se lee como [emitida].
enum EstadoReceta { borrador, emitida, anulada, reemplazada }

class Receta {
  final String? id;
  final String codigoReceta;
  final String consultaId;
  final String pacienteId;
  final String? doctorId;
  final String? doctorNombre;
  final DateTime fechaEmision;
  final List<ItemReceta> items;
  final String? indicacionesGenerales;
  final String? justificacionContraindicaciones;
  final EstadoReceta estado;
  final String? motivoAnulacion;
  final String? recetaReemplazadaId;

  const Receta({
    this.id,
    required this.codigoReceta,
    required this.consultaId,
    required this.pacienteId,
    this.doctorId,
    this.doctorNombre,
    required this.fechaEmision,
    required this.items,
    this.indicacionesGenerales,
    this.justificacionContraindicaciones,
    this.estado = EstadoReceta.borrador,
    this.motivoAnulacion,
    this.recetaReemplazadaId,
  });

  Receta copyWith({
    String? id,
    String? codigoReceta,
    String? consultaId,
    String? pacienteId,
    String? doctorId,
    String? doctorNombre,
    DateTime? fechaEmision,
    List<ItemReceta>? items,
    String? indicacionesGenerales,
    String? justificacionContraindicaciones,
    EstadoReceta? estado,
    String? motivoAnulacion,
    String? recetaReemplazadaId,
  }) {
    return Receta(
      id: null,
      codigoReceta: codigoReceta ?? this.codigoReceta,
      consultaId: consultaId ?? this.consultaId,
      pacienteId: pacienteId ?? this.pacienteId,
      doctorId: doctorId ?? this.doctorId,
      doctorNombre: doctorNombre ?? this.doctorNombre,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      items: items ?? this.items,
      indicacionesGenerales:
          indicacionesGenerales ?? this.indicacionesGenerales,
      justificacionContraindicaciones:
          justificacionContraindicaciones ??
          this.justificacionContraindicaciones,
      estado: estado ?? this.estado,
      motivoAnulacion: motivoAnulacion ?? this.motivoAnulacion,
      recetaReemplazadaId: recetaReemplazadaId ?? this.recetaReemplazadaId,
    );
  }
}
