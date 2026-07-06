import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/signos_vitales.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/receta/domain/entities/receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';

/// Documento (radiografía) seleccionado en el formulario, aún sin subir.
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
      // 1. Subir las radiografías a Storage y recolectar sus URLs.
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
            consultaId: '', // lo asigna la BD dentro del RPC
            descripcion: adj.descripcion,
            tipoDocumento: TipoDocumento.radiografia,
            fechaCreacion: DateTime.now(),
            urlArchivo: url,
          ),
        );
      }

      // 2. Crear consulta en BD.
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

      // La cita pasa a EN_CONSULTA.
      if (citaId != null) {
        await _citaRepository.updateCitaEstado(citaId, EstadoCita.enConsulta);
      }

      // 3. Cargamos los tratamientos de consultas anteriores para proyectar el
      //    estado dental acumulado (capa "histórico"). Si falla, la consulta
      //    arranca igual con la boca en blanco: el historial es contexto, no
      //    debe bloquear la atención.
      var historicoPorFdi = const <int, List<TratamientoAplicado>>{};
      try {
        historicoPorFdi = await _consultaRepository
            .getTratamientosHistoricosPorDiente(
          pacienteId,
          excluyendoConsultaId: consultaId,
        );
      } catch (e) {
        if (kDebugMode) debugPrint('No se pudo cargar el historial dental: $e');
      }

      // 4. Generamos el odontograma en memoria que acompañará la sesión.
      final odontograma = Odontograma(
        consultaId: consultaId,
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
      emit(ConsultaIniciada(consulta: actual.copyWith(signosVitales: signos)));
    }
  }

  void actualizarObservaciones(String notas) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      emit(ConsultaIniciada(consulta: actual.copyWith(notas: notas)));
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

      emit(ConsultaIniciada(consulta: actual.copyWith(odontograma: nuevoOdontograma)));
    }
  }

  /// Quita el tratamiento en [index] del diente (solo en memoria; nada se ha
  /// persistido aún mientras la consulta sigue activa).
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

    emit(ConsultaIniciada(consulta: actual.copyWith(odontograma: nuevoOdontograma)));
  }

  /// Marca el tratamiento en [index] como terminado o en proceso.
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

    emit(ConsultaIniciada(consulta: actual.copyWith(odontograma: nuevoOdontograma)));
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

      emit(ConsultaIniciada(consulta: actual.copyWith(odontograma: nuevoOdontograma)));
    }
  }

  void agregarItemReceta(Receta receta) {
    if (state is ConsultaIniciada) {
      final actual = (state as ConsultaIniciada).consulta;
      emit(ConsultaIniciada(consulta: actual.copyWith(recetas: [...actual.recetas, receta])));
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

      final consultaRehidratada = await _rehidratarTratamientos(consulta);

      emit(ConsultaIniciada(consulta: consultaRehidratada));
    } catch (e) {
      if (kDebugMode) debugPrint('Error al reanudar consulta: $e');
      emit(ConsultaError(_mensajeError(e, fallback: 'No se pudo reanudar la consulta.')));
    }
  }

  Future<Consulta> _rehidratarTratamientos(Consulta consulta) async {
    final odonto = consulta.odontograma;
    if (odonto == null) return consulta;

    final ids = <String>{
      for (final diente in odonto.dientes)
        ...diente.tratamientosAplicadosIds,
    };

    if (ids.isEmpty) return consulta;

    final detallePorId = await _consultaRepository.getDetalleTratamientosAplicados(
      ids.toList(),
    );

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
    if (state is! ConsultaIniciada) return;
    
    final consulta = (state as ConsultaIniciada).consulta;
    final consultaId = consulta.id;
    final odontograma = consulta.odontograma;
    
    if (consultaId == null || odontograma == null) return;

    emit(ConsultaGuardando(consulta: consulta));
    try {
      await _consultaRepository.guardarResultadoConsulta(
        consultaId: consultaId,
        odontograma: odontograma,
        notas: consulta.notas,
        pacienteId: consulta.pacienteId,
      );
      emit(ConsultaIniciada(consulta: consulta));
    } catch (e) {
      if (kDebugMode) debugPrint('Error en guardado parcial: $e');
      emit(ConsultaError(_mensajeError(e)));
      emit(ConsultaIniciada(consulta: consulta)); 
    }
  }

  Future<void> terminarConsulta({String? citaId}) async {
    if (state is! ConsultaIniciada) return;
    
    final consulta = (state as ConsultaIniciada).consulta;
    final consultaId = consulta.id;
    final odontograma = consulta.odontograma;
    
    if (consultaId == null || odontograma == null) {
      emit(const ConsultaError('No hay una consulta activa con odontograma.'));
      return;
    }

    emit(ConsultaGuardando(consulta: consulta));
    try {
      await _consultaRepository.guardarResultadoConsulta(
        consultaId: consultaId,
        odontograma: odontograma,
        notas: consulta.notas,
        pacienteId: consulta.pacienteId,
      );
      if (citaId != null) {
        await _citaRepository.updateCitaEstado(citaId, EstadoCita.completada);
      }
      
      emit(const ConsultaTerminada());
    } catch (e) {
      if (kDebugMode) debugPrint('Error al terminar consulta: $e');
      emit(ConsultaError(_mensajeError(e, fallback: 'No se pudo guardar el resultado de la consulta. Inténtalo de nuevo.')));
      emit(ConsultaIniciada(consulta: consulta));
    }
  }

  String _mensajeError(Object e, {String fallback = 'No se pudo registrar la consulta. Inténtalo de nuevo.'}) {
    final raw = e.toString();
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('network') ||
        raw.contains('connection')) {
      return 'Sin conexión. No se guardó la operación; verifica tu red e inténtalo de nuevo.';
    }
    if (raw.contains('paciente de prueba')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return fallback;
  }
}
