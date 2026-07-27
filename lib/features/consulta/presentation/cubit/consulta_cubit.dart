import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/descontar_stock_por_consumo.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_guardado_odontograma.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/finalizar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/item_receta.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';

class _HistorialDental {
  final Map<int, List<TratamientoAplicado>>? tratamientosPorFdi;
  final Map<int, List<DiagnosticoAplicado>>? diagnosticosPorFdi;
  final EvaluacionOdontologica? evaluacion;

  const _HistorialDental({
    this.tratamientosPorFdi,
    this.diagnosticosPorFdi,
    this.evaluacion,
  });
}

class DocumentoAdjunto {
  final Uint8List bytes;
  final String fileName;
  final String descripcion;

  const DocumentoAdjunto({
    required this.bytes,
    required this.fileName,
    required this.descripcion,
  });
}

class ConsultaCubit extends Cubit<ConsultaState> {
  final CrearConsultaUseCase _crearConsulta;
  final FinalizarConsultaUseCase _finalizarConsulta;
  final SupabaseStorageHelper _storage;
  final CitaRepository _citaRepository;
  final ConsultaRepository _consultaRepository;
  final DescontarStockPorConsumo _descontarStockPorConsumo;

  ConsultaCubit(
    this._crearConsulta,
    this._finalizarConsulta,
    this._storage,
    this._citaRepository,
    this._consultaRepository,
    this._descontarStockPorConsumo,
  ) : super(const ConsultaInactiva());

  static const esperaAutoguardado = Duration(seconds: 3);

  Timer? _autoguardado;
  bool _guardando = false;

  @override
  Future<void> close() {
    _autoguardado?.cancel();
    return super.close();
  }

  /// Registra un cambio clínico en memoria y programa su autoguardado.
  void _emitirCambio(Consulta consulta) {
    if (isClosed) return;
    emit(
      ConsultaIniciada(consulta: consulta, guardado: EstadoGuardado.pendiente),
    );
    _autoguardado?.cancel();
    _autoguardado = Timer(esperaAutoguardado, guardarParcial);
  }

  Consulta _sellarIds(
    Consulta vigente,
    Consulta enviada,
    ResultadoGuardadoOdontograma idsPorFdi,
  ) {
    final odonto = vigente.odontograma;
    if (odonto == null || idsPorFdi.isEmpty) return vigente;

    final enviadaPorFdi = {
      for (final d in enviada.odontograma?.dientes ?? const []) d.fdiCode: d,
    };

    return vigente.copyWith(
      odontograma: odonto.copyWith(
        dientes: [
          for (final diente in odonto.dientes)
            _sellarDiente(
              diente,
              enviadaPorFdi[diente.fdiCode],
              idsPorFdi.tratamientosPorFdi[diente.fdiCode],
              idsPorFdi.diagnosticosPorFdi[diente.fdiCode],
            ),
        ],
      ),
    );
  }

  Diente _sellarDiente(
    Diente vigente,
    Diente? enviado,
    List<String>? ids,
    List<String>? diagnosticosIds,
  ) {
    if (enviado == null) return vigente;
    final actuales = vigente.tratamientos;
    if (ids != null &&
        (actuales.length != enviado.tratamientos.length ||
            actuales.length != ids.length)) {
      return vigente;
    }
    for (var i = 0; i < actuales.length; i++) {
      if (!identical(actuales[i], enviado.tratamientos[i])) return vigente;
    }
    final diagnosticosActuales = vigente.diagnosis;
    final debeSellarDiagnosticos =
        diagnosticosIds != null &&
        diagnosticosActuales.length == enviado.diagnosis.length &&
        diagnosticosActuales.length == diagnosticosIds.length &&
        List.generate(diagnosticosActuales.length, (index) => index).every(
          (index) =>
              identical(diagnosticosActuales[index], enviado.diagnosis[index]),
        );
    return vigente.copyWith(
      tratamientos: [
        for (var i = 0; i < actuales.length; i++)
          actuales[i].id == null && ids != null && ids[i].isNotEmpty
              ? actuales[i].copyWith(id: ids[i])
              : actuales[i],
      ],
      diagnosis: debeSellarDiagnosticos
          ? [
              for (var i = 0; i < diagnosticosActuales.length; i++)
                diagnosticosActuales[i].id == null &&
                        diagnosticosIds[i].isNotEmpty
                    ? diagnosticosActuales[i].copyWith(id: diagnosticosIds[i])
                    : diagnosticosActuales[i],
            ]
          : diagnosticosActuales,
    );
  }

