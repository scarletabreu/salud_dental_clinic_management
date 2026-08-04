import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class ContraindicacionModel extends Contraindicacion {
  ContraindicacionModel({
    super.id,
    required super.condicionId,
    super.medicinaId,
    super.procedimientoId,
    super.tratamientoId,
    required super.descripcion,
    required super.tipoContraindicacion,
    required super.efectosAdversos,
  });

  static String _camelToSnake(String input) {
    return input.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => '_${match.group(1)!.toLowerCase()}',
    );
  }

  static String _snakeToCamel(String input) {
    final parts = input.split('_');
    if (parts.length <= 1) return input;
    return parts.first +
        parts.sublist(1).map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        }).join();
  }

  factory ContraindicacionModel.fromJson(Map<String, dynamic> json) {
    List<String> rawEfectos = [];
    final efectosData = json['efectos_adversos'];

    if (efectosData is List) {
      rawEfectos = efectosData.map((e) => e.toString()).toList();
    } else if (efectosData is String && efectosData.isNotEmpty) {
      final cleaned = efectosData
          .replaceAll('{', '')
          .replaceAll('}', '')
          .trim();
      if (cleaned.isNotEmpty) {
        rawEfectos = cleaned.split(',').map((e) => e.trim()).toList();
      }
    }

    return ContraindicacionModel(
      id: json['id'] as String?,
      condicionId: json['condicion_id'] as String? ?? '',
      medicinaId: json['medicina_id'] as String?,
      procedimientoId: json['procedimiento_id'] as String?,
      tratamientoId: json['tratamiento_id'] as String?,
      descripcion: json['descripcion'] as String? ?? '',
      tipoContraindicacion: TipoContraindicacion.fromKey(
        json['tipo_contraindicacion'] as String? ?? 'relativa',
      ),
      efectosAdversos: rawEfectos.map((e) {
        final normalized = _snakeToCamel(e.replaceAll(' ', '').trim());
        return EfectoAdverso.values.firstWhere(
          (v) => v.name.toLowerCase() == normalized.toLowerCase(),
          orElse: () => EfectoAdverso.fatiga,
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'condicion_id': condicionId,
      'descripcion': descripcion.trim().isEmpty
          ? 'Sin descripción'
          : descripcion.trim(),
      'tipo_contraindicacion': tipoContraindicacion.key,
      'efectos_adversos': efectosAdversos
          .map((e) => _camelToSnake(e.name))
          .toList(),
    };

    if (medicinaId != null &&
        medicinaId!.length == 36 &&
        medicinaId!.contains('-') &&
        medicinaId != '00000000-0000-0000-0000-000000000000') {
      data['medicina_id'] = medicinaId;
    }

    if (procedimientoId != null &&
        procedimientoId!.length == 36 &&
        procedimientoId!.contains('-')) {
      data['procedimiento_id'] = procedimientoId;
    }

    if (tratamientoId != null &&
        tratamientoId!.length == 36 &&
        tratamientoId!.contains('-')) {
      data['tratamiento_id'] = tratamientoId;
    }

    if (id != null && id!.length == 36 && id!.contains('-')) {
      data['id'] = id;
    }

    return data;
  }
}
