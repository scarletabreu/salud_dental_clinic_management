import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontodiagrama_widget.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_widget.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Las dos maneras de mirar la misma boca.
enum VistaOdontograma {
  /// El odontodiagrama del formulario en papel: cuatro filas de piezas con sus
  /// claves. Es la vista por defecto porque es la que el doctor conoce.
  formulario,

  /// La arcada dibujada, donde se asignan tratamientos y superficies.
  arcada,
}

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

/// La vista elegida se recuerda durante la sesión: un doctor que prefiere la
/// arcada no quiere volver a cambiarla en cada paciente. No se persiste en
/// disco a propósito —es una preferencia de momento, no un ajuste de la app.
final ValueNotifier<VistaOdontograma> vistaOdontogramaPreferida = ValueNotifier(
  VistaOdontograma.formulario,
);

/// Conmutador entre las dos vistas. Botones anchos y con etiqueta: en tablet
/// hay que poder cambiar de vista con el dedo y sin adivinar el icono.
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
        // 44 px de alto: la barra se toca con el dedo, no con el ratón.
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

/// Las dos vistas del odontograma bajo un mismo selector.
///
/// Antes se apilaban una debajo de otra en tres pantallas distintas, lo que
/// obligaba a desplazarse por dos diagramas para leer una sola boca. Aquí solo
/// se dibuja la elegida, y ambas leen del mismo [Odontograma]: la arcada
/// muestra tratamientos y la capa histórica de tratamientos, el formulario
/// muestra hallazgos y la capa histórica del odontodiagrama.
class VistasOdontograma extends StatefulWidget {
  final Odontograma odontograma;

  /// Habilita anotar en el formulario y editar en la arcada.
  final bool editable;

  final ValueChanged<EvaluacionOdontologica>? onEvaluacionChanged;
  final void Function(Diente, TipoSuperficie?)? onAddDiagnosis;
  final void Function(Diente, TipoSuperficie?)? onAddTratamiento;
  final void Function(Diente, bool ausente)? onToggleAusente;
  final void Function(Diente, int index)? onQuitarTratamiento;
  final void Function(Diente, int index, bool terminado)?
  onToggleTratamientoTerminado;
  final String Function(String tratamientoId)? nombreTratamiento;

  /// Contenido opcional a la derecha del selector (un indicador de carga, un
  /// contador de tratamientos…).
  final Widget? accion;

  /// Sustituye la vista de formulario. El expediente la envuelve en la hoja
  /// capturable para imprimir, sin duplicar el conmutador.
  final Widget? formularioPersonalizado;

  /// Contenido bajo cualquiera de las dos vistas (el desglose de tratamientos
  /// de la consulta, por ejemplo).
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
          // El selector y la acción comparten fila mientras quepan; en un
          // viewport estrecho la acción baja entera en vez de comprimir los
          // botones por debajo del objetivo táctil.
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
                    // Las mismas piezas y los mismos callbacks que la arcada:
                    // el panel de detalle es el mismo widget en las dos vistas.
                    dientes: {
                      for (final diente in widget.odontograma.dientes)
                        diente.fdiCode: diente,
                    },
                    onAddDiagnosis: widget.onAddDiagnosis,
                    onAddTratamiento: widget.onAddTratamiento,
                    onToggleAusente: widget.onToggleAusente,
                    onQuitarTratamiento: widget.onQuitarTratamiento,
                    onToggleTratamientoTerminado:
                        widget.onToggleTratamientoTerminado,
                    nombreTratamiento: widget.nombreTratamiento,
                  ),
            VistaOdontograma.arcada => OdontogramWidget(
              odontograma: widget.odontograma,
              editMode: widget.editable,
              onAddDiagnosis: widget.onAddDiagnosis,
              onAddTratamiento: widget.onAddTratamiento,
              onToggleAusente: widget.onToggleAusente,
              onQuitarTratamiento: widget.onQuitarTratamiento,
              onToggleTratamientoTerminado: widget.onToggleTratamientoTerminado,
              nombreTratamiento: widget.nombreTratamiento,
            ),
          },
          if (widget.pie != null) ...[const SizedBox(height: 16), widget.pie!],
        ],
      ),
    );
  }
}