  Future<void> iniciar({
    required String pacienteId,
    required String doctorId,
    String? citaId,
    required String? motivoConsulta,
    required List<String> tempCondiciones,
    required List<DocumentoAdjunto> adjuntos,
    SignosVitales? signosVitales,
    TipoAtencionClinica tipoAtencion = TipoAtencionClinica.consulta,
  }) async {
    emit(const ConsultaGuardando());
    try {
      final documentos = <DocumentoClinico>[];
      for (final adj in adjuntos) {
        final url = await _storage.subirDocumento(
          bytes: adj.bytes,
          fileName: adj.fileName,
          pacienteId: pacienteId,
        );
        documentos.add(
          DocumentoClinico(
            pacienteId: pacienteId,
            consultaId: '',
            descripcion: adj.descripcion,
            tipoDocumento: TipoDocumento.radiografia,
            fechaCreacion: DateTime.now(),
            urlArchivo: url,
          ),
        );
      }

      final consultaInicial = Consulta(
        pacienteId: pacienteId,
        doctorId: doctorId,
        citaId: citaId,
        fecha: DateTime.now(),
        motivoConsulta: motivoConsulta,
        tempCondiciones: tempCondiciones,
        documentosClinicos: documentos,
        signosVitales: signosVitales,
        tipoAtencion: tipoAtencion,
      );

      final consultaId = await _crearConsulta(consultaInicial);

      if (citaId != null) {
        await _citaRepository.updateCitaEstado(citaId, EstadoCita.enConsulta);
      }
      final historial = await _cargarHistorial(
        pacienteId,
        excluyendoConsultaId: consultaId,
      );

      final odontograma = Odontograma(
        consultaId: consultaId,
        evaluacionHistorica:
            historial.evaluacion ?? EvaluacionOdontologica.vacia,
        dientes: kFdiTodas.map((fdi) {
          return Diente(
            odontogramaId: '',
            fdiCode: fdi,
            superficies: superficiesParaFdi(fdi)
                .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
                .toList(),
            tratamientosHistoricos:
                historial.tratamientosPorFdi?[fdi] ?? const [],
            diagnosticosHistoricos:
                historial.diagnosticosPorFdi?[fdi] ?? const [],
          );
        }).toList(),
      );

      final consultaActiva = consultaInicial.copyWith(
        id: consultaId,
        odontograma: odontograma,
        finalizada: false,
      );

      emit(ConsultaIniciada(consulta: consultaActiva));
    } catch (e) {
      AppLog.error('crear consulta', e);
      emit(ConsultaError(_mensajeError(e)));
    }
  }

  Future<_HistorialDental> _cargarHistorial(
    String pacienteId, {
    required String excluyendoConsultaId,
  }) async {
    Map<int, List<TratamientoAplicado>>? tratamientos;
    Map<int, List<DiagnosticoAplicado>>? diagnosticos;
    EvaluacionOdontologica? evaluacion;

    try {
      tratamientos = await _consultaRepository
          .getTratamientosHistoricosPorDiente(
            pacienteId,
            excluyendoConsultaId: excluyendoConsultaId,
          );
    } catch (e) {
      AppLog.error('historial dental', e);
    }
    try {
      diagnosticos = await _consultaRepository
          .getDiagnosticosHistoricosPorDiente(
            pacienteId,
            excluyendoConsultaId: excluyendoConsultaId,
          );
    } catch (e) {
      AppLog.error('hallazgos anteriores', e);
    }
    try {
      evaluacion = await _consultaRepository.getEvaluacionHistorica(
        pacienteId,
        excluyendoConsultaId: excluyendoConsultaId,
      );
    } catch (e) {
      AppLog.error('odontodiagrama anterior', e);
    }

    return _HistorialDental(
      tratamientosPorFdi: tratamientos,
      diagnosticosPorFdi: diagnosticos,
      evaluacion: evaluacion,
    );
  }

