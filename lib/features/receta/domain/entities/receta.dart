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

  /// Versión confirmada por el servidor. Viaja en cada guardado para que dos
  /// pestañas editando la misma receta no se pisen en silencio (F1-09): sin
  /// ella, `hfx_clin_002_aplicar_borrador` ni siquiera comprobaba el conflicto,
  /// porque sólo compara cuando la clave está presente.
  final int? version;

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
    this.version,
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
    int? version,
  }) {
    return Receta(
      // Antes esto era `id: null` con el parámetro `id` declarado y sin usar,
      // así que `_sellarRecetas` no sellaba nada: cada autoguardado volvía a
      // mandar la receta sin id, el servidor anulaba la anterior e insertaba
      // otra, y el bloqueo optimista de la receta nunca podía funcionar.
      id: id ?? this.id,
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
      version: version ?? this.version,
    );
  }
}
