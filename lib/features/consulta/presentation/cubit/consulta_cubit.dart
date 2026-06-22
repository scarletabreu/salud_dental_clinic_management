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

      // 3. Generamos el odontograma en memoria que acompañará la sesión
      final odontograma = Odontograma(
        consultaId: consultaId,
        dientes: kFdiPermanentes.map((fdi) {
          return Diente(
            odontogramaId: '',
            fdiCode: fdi,
            superficies: superficiesParaFdi(fdi)
                .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
                .toList(),
          );
        }).toList(),
      );

      final consultaActiva = consultaInicial.copyWith(
        id: consultaId,
        odontograma: odontograma,
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

  void aplicarTratamiento(Diente diente, TipoSuperficie? superficie, Tratamiento tratamiento) {
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
