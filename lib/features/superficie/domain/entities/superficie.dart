import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

class Superficie {
  final String? id;
  final String dienteId;
  final TipoSuperficie tipoSuperficie;
  final String? diagnosisId;
  final List<String> tratamientos;

  Superficie({
    this.id,
    required this.dienteId,
    required this.tipoSuperficie,
    this.diagnosisId,
    this.tratamientos = const [],
  });

  Superficie copyWith({
    String? dienteId,
    TipoSuperficie? tipoSuperficie,
    String? diagnosisId,
    List<String>? tratamientos,
  }) {
    return Superficie(
      id: id,
      dienteId: dienteId ?? this.dienteId,
      tipoSuperficie: tipoSuperficie ?? this.tipoSuperficie,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      tratamientos: tratamientos ?? List.from(this.tratamientos),
    );
  }
}
