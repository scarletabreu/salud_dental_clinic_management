import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/tarjeta_opcion.dart';

/// Qué se lleva al papel cuando se pulsa imprimir desde el odontodiagrama.
enum AlcanceImpresionOdontodiagrama {
  /// La hoja de esta consulta: una página con el diagrama de hoy.
  consultaActual,

  /// El expediente clínico entero del paciente, con todas sus consultas.
  historialCompleto,
}

/// Pregunta el alcance antes de imprimir.
///
/// El botón del odontodiagrama imprimía siempre la consulta abierta y no había
/// forma de sacar el historial completo desde ahí: para eso había que salir al
/// expediente del paciente. Aquí se decide una cosa o la otra en el mismo sitio.
class HojaAlcanceImpresion extends StatefulWidget {
  final String nombrePaciente;

  /// Motivo por el que el historial no se puede imprimir ahora mismo. Con esto
  /// puesto la opción se ofrece apagada y explicada, en vez de desaparecer.
  final String? avisoHistorial;

  const HojaAlcanceImpresion({
    super.key,
    required this.nombrePaciente,
    this.avisoHistorial,
  });

  /// `null` si se cancela.
  static Future<AlcanceImpresionOdontodiagrama?> elegir(
    BuildContext context, {
    required String nombrePaciente,
    String? avisoHistorial,
  }) {
    return showModalBottomSheet<AlcanceImpresionOdontodiagrama>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HojaAlcanceImpresion(
        nombrePaciente: nombrePaciente,
        avisoHistorial: avisoHistorial,
      ),
    );
  }

  static const keyConsulta = Key('alcance_impresion_consulta');
  static const keyHistorial = Key('alcance_impresion_historial');
  static const keyContinuar = Key('alcance_impresion_continuar');

  @override
  State<HojaAlcanceImpresion> createState() => _HojaAlcanceImpresionState();
}

class _HojaAlcanceImpresionState extends State<HojaAlcanceImpresion> {
  // La consulta abierta es lo que el botón hacía siempre: quien solo quiere su
  // hoja no debe tocar nada más que «Continuar».
  AlcanceImpresionOdontodiagrama _alcance =
      AlcanceImpresionOdontodiagrama.consultaActual;

  bool get _historialDisponible => widget.avisoHistorial == null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ac.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.print_rounded,
                      color: ac.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿Qué deseas imprimir?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.nombrePaciente,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ac.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TarjetaOpcion(
                    key: HojaAlcanceImpresion.keyConsulta,
                    titulo: 'Solo esta consulta',
                    subtitulo:
                        'Una hoja con el odontodiagrama de la consulta abierta',
                    icono: Icons.description_rounded,
                    seleccionada:
                        _alcance ==
                        AlcanceImpresionOdontodiagrama.consultaActual,
                    onTap: () => setState(
                      () => _alcance =
                          AlcanceImpresionOdontodiagrama.consultaActual,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TarjetaOpcion(
                    key: HojaAlcanceImpresion.keyHistorial,
                    titulo: 'Historial clínico completo',
                    subtitulo:
                        widget.avisoHistorial ??
                        'El expediente del paciente con todas sus consultas',
                    icono: Icons.folder_shared_rounded,
                    seleccionada:
                        _alcance ==
                        AlcanceImpresionOdontodiagrama.historialCompleto,
                    onTap: _historialDisponible
                        ? () => setState(
                            () => _alcance = AlcanceImpresionOdontodiagrama
                                .historialCompleto,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      key: HojaAlcanceImpresion.keyContinuar,
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, _alcance),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
