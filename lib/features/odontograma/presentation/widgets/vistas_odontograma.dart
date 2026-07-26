import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/leyenda_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/paleta_odontodiagrama.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

enum VistaOdontograma { formulario, arcada }

extension VistaOdontogramaX on VistaOdontograma {
  String get label => switch (this) {
    VistaOdontograma.formulario => 'Formulario',
    VistaOdontograma.arcada => 'Arcada',
  };

  IconData get icono => switch (this) {
    VistaOdontograma.formulario => Icons.table_rows_rounded,
    VistaOdontograma.arcada => Icons.donut_large_rounded,
  };
}

final ValueNotifier<VistaOdontograma> vistaOdontogramaPreferida = ValueNotifier(
  VistaOdontograma.formulario,
);

class SelectorVistaOdontograma extends StatelessWidget {
  final VistaOdontograma vista;
  final ValueChanged<VistaOdontograma> onChanged;

  const SelectorVistaOdontograma({
    super.key,
    required this.vista,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return SegmentedButton<VistaOdontograma>(
      segments: [
        for (final opcion in VistaOdontograma.values)
          ButtonSegment(
            value: opcion,
            icon: Icon(opcion.icono, size: 18),
            label: Text(opcion.label),
            tooltip: switch (opcion) {
              VistaOdontograma.formulario =>
                'Hallazgos por pieza, como en el formulario impreso',
              VistaOdontograma.arcada =>
                'Arcada dibujada, para asignar tratamientos',
            },
          ),
      ],
      selected: {vista},
      showSelectedIcon: false,
      onSelectionChanged: (seleccion) => onChanged(seleccion.first),
      style: SegmentedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        minimumSize: const Size(0, 44),
        visualDensity: VisualDensity.standard,
        selectedBackgroundColor: ac.teal.withValues(alpha: 0.14),
        selectedForegroundColor: ac.teal,
        foregroundColor: ac.textMuted,
        side: BorderSide(color: ac.divider),
      ),
    );
  }
}

class VistasOdontograma extends StatefulWidget {
  final Odontograma odontograma;

  final bool editable;

  final ValueChanged<EvaluacionOdontologica>? onEvaluacionChanged;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool ausente)? onToggleAusente;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)?
  onToggleTratamientoTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;
  final String Function(String doctorId)? nombreDoctor;

  final Map<int, List<ItemPlanTratamiento>> itemsPlan;

  final HistorialPiezas? historialPiezas;

  final void Function(Diente, String)? onNotasPiezaChanged;

  final Widget? accion;

  final Widget? formularioPersonalizado;

  final Widget? pie;

  const VistasOdontograma({
    super.key,
    required this.odontograma,
    this.editable = false,
    this.onEvaluacionChanged,
    this.onAddDiagnosis,
    this.onAddTratamiento,
    this.onToggleAusente,
    this.onQuitarTratamiento,
    this.onToggleTratamientoTerminado,
    this.nombreTratamiento,
    this.nombreDoctor,
    this.itemsPlan = const {},
    this.historialPiezas,
    this.onNotasPiezaChanged,
    this.accion,
    this.formularioPersonalizado,
    this.pie,
  });

  @override
  State<VistasOdontograma> createState() => _VistasOdontogramaState();
}

class _VistasOdontogramaState extends State<VistasOdontograma> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VistaOdontograma>(
      valueListenable: vistaOdontogramaPreferida,
      builder: (context, vista, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              SelectorVistaOdontograma(
                vista: vista,
                onChanged: (nueva) => vistaOdontogramaPreferida.value = nueva,
              ),
              if (widget.accion != null) widget.accion!,
            ],
          ),
          const SizedBox(height: 16),
          switch (vista) {
            VistaOdontograma.formulario =>
              widget.formularioPersonalizado ??
                  OdontodiagramaWidget(
                    evaluacion: widget.odontograma.evaluacionProyectada,
                    historico: widget.odontograma.evaluacionHistorica,
                    editable: widget.editable,
                    onChanged: widget.onEvaluacionChanged,
                    dientes: {
                      for (final diente in widget.odontograma.dientes)
                        diente.fdiCode: diente,
                    },
                    itemsPlan: widget.itemsPlan,
                    historialPiezas: widget.historialPiezas,
                    onNotasPiezaChanged: widget.onNotasPiezaChanged,
                    onAddDiagnosis: widget.onAddDiagnosis,
                    onAddTratamiento: widget.onAddTratamiento,
                    onToggleAusente: widget.onToggleAusente,
                    onQuitarTratamiento: widget.onQuitarTratamiento,
                    onToggleTratamientoTerminado:
                        widget.onToggleTratamientoTerminado,
                    nombreTratamiento: widget.nombreTratamiento,
                    nombreDoctor: widget.nombreDoctor,
                  ),
            VistaOdontograma.arcada => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OdontogramWidget(
                  odontograma: widget.odontograma,
                  editMode: widget.editable,
                  itemsPlan: widget.itemsPlan,
                  historialPiezas: widget.historialPiezas,
                  onNotasPiezaChanged: widget.onNotasPiezaChanged,
                  onAddDiagnosis: widget.onAddDiagnosis,
                  onAddTratamiento: widget.onAddTratamiento,
                  onToggleAusente: widget.onToggleAusente,
                  onQuitarTratamiento: widget.onQuitarTratamiento,
                  onToggleTratamientoTerminado:
                      widget.onToggleTratamientoTerminado,
                  nombreTratamiento: widget.nombreTratamiento,
                  nombreDoctor: widget.nombreDoctor,
                ),
                const SizedBox(height: 16),
                LeyendaOdontograma(paleta: PaletaOdontodiagrama.de(context)),
              ],
            ),
          },
          if (widget.pie != null) ...[const SizedBox(height: 16), widget.pie!],
        ],
      ),
    );
  }
}
