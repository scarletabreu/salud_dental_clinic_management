import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/insumo_utilizado.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/finalizar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/descontar_stock_por_consumo.dart';

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

  /// Margen entre el último cambio y la escritura. Corto a propósito: lo que se
  /// pierde en una consulta no se puede reconstruir de memoria.
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

  /// Sella sobre el estado vigente los ids que devolvió la BD.
  ///
  /// Solo se sellan los dientes cuya lista no cambió mientras se escribía —se
  /// comparan por identidad—; si el doctor tocó una pieza justo entonces, esa
  /// se deja como está y el siguiente guardado la reconcilia.
  Consulta _sellarIds(
    Consulta vigente,
    Consulta enviada,
    Map<int, List<String>> idsPorFdi,
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
              idsPorFdi[diente.fdiCode],
            ),
        ],
      ),
    );
  }

  Diente _sellarDiente(Diente vigente, Diente? enviado, List<String>? ids) {
    if (enviado == null || ids == null) return vigente;
    final actuales = vigente.tratamientos;
    if (actuales.length != enviado.tratamientos.length ||
        actuales.length != ids.length) {
      return vigente;
    }
    for (var i = 0; i < actuales.length; i++) {
      if (!identical(actuales[i], enviado.tratamientos[i])) return vigente;
    }
    return vigente.copyWith(
      tratamientos: [
        for (var i = 0; i < actuales.length; i++)
          actuales[i].id == null && ids[i].isNotEmpty
              ? actuales[i].copyWith(id: ids[i])
              : actuales[i],
      ],
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
      );

      final consultaId = await _crearConsulta(consultaInicial);

      if (citaId != null) {
        await _citaRepository.updateCitaEstado(citaId, EstadoCita.enConsulta);
      }
      var historicoPorFdi = const <int, List<TratamientoAplicado>>{};
      var evaluacionHistorica = EvaluacionOdontologica.vacia;
      // El historial es contexto, no un requisito: si falla, la consulta se
      // abre igual y el doctor trabaja sin la capa tenue.
      try {
        historicoPorFdi = await _consultaRepository
            .getTratamientosHistoricosPorDiente(
              pacienteId,
              excluyendoConsultaId: consultaId,
            );
      } catch (e) {
        if (kDebugMode) debugPrint('No se pudo cargar el historial dental: $e');
      }
      try {
        evaluacionHistorica = await _consultaRepository.getEvaluacionHistorica(
          pacienteId,
          excluyendoConsultaId: consultaId,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('No se pudo cargar el odontodiagrama anterior: $e');
        }
      }

      final odontograma = Odontograma(
        consultaId: consultaId,
        evaluacionHistorica: evaluacionHistorica,
        dientes: kFdiPermanentes.map((fdi) {
          return Diente(
            odontogramaId: '',
            fdiCode: fdi,
            superficies: superficiesParaFdi(fdi)
                .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
                .toList(),
            tratamientosHistoricos: historicoPorFdi[fdi] ?? const [],
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
      if (kDebugMode) debugPrint('Error al crear consulta: $e');
      emit(ConsultaError(_mensajeError(e)));
    }
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
  }) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      final odonto = actual.odontograma;
      if (odonto == null) return;

      final aplicado = TratamientoAplicado(
        tratamientoId: tratamiento.id ?? '',
        esContinuo: false,
        estaTerminado: false,
        superficie: superficie,
        precioAplicado: tratamiento.costo,
        notas: justificacionClinica,
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
              d.tratamientos[i].copyWith(estaTerminado: terminado)
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

  /// Anota el odontodiagrama en memoria. Se persiste con el resto de la
  /// consulta al guardar avance o al terminarla, en la misma escritura.
  void actualizarEvaluacionOdontologica(EvaluacionOdontologica evaluacion) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    final odontograma = actual.odontograma;
    if (odontograma == null) return;
    _emitirCambio(
      actual.copyWith(
        odontograma: odontograma.copyWith(evaluacion: evaluacion),
      ),
    );
  }

  void agregarItemReceta(Receta receta) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      _emitirCambio(actual.copyWith(recetas: [...actual.recetas, receta]));
    }
  }

  void quitarItemReceta(int index) {
    if (state is! ConsultaIniciada) return;
    final actual = (state as ConsultaIniciada).consulta;
    if (index < 0 || index >= actual.recetas.length) return;

    final nuevasRecetas = [...actual.recetas]..removeAt(index);
    _emitirCambio(actual.copyWith(recetas: nuevasRecetas));
  }

  Future<void> reanudarConsulta({required String consultaId}) async {
    emit(const ConsultaGuardando());
    try {
      final consulta = await _consultaRepository.getDetalleConsulta(consultaId);
      if (consulta == null) {
        emit(const ConsultaError('No se encontró la consulta para reanudar.'));
        return;
      }

      // Una consulta cerrada ya generó su pre-factura: reabrirla dejaría la
      // clínica y la cuenta emitida contando cosas distintas.
      if (consulta.finalizada) {
        emit(
          const ConsultaError(
            'Esta consulta ya fue finalizada y no puede reanudarse.',
          ),
        );
        return;
      }

      final consultaRehidratada = await _rehidratarTratamientos(consulta);

      emit(ConsultaIniciada(consulta: consultaRehidratada));
    } catch (e) {
      if (kDebugMode) debugPrint('Error al reanudar consulta: $e');
      emit(
        ConsultaError(
          _mensajeError(e, fallback: 'No se pudo reanudar la consulta.'),
        ),
      );
    }
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

  /// Escribe el trabajo clínico sin bloquear la pantalla: el doctor sigue
  /// anotando mientras se guarda, y el estado del guardado se refleja en la
  /// barra de la consulta.
  ///
  /// Lo dispara el autoguardado tras cada cambio y también el botón «Guardar
  /// avance», que ya solo sirve para forzarlo antes de tiempo.
  Future<void> guardarParcial() async {
    final actual = state;
    if (actual is! ConsultaIniciada) return;
    // Una escritura en vuelo no se pisa: al terminar, si quedaron cambios,
    // ella misma reprograma el siguiente guardado.
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
      // Si el doctor anotó algo mientras se escribía, eso sigue pendiente.
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
      if (kDebugMode) debugPrint('Error en guardado parcial: $e');
      if (isClosed) return;
      final vigente = state;
      if (vigente is! ConsultaIniciada) return;
      // El trabajo sigue en memoria y se reintenta solo: se avisa sin sacar al
      // doctor de la consulta.
      emit(vigente.copyWith(guardado: EstadoGuardado.fallido));
      _autoguardado = Timer(esperaAutoguardado, guardarParcial);
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
    // Dos escrituras simultáneas duplicarían tratamientos: si el autoguardado
    // está en vuelo, se espera a que termine antes de cerrar.
    for (var espera = 0; _guardando && espera < 50; espera++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    _guardando = true;

    emit(ConsultaGuardando(consulta: consulta));
    try {
      // 1. Persiste el trabajo clínico pendiente (tratamientos, recetas, notas).
      await _consultaRepository.guardarResultadoConsulta(
        consultaId: consultaId,
        pacienteId: consulta.pacienteId,
        odontograma: odontograma,
        recetas: consulta.recetas,
        notas: consulta.notas,
        finalizada: true,
      );

      // 1.5 Descuenta del inventario los insumos marcados en esta consulta.
      //     Deuda conocida: no es atómico con el paso 2 (ver DescontarStockPorConsumo).
      if (consulta.insumosUtilizados.isNotEmpty) {
        await _descontarStockPorConsumo(consulta.insumosUtilizados);
      }

      // 2. Handoff financiero atómico: la BD genera la pre-factura (cuenta +
      //    ítems) y marca la cita como completada. Devuelve el id de la cuenta.
      final cuentaId = await _finalizarConsulta(consultaId: consultaId);

      _guardando = false;
      emit(ConsultaTerminada(cuentaId: cuentaId));
    } catch (e) {
      _guardando = false;
      if (kDebugMode) debugPrint('Error al terminar consulta: $e');
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

  String _mensajeError(
    Object e, {
    String fallback = 'No se pudo registrar la consulta. Inténtalo de nuevo.',
  }) {
    // El fallo de red llega tipado desde los repositorios migrados: sin
    // string-matching frágil.
    if (e is NetworkFailure) {
      return 'Sin conexión. No se guardó la operación; verifica tu red e inténtalo de nuevo.';
    }
    // Caso especial: la validación de paciente de prueba se lanza como Exception.
    final raw = e.toString();
    if (raw.contains('paciente de prueba')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return fallback;
  }
}
