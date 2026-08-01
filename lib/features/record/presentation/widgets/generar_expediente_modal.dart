import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/pages/expediente_page.dart';

class GenerarExpedienteModal extends StatefulWidget {
  final Paciente paciente;
  final Odontograma? odontogramaActual;
  final List<Consulta> consultasConOdontograma;
  final HistorialPiezas? historialPiezas;

  const GenerarExpedienteModal({
    super.key,
    required this.paciente,
    this.odontogramaActual,
    this.consultasConOdontograma = const [],
    this.historialPiezas,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required Paciente paciente,
    Odontograma? odontogramaActual,
    List<Consulta> consultasConOdontograma = const [],
    HistorialPiezas? historialPiezas,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GenerarExpedienteModal(
        paciente: paciente,
        odontogramaActual: odontogramaActual,
        consultasConOdontograma: consultasConOdontograma,
        historialPiezas: historialPiezas,
      ),
    );
  }

  @override
  State<GenerarExpedienteModal> createState() => _GenerarExpedienteModalState();
}

enum TipoExpedienteImpresion { conOdontograma, sinOdontograma }

class _GenerarExpedienteModalState extends State<GenerarExpedienteModal> {
  TipoExpedienteImpresion _opcionSeleccionada =
      TipoExpedienteImpresion.conOdontograma;

  /// `null` = todo el historial, que es lo que el expediente hacía siempre.
  DateTimeRange? _rango;

  static String _fechaCorta(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/${f.year}';

  Future<void> _elegirRango() async {
    final ahora = DateTime.now();
    final elegido = await showDateRangePicker(
      context: context,
      // El límite inferior cubre cualquier expediente real de la clínica; el
      // superior es hoy, porque no se imprime lo que aún no ha ocurrido.
      firstDate: DateTime(ahora.year - 20),
      lastDate: ahora,
      initialDateRange: _rango,
      helpText: 'Periodo del expediente',
      saveText: 'Aplicar',
    );
    if (elegido != null) setState(() => _rango = elegido);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;
    final nombrePaciente =
        '${widget.paciente.nombre} ${widget.paciente.apellido}';

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
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
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
                          'Generar Expediente Clínico',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          nombrePaciente,
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
                  _OptionTile(
                    key: const Key('expediente_con_odontograma'),
                    titulo: 'Expediente con odontograma',
                    subtitulo:
                        'Incluye el odontograma clínico consolidado del paciente',
                    icono: Icons.layers_rounded,
                    selected:
                        _opcionSeleccionada ==
                        TipoExpedienteImpresion.conOdontograma,
                    onTap: () => setState(
                      () => _opcionSeleccionada =
                          TipoExpedienteImpresion.conOdontograma,
                    ),
                    ac: ac,
                  ),
                  const SizedBox(height: 10),
                  _OptionTile(
                    key: const Key('expediente_sin_odontograma'),
                    titulo: 'Expediente sin odontograma',
                    subtitulo:
                        'Incluye todos los datos clínicos, sin el diagrama dental',
                    icono: Icons.description_rounded,
                    selected:
                        _opcionSeleccionada ==
                        TipoExpedienteImpresion.sinOdontograma,
                    onTap: () => setState(
                      () => _opcionSeleccionada =
                          TipoExpedienteImpresion.sinOdontograma,
                    ),
                    ac: ac,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // El expediente cubría siempre el historial entero: no había forma
            // de imprimir «lo de este año» (defecto D17).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _rango == null
                          ? 'Todo el historial clínico'
                          : 'Del ${_fechaCorta(_rango!.start)} al '
                                '${_fechaCorta(_rango!.end)}',
                      style: TextStyle(fontSize: 13, color: ac.textSecondary),
                    ),
                  ),
                  if (_rango != null)
                    TextButton(
                      key: const Key('expediente_rango_limpiar'),
                      onPressed: () => setState(() => _rango = null),
                      child: const Text('Todo'),
                    ),
                  TextButton.icon(
                    key: const Key('expediente_rango_fechas'),
                    onPressed: _elegirRango,
                    icon: const Icon(Icons.date_range_rounded, size: 18),
                    label: const Text('Elegir periodo'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ExpedientePage.navegar(
                          context,
                          paciente: widget.paciente,
                          odontogramaActual: widget.odontogramaActual,
                          consultasConOdontograma:
                              widget.consultasConOdontograma,
                          historialPiezas: widget.historialPiezas,
                          // Lo que se eligió arriba: hasta ahora se quedaba en
                          // el modal y la pantalla siempre abría «con
                          // odontograma» y con el historial entero.
                          formatoInicial:
                              _opcionSeleccionada ==
                                  TipoExpedienteImpresion.sinOdontograma
                              ? TipoFormatoExpediente.sinOdontograma
                              : TipoFormatoExpediente.conOdontograma,
                          rango: _rango,
                        );
                      },
                      key: const Key('generar_expediente_pdf'),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Generar PDF'),
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

class _OptionTile extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final bool selected;
  final VoidCallback onTap;
  final AppColors ac;

  const _OptionTile({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.selected,
    required this.onTap,
    required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? ac.primaryGreen.withValues(alpha: 0.08) : ac.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? ac.primaryGreen
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              color: selected
                  ? ac.primaryGreen
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? ac.primaryGreen : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? ac.primaryGreen
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
