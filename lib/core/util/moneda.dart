// Formato de moneda para República Dominicana (RD$) sin dependencia de `intl`,
// coherente con la decisión de `fecha_es.dart` de no requerir inicialización de
// locale en el bootstrap.

/// Ej: `RD$ 1,250.00`
String formatMoneda(double monto) {
  final negativo = monto < 0;
  final abs = monto.abs();
  final partes = abs.toStringAsFixed(2).split('.');
  final entero = partes[0];
  final decimales = partes[1];

  // Inserta separadores de miles cada 3 dígitos desde la derecha.
  final buffer = StringBuffer();
  for (var i = 0; i < entero.length; i++) {
    if (i > 0 && (entero.length - i) % 3 == 0) buffer.write(',');
    buffer.write(entero[i]);
  }

  return '${negativo ? '-' : ''}RD\$ $buffer.$decimales';
}
