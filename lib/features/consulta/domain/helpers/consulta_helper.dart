import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';

/// Determina si una consulta puede ser eliminada de forma segura.
///
/// Una consulta solo es eliminable si:
/// - Fue creada hoy (misma fecha de creación que la fecha actual)
/// - No tiene tratamientos aplicados
/// - No tiene pre-factura
///
/// Esto protege la integridad de registros clínicos según Ley 172-13.
bool esConsultaEliminable(Consulta consulta) {
  final hoy = DateTime.now();
  final esDeHoy = consulta.fecha.year == hoy.year &&
      consulta.fecha.month == hoy.month &&
      consulta.fecha.day == hoy.day;

  if (!esDeHoy) return false;
  if (consulta.tieneTratamientosAplicados) return false;
  if (consulta.tienePreFactura) return false;

  return true;
}

/// Devuelve una razón legible sobre por qué una consulta no es eliminable.
/// Retorna null si la consulta sí es eliminable.
String? razonNoEliminable(Consulta consulta) {
  if (!esConsultaEliminable(consulta)) {
    final hoy = DateTime.now();
    final esDeHoy = consulta.fecha.year == hoy.year &&
        consulta.fecha.month == hoy.month &&
        consulta.fecha.day == hoy.day;

    if (!esDeHoy) {
      return 'Solo se pueden eliminar consultas creadas hoy.';
    }
    if (consulta.tieneTratamientosAplicados) {
      return 'No se puede eliminar una consulta con tratamientos aplicados.';
    }
    if (consulta.tienePreFactura) {
      return 'No se puede eliminar una consulta con pre-factura generada.';
    }
  }
  return null;
}
