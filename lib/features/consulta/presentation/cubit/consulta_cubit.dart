import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/entities/documento_clinico.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/domain/enums/tipo_documento.dart';

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

  ConsultaCubit(this._crearConsulta, this._storage, this._citaRepository)
    : super(const ConsultaInitial());

  Future<void> crearConsulta({
    required String pacienteId,
    required String doctorId,
    String? citaId,
    required String? motivoConsulta,
    required List<String> tempCondiciones,
    required List<DocumentoAdjunto> adjuntos,
  }) async {
    emit(const ConsultaLoading());
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

      // 2. Crear consulta + odontograma + 32 dientes + superficies + documentos
      //    en una sola operación atómica (RPC).
      final consulta = Consulta(
        pacienteId: pacienteId,
        doctorId: doctorId,
        citaId: citaId,
        fecha: DateTime.now(),
        motivoConsulta: motivoConsulta,
        tempCondiciones: tempCondiciones,
        documentosClinicos: documentos,
      );

      await _crearConsulta(consulta);
      emit(const ConsultaCreada());
    } catch (e) {
      if (kDebugMode) debugPrint('Error al crear consulta: $e');
      emit(ConsultaError(_mensajeError(e)));
    }
  }

  /// Finaliza la consulta. Si proviene de una cita, la marca como completada.
  /// Los pasos posteriores (facturación, recetas) aún no están implementados.
  Future<void> terminarConsulta({String? citaId}) async {
    emit(const ConsultaLoading());
    try {
      if (citaId != null) {
        await _citaRepository.updateCitaEstado(citaId, EstadoCita.completada);
      }
      emit(const ConsultaTerminada());
    } catch (e) {
      if (kDebugMode) debugPrint('Error al terminar consulta: $e');
      emit(ConsultaError(_mensajeError(e)));
    }
  }

  String _mensajeError(Object e) {
    final raw = e.toString();
    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('network') ||
        raw.contains('connection')) {
      return 'Sin conexión. No se registró la consulta; '
          'verifica tu red e inténtalo de nuevo.';
    }
    return 'No se pudo registrar la consulta. Inténtalo de nuevo.';
  }
}
