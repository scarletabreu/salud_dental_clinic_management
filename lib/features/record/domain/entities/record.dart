import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

class Record {
  final String id;
  final String pacienteId;
  final TipoSangre tipoSangre;
  final List<Consulta> consultas;
  final String condiciones;
  final int cantHijos;
  final List<String> cirugiasPrevias;
  final String historialFamiliar;

  Record({
    required this.id,
    required this.pacienteId,
    required this.tipoSangre,
    this.consultas = const [],
    required this.condiciones,
    this.cantHijos = 0,
    required this.cirugiasPrevias,
    required this.historialFamiliar,
  });

  Record copyWith({
    String? id,
    String? pacienteId,
    TipoSangre? tipoSangre,
    List<Consulta>? consultas,
    String? condiciones,
    int? cantHijos,
    List<String>? cirugiasPrevias,
    String? historialFamiliar,
  }) {
    return Record(
      id: id ?? this.id,
      pacienteId: pacienteId ?? this.pacienteId,
      tipoSangre: tipoSangre ?? this.tipoSangre,
      consultas: consultas ?? this.consultas,
      condiciones: condiciones ?? this.condiciones,
      cantHijos: cantHijos ?? this.cantHijos,
      cirugiasPrevias: cirugiasPrevias ?? this.cirugiasPrevias,
      historialFamiliar: historialFamiliar ?? this.historialFamiliar,
    );
  }
}
