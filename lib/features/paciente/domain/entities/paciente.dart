import 'package:salud_dental_clinic_management/core/domain/entities/persona.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Paciente extends Persona {
  final Genero genero;
  final Record record;
  final String trabajo;
  final String referencia;
  final List<Cita> citas;
  final TipoPaciente tipoPaciente;
  final double? peso;
  final double? altura;
  final String? fotoRuta;
  final String? fotoMimeType;
  final int? fotoTamanoBytes;
  final DateTime? fotoActualizadaEn;

  Paciente({
    super.id,
    required super.nombre,
    required super.apellido,
    required super.birthDate,
    required super.govID,
    required super.contactos,
    required super.estatus,
    required this.genero,
    required this.record,
    required this.trabajo,
    required this.referencia,
    required this.citas,
    required this.tipoPaciente,
    this.peso,
    this.altura,
    this.fotoRuta,
    this.fotoMimeType,
    this.fotoTamanoBytes,
    this.fotoActualizadaEn,
  });

  bool get tieneFoto => fotoRuta != null && fotoRuta!.trim().isNotEmpty;

  String? get fotoUrl {
    if (!tieneFoto) return null;

    final ruta = fotoRuta!.trim();
    String urlBase;

    if (ruta.startsWith('http://') || ruta.startsWith('https://')) {
      urlBase = ruta;
    } else {
      urlBase = Supabase.instance.client.storage
          .from('fotos-pacientes')
          .getPublicUrl(ruta);
    }

    if (fotoActualizadaEn != null) {
      final timestamp = fotoActualizadaEn!.millisecondsSinceEpoch;
      return urlBase.contains('?')
          ? '$urlBase&v=$timestamp'
          : '$urlBase?v=$timestamp';
    }

    return urlBase;
  }

  Paciente copyWith({
    String? govID,
    EstatusPersona? estatus,
    Genero? genero,
    Record? record,
    String? trabajo,
    String? referencia,
    List<Cita>? citas,
    TipoPaciente? tipoPaciente,
    double? peso,
    double? altura,
    String? fotoRuta,
    String? fotoMimeType,
    int? fotoTamanoBytes,
    DateTime? fotoActualizadaEn,
  }) {
    return Paciente(
      id: id,
      nombre: nombre,
      apellido: apellido,
      birthDate: birthDate,
      contactos: contactos,
      estatus: estatus ?? this.estatus,
      govID: govID ?? this.govID,
      genero: genero ?? this.genero,
      record: record ?? this.record,
      trabajo: trabajo ?? this.trabajo,
      referencia: referencia ?? this.referencia,
      citas: citas ?? this.citas,
      tipoPaciente: tipoPaciente ?? this.tipoPaciente,
      peso: peso ?? this.peso,
      altura: altura ?? this.altura,
      fotoRuta: fotoRuta ?? this.fotoRuta,
      fotoMimeType: fotoMimeType ?? this.fotoMimeType,
      fotoTamanoBytes: fotoTamanoBytes ?? this.fotoTamanoBytes,
      fotoActualizadaEn: fotoActualizadaEn ?? this.fotoActualizadaEn,
    );
  }
}