  void actualizarSignosVitales(SignosVitales signos) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      _emitirCambio(actual.copyWith(signosVitales: signos));
    }
  }

  void actualizarObservaciones(String notas) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      _emitirCambio(actual.copyWith(notas: notas));
    }
  }

  void aplicarTratamiento(
    Diente diente,
    TipoSuperficie? superficie,
    Tratamiento tratamiento, {
    String? justificacionClinica,
    String? itemPlanId,
    String? justificacionNoPlanificada,
  }) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      final odonto = actual.odontograma;
      if (odonto == null) return;

      final aplicado = TratamientoAplicado(
        tratamientoId: tratamiento.id ?? '',
        esContinuo: false,
        estaTerminado: false,
        superficie: tratamiento.alcance == Alcance.puntual ? superficie : null,
        precioAplicado: tratamiento.costo,
        notas: justificacionClinica,
        itemPlanId: itemPlanId,
        justificacionNoPlanificada: justificacionNoPlanificada,
        nombreTratamiento: tratamiento.nombre,
        claveOdontograma: tratamiento.claveOdontograma,
        fechaAplicacion: DateTime.now(),
        doctorEjecutaId: actual.doctorId,
        fechaEjecucion: DateTime.now(),
      );

      final nuevoOdontograma = odonto.copyWith(
        dientes: odonto.dientes.map((d) {
          if (d.fdiCode == diente.fdiCode) {
            return d.copyWith(tratamientos: [...d.tratamientos, aplicado]);
          }
          return d;
        }).toList(),
      );

      _emitirCambio(actual.copyWith(odontograma: nuevoOdontograma));
    }
  }

  void aplicarDiagnostico(
    Diente diente,
    TipoSuperficie? superficie,
    Diagnosis diagnostico, {
    SeveridadDiagnosis? severidad,
    OrigenMarcaOdontograma origen = OrigenMarcaOdontograma.preexistente,
    String notas = '',
    String? evaluacionId,
  }) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final odontograma = actual.odontograma;
    if (odontograma == null) return;
    final aplicado = DiagnosticoAplicado(
      diagnosisId: diagnostico.id ?? '',
      severidad: severidad ?? diagnostico.severidadDefault,
      fechaAplicacion: DateTime.now(),
      notas: notas,
      superficie: diagnostico.alcance == Alcance.puntual ? superficie : null,
      origen: origen,
      evaluacionId: evaluacionId,
      doctorId: actual.doctorId,
      nombreDiagnostico: diagnostico.nombre,
      claveOdontograma: diagnostico.claveOdontograma,
    );
    final actualizado = odontograma.copyWith(
      dientes: [
        for (final actualDiente in odontograma.dientes)
          if (actualDiente.fdiCode == diente.fdiCode)
            actualDiente.copyWith(
              diagnosis: [...actualDiente.diagnosis, aplicado],
            )
          else
            actualDiente,
      ],
    );
    _emitirCambio(actual.copyWith(odontograma: actualizado));
  }

  void quitarTratamiento(Diente diente, int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final odonto = actual.odontograma;
    if (odonto == null) return;

    final nuevoOdontograma = odonto.copyWith(
      dientes: odonto.dientes.map((d) {
        if (d.fdiCode != diente.fdiCode) return d;
        if (index < 0 || index >= d.tratamientos.length) return d;
        final nuevos = [...d.tratamientos]..removeAt(index);
        return d.copyWith(tratamientos: nuevos);
      }).toList(),
    );

    _emitirCambio(actual.copyWith(odontograma: nuevoOdontograma));
  }

  void marcarTratamientoTerminado(Diente diente, int index, bool terminado) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final odonto = actual.odontograma;
    if (odonto == null) return;

    final nuevoOdontograma = odonto.copyWith(
      dientes: odonto.dientes.map((d) {
        if (d.fdiCode != diente.fdiCode) return d;
        if (index < 0 || index >= d.tratamientos.length) return d;
        final nuevos = [
          for (var i = 0; i < d.tratamientos.length; i++)
            if (i == index)
              d.tratamientos[i].copyWith(
                estaTerminado: terminado,
                estado: terminado
                    ? EstadoTratamientoAplicado.completado
                    : EstadoTratamientoAplicado.enProceso,
              )
            else
              d.tratamientos[i],
        ];
        return d.copyWith(tratamientos: nuevos);
      }).toList(),
    );

    _emitirCambio(actual.copyWith(odontograma: nuevoOdontograma));
  }

  void toggleDienteAusente(Diente diente, bool ausente) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      final odonto = actual.odontograma;
      if (odonto == null) return;

      final nuevoOdontograma = odonto.copyWith(
        dientes: odonto.dientes.map((d) {
          if (d.fdiCode == diente.fdiCode) {
            return d.copyWith(estaAusente: ausente);
          }
          return d;
        }).toList(),
      );

      _emitirCambio(actual.copyWith(odontograma: nuevoOdontograma));
    }
  }

  void agregarInsumo(InsumoUtilizado insumo) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      _emitirCambio(
        actual.copyWith(
          insumosUtilizados: [...actual.insumosUtilizados, insumo],
        ),
      );
    }
  }

  void quitarInsumo(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (index < 0 || index >= actual.insumosUtilizados.length) return;
    final nuevos = [...actual.insumosUtilizados]..removeAt(index);
    _emitirCambio(actual.copyWith(insumosUtilizados: nuevos));
  }

  void actualizarNotasPieza(Diente diente, String notas) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final odonto = actual.odontograma;
    if (odonto == null) return;

    final limpias = notas.trim();
    final nuevas = limpias.isEmpty ? null : limpias;
    final objetivo = odonto.dientes.firstWhere(
      (d) => d.fdiCode == diente.fdiCode,
      orElse: () => diente,
    );
    if (objetivo.observaciones == nuevas) return;

    _emitirCambio(
      actual.copyWith(
        odontograma: odonto.copyWith(
          dientes: [
            for (final d in odonto.dientes)
              if (d.fdiCode == diente.fdiCode)
                Diente(
                  id: d.id,
                  odontogramaId: d.odontogramaId,
                  superficies: d.superficies,
                  tratamientos: d.tratamientos,
                  tratamientosHistoricos: d.tratamientosHistoricos,
                  diagnosticosHistoricos: d.diagnosticosHistoricos,
                  tratamientosAplicadosIds: d.tratamientosAplicadosIds,
                  diagnosis: d.diagnosis,
                  fdiCode: d.fdiCode,
                  observaciones: nuevas,
                  estaAusente: d.estaAusente,
                )
              else
                d,
          ],
        ),
      ),
    );
  }

  void actualizarEvaluacionOdontologica(EvaluacionOdontologica evaluacion) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final odontograma = actual.odontograma;
    if (odontograma == null) return;
    _emitirCambio(
      actual.copyWith(
        odontograma: odontograma.copyWith(
          evaluacion: EvaluacionOdontologica(
            tejidosBlandos: evaluacion.tejidosBlandos,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Manejo Multirrenglón de Recetas Médicas
  // ---------------------------------------------------------------------------

  /// Agrega un fármaco prescrito (renglón/ItemReceta) a la receta de la consulta.
  /// Si aún no existe una receta activa en esta sesión, se genera la cabecera.
  void agregarItemReceta({
    required ItemReceta itemReceta,
    String? justificacion,
  }) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;

    final List<Receta> recetasVigentes = [...actual.recetas];

    if (recetasVigentes.isEmpty) {
      // Crear cabecera inicial con el primer medicamento
      final nuevaReceta = Receta(
        codigoReceta: '',
        consultaId: actual.id ?? '',
        pacienteId: actual.pacienteId,
        doctorId: actual.doctorId,
        fechaEmision: DateTime.now(),
        items: [itemReceta],
        justificacionContraindicaciones: justificacion,
      );
      _emitirCambio(actual.copyWith(recetas: [nuevaReceta]));
    } else {
      // Adjuntar el renglón a la receta en curso
      final recetaExistente = recetasVigentes.first;
      final itemsActualizados = [...recetaExistente.items, itemReceta];
      final recetaActualizada = recetaExistente.copyWith(
        items: itemsActualizados,
        justificacionContraindicaciones:
            justificacion ?? recetaExistente.justificacionContraindicaciones,
      );
      recetasVigentes[0] = recetaActualizada;
      _emitirCambio(actual.copyWith(recetas: recetasVigentes));
    }
  }

  /// Remueve un fármaco prescrito por su índice global.
  void quitarItemReceta(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (actual.recetas.isEmpty) return;

    final recetaActual = actual.recetas.first;
    final items = [...recetaActual.items];

    if (index < 0 || index >= items.length) return;

    items.removeAt(index);

    if (items.isEmpty) {
      // Si no quedan medicamentos, se retira la receta completa
      _emitirCambio(actual.copyWith(recetas: const []));
    } else {
      final recetaActualizada = recetaActual.copyWith(items: items);
      _emitirCambio(actual.copyWith(recetas: [recetaActualizada]));
    }
  }

  Future<void> reanudarConsulta({required String consultaId}) async {
    emit(const ConsultaGuardando());
    try {
      final consulta = await _consultaRepository.getDetalleConsulta(consultaId);
      if (consulta == null) {
        emit(const ConsultaError('No se encontró la consulta para reanudar.'));
        return;
      }

      if (consulta.finalizada) {
        emit(
          const ConsultaError(
            'Esta consulta ya fue finalizada y no puede reanudarse.',
          ),
        );
        return;
      }

      final consultaRehidratada = await _rehidratarTratamientos(consulta);

      emit(
        ConsultaIniciada(consulta: await _conHistorial(consultaRehidratada)),
      );
    } catch (e) {
      AppLog.error('reanudar consulta', e);
      emit(
        ConsultaError(
          _mensajeError(e, fallback: 'No se pudo reanudar la consulta.'),
        ),
      );
    }
  }

  Future<Consulta> _conHistorial(Consulta consulta) async {
    final odonto = consulta.odontograma;
    final consultaId = consulta.id;
    if (odonto == null || consultaId == null) return consulta;

    final historial = await _cargarHistorial(
      consulta.pacienteId,
      excluyendoConsultaId: consultaId,
    );

    final tratamientos = historial.tratamientosPorFdi;
    final diagnosticos = historial.diagnosticosPorFdi;

    return consulta.copyWith(
      odontograma: odonto.copyWith(
        evaluacionHistorica: historial.evaluacion,
        dientes: [
          for (final diente in odonto.dientes)
            diente.copyWith(
              tratamientosHistoricos: tratamientos == null
                  ? null
                  : (tratamientos[diente.fdiCode] ?? const []),
              diagnosticosHistoricos: diagnosticos == null
                  ? null
                  : (diagnosticos[diente.fdiCode] ?? const []),
            ),
        ],
      ),
    );
  }

  Future<Consulta> _rehidratarTratamientos(Consulta consulta) async {
    final odonto = consulta.odontograma;
    if (odonto == null) return consulta;

    final ids = <String>{
      for (final diente in odonto.dientes) ...diente.tratamientosAplicadosIds,
    };

    if (ids.isEmpty) return consulta;

    final detallePorId = await _consultaRepository
        .getDetalleTratamientosAplicados(ids.toList());

    final dientes = odonto.dientes.map((diente) {
      final tratamientos = diente.tratamientosAplicadosIds
          .map((id) => detallePorId[id]?.tratamiento)
          .whereType<TratamientoAplicado>()
          .toList();
      return diente.copyWith(tratamientos: tratamientos);
    }).toList();

    return consulta.copyWith(odontograma: odonto.copyWith(dientes: dientes));
  }

  Future<void> guardarParcial() async {
    final actual = state;
    if (actual is! ConsultaIniciada) return;
    if (_guardando) return;

    final consulta = actual.consulta;
    final consultaId = consulta.id;
    final odontograma = consulta.odontograma;

    if (consultaId == null || odontograma == null) return;

    _autoguardado?.cancel();
    _guardando = true;
    emit(actual.copyWith(guardado: EstadoGuardado.guardando));
    try {
      final idsPorFdi = await _consultaRepository.guardarResultadoConsulta(
        consultaId: consultaId,
        pacienteId: consulta.pacienteId,
        odontograma: odontograma,
        recetas: consulta.recetas,
        notas: consulta.notas,
        finalizada: false,
      );
      _guardando = false;
      if (isClosed) return;

      final vigente = state;
      if (vigente is! ConsultaIniciada) return;
      final sellada = _sellarIds(vigente.consulta, consulta, idsPorFdi);
      final quedaPendiente = !identical(vigente.consulta, consulta);
      emit(
        ConsultaIniciada(
          consulta: sellada,
          guardado: quedaPendiente
              ? EstadoGuardado.pendiente
              : EstadoGuardado.alDia,
        ),
      );
      if (quedaPendiente) {
        _autoguardado = Timer(esperaAutoguardado, guardarParcial);
      }
    } catch (e) {
      _guardando = false;
      AppLog.error('guardado parcial', e);
      if (isClosed) return;
      final vigente = state;
      if (vigente is! ConsultaIniciada) return;
      emit(vigente.copyWith(guardado: EstadoGuardado.fallido));
    }
  }

  Future<void> terminarConsulta() async {
    if (state is! ConsultaIniciada) return;

    final consulta = (state as ConsultaIniciada).consulta;
    final consultaId = consulta.id;
    final odontograma = consulta.odontograma;

    if (consultaId == null || odontograma == null) {
      emit(const ConsultaError('No hay una consulta activa con odontograma.'));
      return;
    }

    _autoguardado?.cancel();
    for (var espera = 0; _guardando && espera < 50; espera++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _guardando = true;

    emit(ConsultaGuardando(consulta: consulta));
    try {
      await _consultaRepository.guardarResultadoConsulta(
        consultaId: consultaId,
        pacienteId: consulta.pacienteId,
        odontograma: odontograma,
        recetas: consulta.recetas,
        notas: consulta.notas,
        finalizada: true,
      );

      if (consulta.insumosUtilizados.isNotEmpty) {
        await _descontarStockPorConsumo(consulta.insumosUtilizados);
      }

      final cuentaId = await _finalizarConsulta(consultaId: consultaId);

      _guardando = false;
      emit(ConsultaTerminada(cuentaId: cuentaId));
    } catch (e) {
      _guardando = false;
      AppLog.error('terminar consulta', e);
      emit(
        ConsultaError(
          _mensajeError(
            e,
            fallback:
                'No se pudo guardar el resultado de la consulta. Inténtalo de nuevo.',
          ),
        ),
      );
      emit(ConsultaIniciada(consulta: consulta));
    }
  }

  Future<void> terminarAtencion() async {
    if (state is! ConsultaIniciada) return;
    final consulta = (state as ConsultaIniciada).consulta;
    final tieneTratamientos =
        consulta.odontograma?.dientes.any(
          (diente) => diente.tratamientos.isNotEmpty,
        ) ??
        false;
    final requiereCierreFinanciero =
        tieneTratamientos || consulta.insumosUtilizados.isNotEmpty;
    if (requiereCierreFinanciero) {
      await terminarConsulta();
    } else {
      await terminarEvaluacion();
    }
  }

  Future<void> terminarEvaluacion() async {
    if (state is! ConsultaIniciada) return;
    final consulta = (state as ConsultaIniciada).consulta;
    final consultaId = consulta.id;
    final odontograma = consulta.odontograma;
    if (consultaId == null || odontograma == null) {
      emit(const ConsultaError('No hay una evaluación activa.'));
      return;
    }

    _autoguardado?.cancel();
    for (var espera = 0; _guardando && espera < 50; espera++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _guardando = true;
    emit(ConsultaGuardando(consulta: consulta));
    try {
      await _consultaRepository.guardarResultadoConsulta(
        consultaId: consultaId,
        pacienteId: consulta.pacienteId,
        odontograma: odontograma,
        recetas: consulta.recetas,
        notas: consulta.notas,
        signosVitales: consulta.signosVitales?.toJson(),
        finalizada: true,
      );
      if (consulta.citaId != null) {
        await _citaRepository.updateCitaEstado(
          consulta.citaId!,
          EstadoCita.completada,
        );
      }
      _guardando = false;
      emit(const ConsultaTerminada());
    } catch (e) {
      _guardando = false;
      AppLog.error('terminar evaluación', e);
      emit(
        ConsultaError(
          _mensajeError(e, fallback: 'No se pudo cerrar la evaluación.'),
        ),
      );
      emit(ConsultaIniciada(consulta: consulta));
    }
  }

  String _mensajeError(
    Object e, {
    String fallback = 'No se pudo registrar la consulta. Inténtalo de nuevo.',
  }) {
    if (e is NetworkFailure) {
      return 'Sin conexión. No se guardó la operación; verifica tu red e inténtalo de nuevo.';
    }
    final raw = e.toString();
    if (raw.contains('paciente de prueba')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return fallback;
  }
}
