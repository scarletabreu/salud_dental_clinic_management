import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// De dónde viene una marca del odontograma.
///
/// No es una columna nueva: es la lectura unificada de los tres ejes que SD-135
/// separó —evaluar, planificar, ejecutar— más el antecedente de otra consulta.
/// Guardarla en la base la haría derivar de dos sitios a la vez y quedaría
/// desincronizada en cuanto una fila cambiara de eje.
enum ProcedenciaMarca {
  /// Anotado en una consulta anterior del mismo paciente.
  historico,

  /// Hallazgo de la evaluación de esta consulta (`diagnosticos_aplicados`).
  evaluado,

  /// Actividad decidida en el plan (`items_plan_tratamiento`). No factura.
  planificado,

  /// Procedimiento realizado (`tratamientos_aplicados`). Es lo único que cobra.
  ejecutado,
}

extension ProcedenciaMarcaX on ProcedenciaMarca {
  String get etiqueta => switch (this) {
    ProcedenciaMarca.historico => 'Histórico',
    ProcedenciaMarca.evaluado => 'Evaluado',
    ProcedenciaMarca.planificado => 'Planificado',
    ProcedenciaMarca.ejecutado => 'Ejecutado',
  };

  /// Lo que significa para el doctor, tal como se lee en la leyenda.
  String get descripcion => switch (this) {
    ProcedenciaMarca.historico => 'Anotado en una consulta anterior',
    ProcedenciaMarca.evaluado => 'Hallazgo de la evaluación de hoy',
    ProcedenciaMarca.planificado => 'Decidido en el plan, aún sin ejecutar',
    ProcedenciaMarca.ejecutado => 'Realizado en esta consulta',
  };

  /// Cuál manda cuando varias marcas caen sobre la misma cara.
  ///
  /// Gana lo que describe el estado actual de la boca: lo que se hizo hoy tapa
  /// lo que se halló hoy, y ambos tapan una intención o un antecedente. Sin
  /// este orden, una caries evaluada seguiría pintando en rojo una cara que ya
  /// se restauró en la misma sesión.
  int get prioridadVisual => switch (this) {
    ProcedenciaMarca.ejecutado => 3,
    ProcedenciaMarca.evaluado => 2,
    ProcedenciaMarca.planificado => 1,
    ProcedenciaMarca.historico => 0,
  };
}

/// Qué clase de cosa es una marca, con independencia del eje del que venga.
///
/// Es lo que decide con qué tinta se dibuja cuando el catálogo todavía no le
/// asignó una clave del formulario: un hallazgo describe una patología y se
/// anota en rojo; un procedimiento es trabajo sobre la pieza y va en azul.
enum TipoMarcaClinica { hallazgo, procedimiento }

/// Una anotación del odontograma sobre una pieza o sobre una de sus caras.
///
/// Unifica en una sola lectura lo que vive en tres tablas distintas para que la
/// ficha de la pieza, el mapa de superficies y la leyenda cuenten lo mismo. Es
/// una proyección de solo lectura: se construye al pintar y nunca se persiste.
class MarcaClinicaPieza {
  /// Id de la fila de origen, si ya está persistida.
  final String? id;

  final int fdi;

  /// Clave del formulario en papel, cuando el catálogo se la asignó.
  ///
  /// `null` es lo normal en cuanto la clínica añade un procedimiento propio:
  /// las claves impresas son un vocabulario cerrado y la mayoría del catálogo
  /// no cabe en ellas. Sin clave la marca no estampa símbolo en el diagrama,
  /// pero sigue tiñendo su cara y listándose en la ficha.
  final EstadoClinicoDental? clave;

  /// Hallazgo o procedimiento. Decide la tinta cuando no hay clave.
  final TipoMarcaClinica tipo;

  /// Nombre del catálogo («Resina compuesta», «Caries oclusal»).
  final String titulo;

  /// Cara concreta, o `null` si la marca es de la pieza entera.
  final TipoSuperficie? superficie;

  final ProcedenciaMarca procedencia;

  /// Estado dentro de su propio eje: severidad si es un hallazgo, situación del
  /// plan si es una actividad, avance de la ejecución si es un procedimiento.
  final String estado;

  final DateTime? fecha;
  final String? consultaId;
  final String? doctorId;
  final String? notas;

  /// Posición de la fila dentro de la lista de la pieza de la que salió
  /// (`diente.tratamientos`, `diente.diagnosis`…). Es como el resto de la
  /// aplicación direcciona una anotación para editarla —`quitarTratamiento`
  /// recibe un índice—, y `null` en lo que no se edita desde aquí.
  final int? indiceOrigen;

  /// Si la marca sigue describiendo el estado de la pieza. Una actividad
  /// rechazada o cancelada se conserva en la ficha —es constancia de lo que se
  /// ofreció— pero no pinta la cara: nadie va a tratarla por ella.
  final bool vigente;

  const MarcaClinicaPieza({
    this.id,
    required this.fdi,
    required this.titulo,
    required this.procedencia,
    required this.estado,
    required this.tipo,
    this.clave,
    this.superficie,
    this.fecha,
    this.consultaId,
    this.doctorId,
    this.notas,
    this.indiceOrigen,
    this.vigente = true,
  });

