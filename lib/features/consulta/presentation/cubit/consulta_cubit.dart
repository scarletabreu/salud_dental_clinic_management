import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/util/app_log.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/referencia_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/alerta_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/resultado_borrador_consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
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
  final SupabaseStorageHelper _storage;
  final CitaRepository _citaRepository;
  final ConsultaRepository _consultaRepository;

  ConsultaCubit(
    this._crearConsulta,
    this._storage,
    this._citaRepository,
    this._consultaRepository,
  ) : super(const ConsultaInactiva());

  static const esperaAutoguardado = Duration(seconds: 3);

  Timer? _autoguardado;
  bool _guardando = false;

  /// Identifica el intento lógico de cierre en curso. Se conserva mientras el
  /// cierre no se confirme: si la respuesta se perdió por red, reintentar con
  /// la misma clave devuelve el resultado existente en vez de descontar
  /// inventario o facturar por segunda vez.
  String? _claveCierre;

  @override
  Future<void> close() {
    _autoguardado?.cancel();
    return super.close();
  }

  void _emitirCambio(Consulta consulta) {
    if (isClosed) return;
    emit(
      ConsultaIniciada(consulta: consulta, guardado: EstadoGuardado.pendiente),
    );
    _autoguardado?.cancel();
    _autoguardado = Timer(esperaAutoguardado, guardarParcial);
  }

  /// Fija sobre el estado en memoria las identidades y la versión que el
  /// servidor confirmó. Sin esto, el siguiente autoguardado volvería a insertar
  /// lo mismo con otro id y la versión enviada nunca coincidiría.
  Consulta _sellarIds(
    Consulta vigente,
    Consulta enviada,
    ResultadoBorradorConsulta confirmado,
  ) {
    // Las alertas las decide el servidor: son las reglas aprobadas aplicadas a
    // lo que quedó guardado, no a lo que la pantalla cree tener.
    final sellada = vigente.copyWith(
      version: confirmado.version,
      alertas: confirmado.alertas,
    );
    final odonto = sellada.odontograma;
    if (odonto == null || confirmado.sinIdentidades) {
      return _sellarRecetas(sellada, enviada, confirmado.recetaIds);
    }

    final enviadaPorFdi = {
      for (final d in enviada.odontograma?.dientes ?? const []) d.fdiCode: d,
    };

    return _sellarRecetas(
      sellada.copyWith(
        odontograma: odonto.copyWith(
          dientes: [
            for (final diente in odonto.dientes)
              _sellarDiente(
                diente,
                enviadaPorFdi[diente.fdiCode],
                confirmado.tratamientosPorFdi[diente.fdiCode],
                confirmado.diagnosticosPorFdi[diente.fdiCode],
              ),
          ],
        ),
      ),
      enviada,
      confirmado.recetaIds,
    );
  }

  /// La receta guardada conserva su id: así el siguiente guardado la actualiza
  /// en su sitio en vez de anularla y crear otra.
  Consulta _sellarRecetas(
    Consulta vigente,
    Consulta enviada,
    List<String> ids,
  ) {
    if (ids.isEmpty) return vigente;
    final actuales = vigente.recetas;
    if (actuales.length != enviada.recetas.length ||
        actuales.length != ids.length) {
      return vigente;
    }
    for (var i = 0; i < actuales.length; i++) {
      if (!identical(actuales[i], enviada.recetas[i])) return vigente;
    }
    return vigente.copyWith(
      recetas: [
        for (var i = 0; i < actuales.length; i++)
          actuales[i].id == null && ids[i].isNotEmpty
              ? actuales[i].copyWith(id: ids[i])
              : actuales[i],
      ],
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
    List<CondicionDetectada> condicionesDetectadas = const [],
    required List<DocumentoAdjunto> adjuntos,
    SignosVitales? signosVitales,
    TipoAtencionClinica tipoAtencion = TipoAtencionClinica.consulta,
  }) async {
    emit(const ConsultaGuardando());
    try {
      // La consulta que nace de una cita se fecha con la hora agendada, no con
      // la del clic (SD-160): si no, una cita de mañana atendida hoy aparecía
      // en el día de hoy y la lista nunca cuadraba con la agenda. El momento
      // real de apertura ya queda en `consultas.created_at`, que lo pone la BD.
      final citaOrigen = await _resolverCitaDeOrigen(citaId);
      final fechaConsulta = citaOrigen?.fechaHora ?? DateTime.now();

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
        fecha: fechaConsulta,
        motivoConsulta: motivoConsulta,
        tempCondiciones: tempCondiciones,
        condicionesDetectadas: condicionesDetectadas,
        documentosClinicos: documentos,
        signosVitales: signosVitales,
        tipoAtencion: tipoAtencion,
      );

      final consultaId = await _crearConsulta(consultaInicial);

      // Ya validado arriba que la transición es legal. Si la cita venía en
      // `enConsulta` no se reescribe: el grafo no admite ese lazo.
      if (citaId != null && citaOrigen?.estado != EstadoCita.enConsulta) {
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

      // Se emite como cambio pendiente a propósito: el primer autoguardado es
      // el que lleva las mediciones y las condiciones detectadas a sus tablas,
      // donde el servidor las valida y el motor de alertas las evalúa.
      _emitirCambio(consultaActiva);
    } catch (e) {
      AppLog.error('crear consulta', e);
      emit(ConsultaError(_mensajeError(e)));
    }
  }

  /// Cita de la que nace la consulta, ya validada. `null` para una atención sin
  /// cita (walk-in), que se fecha con `now()`.
  ///
  /// Se resuelve y se comprueba *antes* de crear la consulta: si la cita no
  /// existe o no puede pasar a `enConsulta`, el fallo ocurre sin haber dejado
  /// una consulta huérfana que nadie reclame. Tampoco se cae a `now()` en
  /// silencio: ese respaldo era justo lo que desfasaba la fecha (SD-160).
  Future<ReferenciaCita?> _resolverCitaDeOrigen(String? citaId) async {
    if (citaId == null) return null;

    final referencia = await _citaRepository.getReferenciaCita(citaId);
    if (referencia == null) {
      throw Exception(
        'La cita de origen ya no existe. Recarga la agenda antes de iniciar '
        'la consulta.',
      );
    }
    final estado = referencia.estado;
    if (estado != EstadoCita.enConsulta &&
        !estado.puedeTransicionarA(EstadoCita.enConsulta)) {
      throw Exception(
        'La cita está "${estado.label}" y no puede pasar a consulta. '
        'Recarga la agenda para ver su estado actual.',
      );
    }
    return referencia;
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

  /// Registra una condición de catálogo descubierta hoy. Cuenta desde este
  /// momento para contraindicaciones y alertas: no espera al cierre.
  void agregarCondicionDetectada(CondicionDetectada condicion) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (actual.condicionesDetectadas.any(
      (c) => c.condicionId == condicion.condicionId,
    )) {
      return;
    }
    _emitirCambio(
      actual.copyWith(
        condicionesDetectadas: [...actual.condicionesDetectadas, condicion],
      ),
    );
  }

  void actualizarCondicionDetectada(int index, CondicionDetectada condicion) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (index < 0 || index >= actual.condicionesDetectadas.length) return;
    final nuevas = [...actual.condicionesDetectadas];
    nuevas[index] = condicion;
    _emitirCambio(actual.copyWith(condicionesDetectadas: nuevas));
  }

  void quitarCondicionDetectada(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (index < 0 || index >= actual.condicionesDetectadas.length) return;
    final nuevas = [...actual.condicionesDetectadas]..removeAt(index);
    _emitirCambio(actual.copyWith(condicionesDetectadas: nuevas));
  }

  /// Ejecución de alcance global o de arcada: no cuelga de ninguna pieza.
  void aplicarTratamientoGeneral(
    Tratamiento tratamiento, {
    String? justificacionClinica,
    String? itemPlanId,
  }) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final aplicado = TratamientoAplicado(
      tratamientoId: tratamiento.id ?? '',
      esContinuo: false,
      estaTerminado: false,
      precioAplicado: tratamiento.costo,
      notas: justificacionClinica,
      itemPlanId: itemPlanId,
      nombreTratamiento: tratamiento.nombre,
      claveOdontograma: tratamiento.claveOdontograma,
      fechaAplicacion: DateTime.now(),
      doctorEjecutaId: actual.doctorId,
      fechaEjecucion: DateTime.now(),
    );
    _emitirCambio(
      actual.copyWith(
        tratamientosGenerales: [...actual.tratamientosGenerales, aplicado],
      ),
    );
  }

  void quitarTratamientoGeneral(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (index < 0 || index >= actual.tratamientosGenerales.length) return;
    final nuevos = [...actual.tratamientosGenerales]..removeAt(index);
    _emitirCambio(actual.copyWith(tratamientosGenerales: nuevos));
  }

  void aplicarDiagnosticoGeneral(
    Diagnosis diagnostico, {
    SeveridadDiagnosis? severidad,
    OrigenMarcaOdontograma origen = OrigenMarcaOdontograma.estaConsulta,
    String notas = '',
  }) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final aplicado = DiagnosticoAplicado(
      diagnosisId: diagnostico.id ?? '',
      severidad: severidad ?? diagnostico.severidadDefault,
      fechaAplicacion: DateTime.now(),
      notas: notas,
      origen: origen,
      doctorId: actual.doctorId,
      nombreDiagnostico: diagnostico.nombre,
      claveOdontograma: diagnostico.claveOdontograma,
    );
    _emitirCambio(
      actual.copyWith(
        diagnosticosGenerales: [...actual.diagnosticosGenerales, aplicado],
      ),
    );
  }

  void quitarDiagnosticoGeneral(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (index < 0 || index >= actual.diagnosticosGenerales.length) return;
    final nuevos = [...actual.diagnosticosGenerales]..removeAt(index);
    _emitirCambio(actual.copyWith(diagnosticosGenerales: nuevos));
  }

  /// Deja constancia de la decisión sobre una alerta y refresca el estado con
  /// lo que el servidor confirmó.
  Future<void> resolverAlerta(
    AlertaClinica alerta, {
    required bool documentada,
    String? justificacion,
  }) async {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    try {
      await _consultaRepository.resolverAlerta(
        alertaId: alerta.id,
        documentada: documentada,
        justificacion: justificacion,
      );
    } catch (e) {
      AppLog.error('resolver alerta clínica', e);
      if (isClosed) return;
      emit(ConsultaError(_mensajeError(e, fallback: _falloAlerta)));
      emit(ConsultaIniciada(consulta: actual));
      return;
    }

    final vigente = state;
    if (isClosed || vigente is! ConsultaIniciada) return;
    emit(
      vigente.copyWith(
        consulta: vigente.consulta.copyWith(
          alertas: [
            for (final a in vigente.consulta.alertas)
              if (a.id == alerta.id)
                a.copyWith(
                  estado: documentada
                      ? EstadoAlerta.documentada
                      : EstadoAlerta.confirmada,
                  justificacion: justificacion,
                )
              else
                a,
          ],
        ),
      ),
    );
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

  void limpiarRecetas() {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    _emitirCambio(actual.copyWith(recetas: const []));
  }

  void agregarItemReceta({
    required ItemReceta itemReceta,
    String? justificacion,
  }) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;

    final List<Receta> recetasVigentes = [...actual.recetas];

    if (recetasVigentes.isEmpty) {
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

  void quitarItemReceta(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (actual.recetas.isEmpty) return;

    final recetaActual = actual.recetas.first;
    final items = [...recetaActual.items];

    if (index < 0 || index >= items.length) return;

    items.removeAt(index);

    if (items.isEmpty) {
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
      final confirmado = await _consultaRepository.guardarBorradorConsulta(
        consultaId: consultaId,
        version: consulta.version,
        odontograma: odontograma,
        recetas: consulta.recetas,
        insumos: consulta.insumosUtilizados,
        notas: consulta.notas,
        signosVitales: consulta.signosVitales,
        condicionesDetectadas: consulta.condicionesDetectadas,
        tratamientosGenerales: consulta.tratamientosGenerales,
        diagnosticosGenerales: consulta.diagnosticosGenerales,
      );
      _guardando = false;
      if (isClosed) return;

      final vigente = state;
      if (vigente is! ConsultaIniciada) return;
      final sellada = _sellarIds(vigente.consulta, consulta, confirmado);
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
      if (e is ConsultaCerradaFailure) {
        // Seguir ofreciendo el workspace sería mentir: el expediente ya cerró.
        emit(ConsultaError(e.message));
        return;
      }
      final vigente = state;
      if (vigente is! ConsultaIniciada) return;
      emit(
        vigente.copyWith(
          guardado: e is ConflictoVersionFailure
              ? EstadoGuardado.conflicto
              : EstadoGuardado.fallido,
          detalleFallo: _detalleFallo(e),
        ),
      );
    }
  }

  /// Cierra la consulta como una sola operación del servidor.
  ///
  /// Antes esto eran cuatro llamadas seguidas —guardar, descontar stock,
  /// finalizar, completar cita— y una interrupción entre dos de ellas dejaba
  /// una consulta cerrada sin cuenta, o inventario descontado sin cierre.
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

    // La clave sobrevive al fallo a propósito: reintentar el mismo cierre es
    // el mismo intento lógico, no uno nuevo.
    final clave = _claveCierre ??= _nuevaClaveCierre(consultaId);

    emit(ConsultaGuardando(consulta: consulta));
    try {
      final cierre = await _consultaRepository.cerrarConsulta(
        consultaId: consultaId,
        version: consulta.version,
        odontograma: odontograma,
        recetas: consulta.recetas,
        insumos: consulta.insumosUtilizados,
        notas: consulta.notas,
        signosVitales: consulta.signosVitales,
        condicionesDetectadas: consulta.condicionesDetectadas,
        tratamientosGenerales: consulta.tratamientosGenerales,
        diagnosticosGenerales: consulta.diagnosticosGenerales,
        idempotenciaKey: clave,
      );

      _guardando = false;
      _claveCierre = null;
      emit(
        ConsultaTerminada(
          consultaId: consultaId,
          cuentaId: cierre.cuentaId,
          montoTotal: cierre.montoTotal,
        ),
      );
    } catch (e) {
      _guardando = false;
      AppLog.error('terminar consulta', e);
      emit(ConsultaError(_mensajeError(e, fallback: _falloCierre)));
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

  /// Cierra una evaluación: mismo cierre transaccional, sin pre-factura. Una
  /// evaluación sin ejecución no cobra nada, y el servidor es quien decide eso.
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
    final clave = _claveCierre ??= _nuevaClaveCierre(consultaId);

    emit(ConsultaGuardando(consulta: consulta));
    try {
      final cierre = await _consultaRepository.cerrarConsulta(
        consultaId: consultaId,
        version: consulta.version,
        odontograma: odontograma,
        recetas: consulta.recetas,
        insumos: consulta.insumosUtilizados,
        notas: consulta.notas,
        signosVitales: consulta.signosVitales,
        condicionesDetectadas: consulta.condicionesDetectadas,
        tratamientosGenerales: consulta.tratamientosGenerales,
        diagnosticosGenerales: consulta.diagnosticosGenerales,
        idempotenciaKey: clave,
      );
      _guardando = false;
      _claveCierre = null;
      emit(
        ConsultaTerminada(
          consultaId: consultaId,
          cuentaId: cierre.cuentaId,
          montoTotal: cierre.montoTotal,
        ),
      );
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

  static const _falloAlerta =
      'No se pudo registrar la decisión sobre la alerta. La consulta sigue '
      'abierta y la alerta continúa pendiente.';

  static const _falloCierre =
      'No se pudo cerrar la consulta. No se descontó inventario ni se generó '
      'la pre-factura; la consulta sigue abierta.';

  String _nuevaClaveCierre(String consultaId) =>
      '$consultaId:${DateTime.now().microsecondsSinceEpoch}';

  /// Explica qué falló sin exponer el payload: el doctor necesita saber qué
  /// operación no pasó, no el detalle interno del servidor.
  String? _detalleFallo(Object e) {
    if (e is ConflictoVersionFailure ||
        e is StockInsuficienteFailure ||
        e is NetworkFailure) {
      return e.toString();
    }
    return null;
  }

  String _mensajeError(
    Object e, {
    String fallback = 'No se pudo registrar la consulta. Inténtalo de nuevo.',
  }) {
    if (e is NetworkFailure) {
      return 'Sin conexión. No se guardó la operación; verifica tu red e inténtalo de nuevo.';
    }
    // Estos fallos ya vienen redactados para el doctor y nombran la operación
    // que no pasó (el insumo sin stock, la sesión que escribió primero).
    // Reemplazarlos por un texto genérico es lo que hacía imposible saber qué
    // corregir.
    if (e is StockInsuficienteFailure ||
        e is ConflictoVersionFailure ||
        e is ConsultaCerradaFailure ||
        e is ValidationFailure) {
      return e.toString();
    }
    final raw = e.toString();
    if (raw.contains('paciente de prueba')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return fallback;
  }
}
