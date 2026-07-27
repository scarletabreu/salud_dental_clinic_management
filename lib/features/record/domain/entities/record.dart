import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/record_condicion.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';

class Record {
  final String? id;
  final String pacienteId;
  final TipoSangre tipoSangre;
  final List<Consulta> consultas;
  final List<Condicion> condiciones;
  final List<RecordCondicion> detallesCondiciones;
  final int cantHijos;
  final List<String> cirugiasPrevias;
  final String historialFamiliar;

  Record({
    this.id,
    required this.pacienteId,
    required this.tipoSangre,
    this.consultas = const [],
    required this.condiciones,
    this.detallesCondiciones = const [],
    this.cantHijos = 0,
    required this.cirugiasPrevias,
    required this.historialFamiliar,
  });

  String get bloodType => tipoSangre.name.toUpperCase();
  List<Condicion> get conditions => condiciones;
  String get history => historialFamiliar;
  int get childrenCount => cantHijos;
  List<String> get surgeries => cirugiasPrevias;

  Record copyWith({
    String? id,
    String? pacienteId,
    TipoSangre? tipoSangre,
    List<Consulta>? consultas,
    List<Condicion>? condiciones,
    List<RecordCondicion>? detallesCondiciones,
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
      detallesCondiciones: detallesCondiciones ?? this.detallesCondiciones,
      cantHijos: cantHijos ?? this.cantHijos,
      cirugiasPrevias: cirugiasPrevias ?? this.cirugiasPrevias,
      historialFamiliar: historialFamiliar ?? this.historialFamiliar,
    );
  }
}