  bool get esPiezaCompleta => superficie == null;

  /// Con qué tinta se anota. El dato clínico es *cuál* de las tres, no su
  /// valor RGB: cada papel la resuelve a su manera.
  ///
  /// Sin clave manda el tipo. Antes se caía en «Otro», y eso estampaba un
  /// asterisco sobre cada pieza con un procedimiento que la clínica aún no
  /// había clasificado —una corona, una profilaxis—, indistinguible de lo que
  /// el doctor sí quiso marcar como «Otro». «Otro» es una elección explícita,
  /// no el cajón de lo que falta en el catálogo.
  TintaClinica get tintaClinica =>
      clave?.tintaClinica ??
      switch (tipo) {
        TipoMarcaClinica.hallazgo => TintaClinica.roja,
        TipoMarcaClinica.procedimiento => TintaClinica.azul,
      };

  @override
  bool operator ==(Object other) =>
      other is MarcaClinicaPieza &&
      other.id == id &&
      other.fdi == fdi &&
      other.clave == clave &&
      other.tipo == tipo &&
      other.titulo == titulo &&
      other.superficie == superficie &&
      other.procedencia == procedencia &&
      other.estado == estado &&
      other.fecha == fecha &&
      other.consultaId == consultaId &&
      other.doctorId == doctorId &&
      other.notas == notas &&
      other.indiceOrigen == indiceOrigen &&
      other.vigente == vigente;

  @override
  int get hashCode => Object.hash(
    id,
    fdi,
    clave,
    tipo,
    titulo,
    superficie,
    procedencia,
    estado,
    fecha,
    consultaId,
    doctorId,
    notas,
    indiceOrigen,
    vigente,
  );
}

/// Todo lo anotado sobre una pieza, en los cuatro ejes, ordenado de lo más
/// firme a lo más antiguo.
///
/// [hallazgosHistoricos] es el respaldo proyectado del odontodiagrama: solo se
/// usa cuando la pieza no trae `diagnosticosHistoricos` cargados, porque esa
/// proyección pierde fecha, consulta y doctor. Con las entidades disponibles
/// siempre se prefieren ellas.
List<MarcaClinicaPieza> marcasDePieza({
  required int fdi,
  Diente? diente,
  List<ItemPlanTratamiento> itemsPlan = const [],
  List<HallazgoDental> hallazgosHistoricos = const [],
  String Function(String tratamientoId)? nombreTratamiento,
}) {
  final marcas = <MarcaClinicaPieza>[];

  if (diente != null) {
    for (var i = 0; i < diente.diagnosis.length; i++) {
      marcas.add(
        _deDiagnostico(
          fdi,
          diente.diagnosis[i],
          ProcedenciaMarca.evaluado,
          indice: i,
        ),
      );
    }
    for (var i = 0; i < diente.tratamientos.length; i++) {
      marcas.add(
        _deTratamiento(
          fdi,
          diente.tratamientos[i],
          ProcedenciaMarca.ejecutado,
          nombreTratamiento,
          indice: i,
        ),
      );
    }
    for (final diagnostico in diente.diagnosticosHistoricos) {
      marcas.add(_deDiagnostico(fdi, diagnostico, ProcedenciaMarca.historico));
    }
    for (final tratamiento in diente.tratamientosHistoricos) {
      marcas.add(
        _deTratamiento(
          fdi,
          tratamiento,
          ProcedenciaMarca.historico,
          nombreTratamiento,
        ),
      );
    }
    // La ausencia es estado de la pieza, no una fila: sin esto una pieza
    // marcada como ausente no aparecería en su propia ficha.
    if (diente.estaAusente) {
      marcas.add(
        MarcaClinicaPieza(
          fdi: fdi,
          clave: EstadoClinicoDental.perdida,
          tipo: TipoMarcaClinica.hallazgo,
          titulo: EstadoClinicoDental.perdida.label,
          procedencia: ProcedenciaMarca.evaluado,
          estado: 'Pieza ausente',
        ),
      );
    }
  }

  if (diente == null || diente.diagnosticosHistoricos.isEmpty) {
    for (final hallazgo in hallazgosHistoricos) {
      if (hallazgo.superficies.isEmpty) {
        marcas.add(_deHallazgo(fdi, hallazgo, null));
      } else {
        for (final superficie in hallazgo.superficies) {
          marcas.add(_deHallazgo(fdi, hallazgo, superficie));
        }
      }
    }
  }

  for (final item in itemsPlan) {
    marcas.add(
      MarcaClinicaPieza(
        id: item.id,
        fdi: fdi,
        clave: null,
        tipo: TipoMarcaClinica.procedimiento,
        titulo:
            item.nombreTratamiento ??
            nombreTratamiento?.call(item.tratamientoId) ??
            'Tratamiento',
        superficie: item.superficie,
        procedencia: ProcedenciaMarca.planificado,
        estado: item.estado.etiqueta,
        fecha: _fechaDelPlan(item),
        doctorId: item.doctorProponeId,
        notas: item.notas,
        vigente: !_planSinVigencia.contains(item.estado),
      ),
    );
  }

  marcas.sort((a, b) {
    final porProcedencia = b.procedencia.prioridadVisual.compareTo(
      a.procedencia.prioridadVisual,
    );
    if (porProcedencia != 0) return porProcedencia;
    final fechaA = a.fecha;
    final fechaB = b.fecha;
    if (fechaA == null || fechaB == null) return 0;
    return fechaB.compareTo(fechaA);
  });
  return marcas;
}

