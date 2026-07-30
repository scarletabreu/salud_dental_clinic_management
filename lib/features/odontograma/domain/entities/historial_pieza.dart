import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

/// La consulta en la que ocurrió algo sobre una pieza, con lo justo para poder
/// encabezar su tramo de la línea de tiempo.
///
/// No es la [Consulta] entera a propósito: el historial de una pieza se abre
/// desde un panel flotante y no tiene por qué arrastrar recetas, insumos ni el
/// odontograma completo de cada visita del paciente.
class ReferenciaConsulta {
  final String id;
  final DateTime fecha;
  final String? motivo;
  final TipoAtencionClinica tipoAtencion;

  /// Doctor que atendió la visita. Es el respaldo cuando la anotación concreta
  /// no dice quién la hizo (filas anteriores a la auditoría de SD-135).
  final String? doctorId;

  const ReferenciaConsulta({
    required this.id,
    required this.fecha,
    this.motivo,
    this.tipoAtencion = TipoAtencionClinica.consulta,
    this.doctorId,
  });

  @override
  bool operator ==(Object other) =>
      other is ReferenciaConsulta &&
      other.id == id &&
      other.fecha == fecha &&
      other.motivo == motivo &&
      other.tipoAtencion == tipoAtencion &&
      other.doctorId == doctorId;

  @override
  int get hashCode => Object.hash(id, fecha, motivo, tipoAtencion, doctorId);
}

/// Todo lo que se anotó sobre una pieza en una misma visita.
///
/// Agrupar por visita es lo que convierte una lista de filas en una historia:
/// el doctor lee «el 12 de junio se halló caries, se planificó una resina y se
/// ejecutó», no tres listas paralelas que hay que cruzar por fecha.
class VisitaPieza {
  /// La consulta de la que salieron los eventos. `null` cuando la anotación no
  /// cuelga de ninguna —un plan propuesto fuera de consulta— o cuando la
  /// consulta ya no se puede leer.
  final ReferenciaConsulta? consulta;

  /// Cuándo ocurrió. Es la fecha de la consulta si se conoce y, si no, la del
  /// evento más reciente del grupo.
  final DateTime fecha;

  /// De lo evaluado a lo ejecutado, que es el orden en que ocurren las cosas
  /// dentro de una visita.
  final List<MarcaClinicaPieza> eventos;

  const VisitaPieza({
    required this.fecha,
    required this.eventos,
    this.consulta,
  });

  /// Si en esta visita se cobró algo sobre la pieza.
  bool get tienePrecio => eventos.any(
    (e) => e.precio != null && e.procedencia == ProcedenciaMarca.ejecutado,
  );

  @override
  bool operator ==(Object other) =>
      other is VisitaPieza &&
      other.consulta == consulta &&
      other.fecha == fecha &&
      _mismosEventos(other.eventos, eventos);

  @override
  int get hashCode => Object.hash(consulta, fecha, Object.hashAll(eventos));
}

