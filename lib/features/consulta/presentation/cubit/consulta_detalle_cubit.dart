import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/tratamiento_aplicado_detalle.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';

/// Enriquece la consulta para el detalle de solo lectura: resuelve los
/// tratamientos aplicados (nombre + precio congelado) que el odontograma
/// referencia por id, y los nombres de las medicinas recetadas.
class ConsultaDetalleCubit extends Cubit<ConsultaDetalleState> {
  final ConsultaRepository _consultaRepository;
  final IMedicinaRepository _medicinaRepository;
  final CitaRepository _citaRepository;

  ConsultaDetalleCubit(
    this._consultaRepository,
    this._medicinaRepository,
    this._citaRepository,
  ) : super(const ConsultaDetalleCargando());

  Future<void> cargar(Consulta consulta) async {
    emit(const ConsultaDetalleCargando());

    final ids = <String>[
      for (final diente in consulta.odontograma?.dientes ?? const <Diente>[])
        ...diente.tratamientosAplicadosIds,
    ];

    // Cada fuente degrada de forma independiente: el detalle se muestra igual
    // con lo que se haya podido cargar.
    var tratamientos = <String, TratamientoAplicadoDetalle>{};
    var nombresMedicinas = <String, String>{};
    var historialPiezas = HistorialPiezas.vacio;

    if (ids.isNotEmpty) {
      try {
        tratamientos = await _consultaRepository.getDetalleTratamientosAplicados(
          ids,
        );
      } catch (_) {
        tratamientos = {};
      }
    }

    // La historia por pieza es del paciente, no de esta consulta: sin ella la
    // ficha que abre un diente solo contaría lo de este odontograma (SD-144).
    try {
      historialPiezas = await _consultaRepository.getHistorialPiezas(
        consulta.pacienteId,
      );
    } catch (_) {
      historialPiezas = HistorialPiezas.vacio;
    }

    if (consulta.tieneRecetas) {
      try {
        final catalogo = await _medicinaRepository.getCatalogoMedicinas();
        nombresMedicinas = {
          for (final m in catalogo)
            if (m.id != null) m.id!: m.nombre,
        };
      } catch (_) {
        nombresMedicinas = {};
      }
    }

    // La cita de origen hace visible el vínculo que `Consulta.citaId` ya
    // guardaba sin mostrar (SD-160): sin ella el detalle no puede decir de qué
    // hueco de la agenda salió esta visita.
    ReferenciaCita? citaOrigen;
    final citaId = consulta.citaId;
    if (citaId != null && citaId.isNotEmpty) {
      try {
        citaOrigen = await _citaRepository.getReferenciaCita(citaId);
      } catch (_) {
        citaOrigen = null;
      }
    }

    emit(
      ConsultaDetalleListo(
        tratamientos: tratamientos,
        nombresMedicinas: nombresMedicinas,
        historialPiezas: historialPiezas,
        citaOrigen: citaOrigen,
        citaOrigenAusente: citaId != null && citaId.isNotEmpty && citaOrigen == null,
      ),
    );
  }
}

abstract class ConsultaDetalleState extends Equatable {
  const ConsultaDetalleState();

  @override
  List<Object?> get props => [];
}

class ConsultaDetalleCargando extends ConsultaDetalleState {
  const ConsultaDetalleCargando();
}

class ConsultaDetalleListo extends ConsultaDetalleState {
  /// id de `tratamiento_aplicado` → detalle (nombre + precio congelado).
  final Map<String, TratamientoAplicadoDetalle> tratamientos;

  /// id de medicina → nombre del catálogo.
  final Map<String, String> nombresMedicinas;

  /// La línea de tiempo de cada pieza del paciente (SD-144).
  final HistorialPiezas historialPiezas;

  /// Cita de la que nació la consulta. `null` en una atención sin cita.
  final ReferenciaCita? citaOrigen;

  /// La consulta apunta a una cita que ya no se puede leer (eliminada o sin
  /// permiso). Se distingue del walk-in: aquí sí hubo cita y falta.
  final bool citaOrigenAusente;

  const ConsultaDetalleListo({
    this.tratamientos = const {},
    this.nombresMedicinas = const {},
    this.historialPiezas = HistorialPiezas.vacio,
    this.citaOrigen,
    this.citaOrigenAusente = false,
  });

  TratamientoAplicadoDetalle? detalleDe(String tratamientoAplicadoId) =>
      tratamientos[tratamientoAplicadoId];

  String nombreDe(String tratamientoAplicadoId) =>
      tratamientos[tratamientoAplicadoId]?.nombre ?? 'Tratamiento';

  String nombreMedicina(String medicinaId) =>
      nombresMedicinas[medicinaId] ?? 'Medicamento';

  @override
  List<Object?> get props => [
    tratamientos,
    nombresMedicinas,
    historialPiezas.porFdi.length,
    citaOrigen?.id,
    citaOrigen?.estado,
    citaOrigen?.fechaHora,
    citaOrigenAusente,
  ];
}