/// La marca que colorea la cara [cara], o `null` si la cara no tiene nada.
///
/// Solo cuentan las marcas de esa cara concreta: una clave de pieza completa
/// —una `X` de pérdida, un conducto— no tiñe las cinco caras, igual que en el
/// papel no se sombrea el diente entero por anotarla.
MarcaClinicaPieza? marcaDeSuperficie(
  Iterable<MarcaClinicaPieza> marcas,
  TipoSuperficie cara,
) {
  MarcaClinicaPieza? mejor;
  for (final marca in marcas) {
    if (marca.superficie != cara || !marca.vigente) continue;
    if (mejor == null ||
        marca.procedencia.prioridadVisual > mejor.procedencia.prioridadVisual) {
      mejor = marca;
    }
  }
  return mejor;
}

/// La marca que describe el estado de la pieza entera, o `null` si no tiene
/// nada vigente anotado. Es la que decide de qué color se dibuja el diente.
MarcaClinicaPieza? marcaDominante(Iterable<MarcaClinicaPieza> marcas) {
  MarcaClinicaPieza? mejor;
  for (final marca in marcas) {
    if (!marca.vigente) continue;
    if (mejor == null ||
        marca.procedencia.prioridadVisual > mejor.procedencia.prioridadVisual) {
      mejor = marca;
    }
  }
  return mejor;
}

MarcaClinicaPieza _deDiagnostico(
  int fdi,
  DiagnosticoAplicado diagnostico,
  ProcedenciaMarca procedencia, {
  int? indice,
}) {
  final clave = EstadoClinicoDentalX.fromDb(diagnostico.claveOdontograma);
  return MarcaClinicaPieza(
    id: diagnostico.id,
    indiceOrigen: indice,
    fdi: fdi,
    clave: clave,
    tipo: TipoMarcaClinica.hallazgo,
    titulo: diagnostico.nombreDiagnostico ?? clave?.label ?? 'Hallazgo',
    superficie: diagnostico.superficie,
    procedencia: procedencia,
    estado: diagnostico.severidad.etiqueta,
    fecha: diagnostico.fechaAplicacion,
    consultaId: diagnostico.consultaId,
    doctorId: diagnostico.doctorId,
    notas: diagnostico.notas.isEmpty ? null : diagnostico.notas,
  );
}

MarcaClinicaPieza _deTratamiento(
  int fdi,
  TratamientoAplicado tratamiento,
  ProcedenciaMarca procedencia,
  String Function(String tratamientoId)? nombreTratamiento, {
  int? indice,
}) {
  return MarcaClinicaPieza(
    id: tratamiento.id,
    indiceOrigen: indice,
    fdi: fdi,
    // Sin clave se queda sin clave: no estampa símbolo en el papel, pero sigue
    // tiñendo su cara en azul de procedimiento y apareciendo en la ficha.
    clave: EstadoClinicoDentalX.fromDb(tratamiento.claveOdontograma),
    tipo: TipoMarcaClinica.procedimiento,
    titulo:
        tratamiento.nombreTratamiento ??
        nombreTratamiento?.call(tratamiento.tratamientoId) ??
        'Tratamiento',
    superficie: tratamiento.superficie,
    procedencia: procedencia,
    estado: tratamiento.estaTerminado ? 'Terminado' : 'En proceso',
    fecha: tratamiento.fechaEjecucion ?? tratamiento.fechaAplicacion,
    consultaId: tratamiento.consultaId,
    doctorId: tratamiento.doctorEjecutaId,
    notas: (tratamiento.notas?.isEmpty ?? true) ? null : tratamiento.notas,
  );
}

MarcaClinicaPieza _deHallazgo(
  int fdi,
  HallazgoDental hallazgo,
  TipoSuperficie? superficie,
) => MarcaClinicaPieza(
  fdi: fdi,
  clave: hallazgo.estado,
  tipo: TipoMarcaClinica.hallazgo,
  titulo: hallazgo.estado.label,
  superficie: superficie,
  procedencia: ProcedenciaMarca.historico,
  estado: 'Registrado',
  notas: hallazgo.detalle,
);

/// La fecha que mejor sitúa una actividad del plan: la del último movimiento
/// real de su ciclo de vida, no siempre la de la propuesta.
DateTime _fechaDelPlan(ItemPlanTratamiento item) =>
    item.fechaCompletado ??
    item.fechaInicio ??
    item.fechaRechazo ??
    item.fechaAceptacion ??
    item.fechaPropuesta;

/// Estados del plan que ya no describen trabajo por hacer.
const _planSinVigencia = {EstadoItemPlan.rechazado, EstadoItemPlan.cancelado};