bool _mismosEventos(List<MarcaClinicaPieza> a, List<MarcaClinicaPieza> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class HistorialPieza {
  final int fdi;
  final List<VisitaPieza> visitas;

  const HistorialPieza({required this.fdi, required this.visitas});

  bool get estaVacio => visitas.isEmpty;

  int get totalEventos =>
      visitas.fold(0, (suma, visita) => suma + visita.eventos.length);

  Iterable<MarcaClinicaPieza> get eventos =>
      visitas.expand((visita) => visita.eventos);

  double get totalEjecutado => eventos
      .where(
        (e) =>
            e.procedencia == ProcedenciaMarca.ejecutado &&
            !e.anulada &&
            e.precio != null,
      )
      .fold(0.0, (suma, e) => suma + e.precio!);

  int conteoDe(ProcedenciaMarca procedencia) =>
      eventos.where((e) => e.procedencia == procedencia).length;
}

class HistorialPiezas {
  final Map<int, HistorialPieza> porFdi;
  final Map<String, String> nombrePorDoctorId;

  const HistorialPiezas({
    this.porFdi = const {},
    this.nombrePorDoctorId = const {},
  });

  static const vacio = HistorialPiezas();

  bool get estaVacio => porFdi.isEmpty;
  HistorialPieza? operator [](int fdi) => porFdi[fdi];
  String nombreDoctor(String doctorId) => nombrePorDoctorId[doctorId] ?? '';
  factory HistorialPiezas.consolidar({
    Map<int, List<DiagnosticoAplicado>> diagnosticos = const {},
    Map<int, List<TratamientoAplicado>> tratamientos = const {},
    Map<int, List<ItemPlanTratamiento>> itemsPlan = const {},
    Map<String, ReferenciaConsulta> consultas = const {},
    Map<String, String> nombrePorDoctorId = const {},
    String Function(String tratamientoId)? nombreTratamiento,
  }) {
    final marcasPorFdi = <int, List<MarcaClinicaPieza>>{};

    void agregar(int fdi, MarcaClinicaPieza marca) =>
        marcasPorFdi.putIfAbsent(fdi, () => []).add(marca);

    diagnosticos.forEach((fdi, filas) {
      for (final diagnostico in filas) {
        agregar(
          fdi,
          marcaDeDiagnostico(fdi, diagnostico, ProcedenciaMarca.evaluado),
        );
      }
    });
    tratamientos.forEach((fdi, filas) {
      for (final tratamiento in filas) {
        agregar(
          fdi,
          marcaDeTratamiento(
            fdi,
            tratamiento,
            ProcedenciaMarca.ejecutado,
            nombreTratamiento,
          ),
        );
      }
    });
    itemsPlan.forEach((fdi, filas) {
      for (final item in filas) {
        agregar(fdi, marcaDeItemPlan(fdi, item, nombreTratamiento));
      }
    });

    return HistorialPiezas(
      porFdi: {
        for (final entrada in marcasPorFdi.entries)
          entrada.key: HistorialPieza(
            fdi: entrada.key,
            visitas: _agruparEnVisitas(entrada.value, consultas),
          ),
      },
      nombrePorDoctorId: nombrePorDoctorId,
    );
  }
}

/// Reparte los eventos de una pieza en visitas y las ordena de la más reciente
/// a la más antigua.
List<VisitaPieza> _agruparEnVisitas(
  List<MarcaClinicaPieza> marcas,
  Map<String, ReferenciaConsulta> consultas,
) {
  final grupos = <String, List<MarcaClinicaPieza>>{};
  final referencias = <String, ReferenciaConsulta?>{};
  final fechas = <String, DateTime?>{};

  for (final marca in marcas) {
    final referencia = marca.consultaId == null
        ? null
        : consultas[marca.consultaId];
    final fecha = marca.fecha ?? referencia?.fecha;

    // Con consulta conocida, la clave es la consulta. Sin ella se agrupa por
    // día: dos anotaciones sueltas de la misma fecha son una misma visita a
    // ojos del doctor, y así ninguna queda huérfana de su tramo.
    final clave = referencia != null
        ? 'consulta:${referencia.id}'
        : marca.consultaId != null
        ? 'consulta:${marca.consultaId}'
        : fecha != null
        ? 'dia:${fecha.year}-${fecha.month}-${fecha.day}'
        : 'sin-fecha';

    grupos.putIfAbsent(clave, () => []).add(marca);
    referencias[clave] = referencias[clave] ?? referencia;
    final acumulada = fechas[clave];
    if (fecha != null && (acumulada == null || fecha.isAfter(acumulada))) {
      fechas[clave] = fecha;
    }
  }

  final visitas = [
    for (final entrada in grupos.entries)
      VisitaPieza(
        consulta: referencias[entrada.key],
        // Manda la fecha de la consulta: es la del acto clínico. La del evento
        // solo se usa cuando no hay consulta que lo sitúe.
        fecha:
            referencias[entrada.key]?.fecha ??
            fechas[entrada.key] ??
            DateTime.fromMillisecondsSinceEpoch(0),
        eventos: _ordenarEventos(entrada.value),
      ),
  ];

  visitas.sort((a, b) => b.fecha.compareTo(a.fecha));
  return visitas;
}

/// Dentro de una visita se cuenta en el orden en que ocurren las cosas: qué se
/// halló, qué se decidió y qué se hizo.
List<MarcaClinicaPieza> _ordenarEventos(List<MarcaClinicaPieza> eventos) {
  const orden = {
    ProcedenciaMarca.evaluado: 0,
    ProcedenciaMarca.planificado: 1,
    ProcedenciaMarca.ejecutado: 2,
    ProcedenciaMarca.historico: 3,
  };
  final ordenados = [...eventos];
  ordenados.sort((a, b) {
    final porEje = (orden[a.procedencia] ?? 9).compareTo(
      orden[b.procedencia] ?? 9,
    );
    if (porEje != 0) return porEje;
    final fechaA = a.fecha;
    final fechaB = b.fecha;
    if (fechaA == null || fechaB == null) return 0;
    return fechaA.compareTo(fechaB);
  });
  return ordenados;
}
