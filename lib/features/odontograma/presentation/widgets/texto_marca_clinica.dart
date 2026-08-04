import 'package:flutter/material.dart' show Color;
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/marca_clinica_pieza.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Cómo se dice una marca del odontograma: en la ficha de la pieza, en su línea
/// de tiempo y en voz alta. Vive aparte porque las tres la escriben igual y
/// duplicar el formato es lo que hace que una diga «Oclusal» y otra «oclusal».

/// «Resina compuesta · Oclusal», o solo el nombre si la marca es de la pieza
/// entera. La cara es dato clínico: sin ella, dos resinas en el mismo diente se
/// leen como una repetición.
String conSuperficie(String nombre, TipoSuperficie? superficie) =>
    superficie == null ? nombre : '$nombre · ${superficie.name}';

/// Los ocho primeros caracteres de un uuid: lo justo para reconocer la consulta
/// sin llenar la ficha de identificadores.
String referenciaCorta(String id) => id.length > 8 ? id.substring(0, 8) : id;

String fechaCortaDeMarca(DateTime fecha) =>
    '${fecha.day}/${fecha.month}/${fecha.year}';

/// «12 Jun 2026». Se usa donde la fecha encabeza un tramo del historial y tiene
/// que leerse de un vistazo, no compararse dígito a dígito.
String fechaLargaDeMarca(DateTime fecha) {
  const meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];
  final mes = meses[(fecha.month - 1).clamp(0, 11)];
  return '${fecha.day} $mes ${fecha.year}';
}

/// Los antecedentes y lo que ya no se hará se leen más apagados: siguen ahí,
/// pero no describen el estado de hoy.
Color procedenciaAtenuada(MarcaClinicaPieza marca, AppColors ac) =>
    !marca.vigente || marca.procedencia == ProcedenciaMarca.historico
    ? ac.textMuted
    : ac.textSecondary;

/// La fila entera dicha en voz alta, para quien no ve el color ni el trazo.
String descripcionAccesible(
  MarcaClinicaPieza marca, {
  String Function(String doctorId)? nombreDoctor,
}) {
  final cara = marca.superficie == null
      ? 'pieza completa'
      : 'cara ${marca.superficie!.name.toLowerCase()}';
  final partes = <String>[
    '${marca.titulo}, $cara',
    marca.procedencia.etiqueta.toLowerCase(),
    marca.estado.toLowerCase(),
    if (marca.fecha case final fecha?) fechaCortaDeMarca(fecha),
    if (marca.doctorId case final doctorId?)
      if (nombreDoctor?.call(doctorId) case final nombre?
          when nombre.trim().isNotEmpty)
        nombre,
    ?marca.notas,
  ];
  return partes.join('. ');
}
