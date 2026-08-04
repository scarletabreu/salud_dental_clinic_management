// Utilidades de formato de fecha en español (es-DO) sin dependencia de `intl`,
// para no requerir inicialización de locale en el bootstrap de la app.

const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const List<String> _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Ej: `6 de junio de 2026`
String fechaLargaEs(DateTime fecha) =>
    '${fecha.day} de ${_meses[fecha.month - 1]} de ${fecha.year}';

/// Ej: `6 jun 2026`
String fechaCortaEs(DateTime fecha) =>
    '${fecha.day} ${_mesesCortos[fecha.month - 1]} ${fecha.year}';

/// Ej: `jun`
String mesAbrevEs(DateTime fecha) => _mesesCortos[fecha.month - 1];

/// Ej: `06/06/2026`
String fechaNumericaEs(DateTime fecha) {
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  return '$d/$m/${fecha.year}';
}
