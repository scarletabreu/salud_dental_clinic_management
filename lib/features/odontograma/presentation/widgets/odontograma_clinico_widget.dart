import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';

/// Representación clínica reutilizable. Solo recibe datos y emite cambios:
/// no conoce cubits, repositorios ni Supabase.
class OdontogramaClinicoWidget extends StatefulWidget {
  final Odontograma odontograma;
  final bool editable;
  final bool modoImpresion;
  final List<EntradaLeyendaOdontograma> leyenda;
  final ValueChanged<Map<int, HallazgoDental>>? onHallazgosChanged;
  final ValueChanged<Map<TejidoBlando, EvaluacionTejidoBlando>>?
  onTejidosChanged;

  const OdontogramaClinicoWidget({
    super.key,
    required this.odontograma,
    this.editable = false,
    this.modoImpresion = false,
    this.leyenda = leyendaOdontogramaPredeterminada,
    this.onHallazgosChanged,
    this.onTejidosChanged,
  });

  @override
  State<OdontogramaClinicoWidget> createState() =>
      _OdontogramaClinicoWidgetState();
}

class _OdontogramaClinicoWidgetState extends State<OdontogramaClinicoWidget> {
  Denticion _denticion = Denticion.permanente;
  EstadoClinicoDental _estadoActivo = EstadoClinicoDental.caries;

  EntradaLeyendaOdontograma _entrada(EstadoClinicoDental estado) =>
      widget.leyenda.firstWhere(
        (item) => item.estado == estado,
        orElse: () => leyendaOdontogramaPredeterminada.firstWhere(
          (item) => item.estado == estado,
        ),
      );

  void _marcar(int fdi) {
    if (!widget.editable) return;
    final nuevos = Map<int, HallazgoDental>.from(widget.odontograma.hallazgos);
    if (nuevos[fdi]?.estado == _estadoActivo) {
      nuevos.remove(fdi);
    } else {
      nuevos[fdi] = HallazgoDental(estado: _estadoActivo);
    }
    widget.onHallazgosChanged?.call(nuevos);
  }

  Future<void> _editarTejido(TejidoBlando tejido) async {
    if (!widget.editable) return;
    final actual = widget.odontograma.tejidosBlandos[tejido];
    var condicion = actual?.condicion ?? CondicionTejidoBlando.sinAlteracion;
    final observacion = TextEditingController(text: actual?.observacion);
    final resultado = await showDialog<EvaluacionTejidoBlando>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(tejido.label),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<CondicionTejidoBlando>(
                  segments: const [
                    ButtonSegment(
                      value: CondicionTejidoBlando.sinAlteracion,
                      label: Text('Normal'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment(
                      value: CondicionTejidoBlando.conAlteracion,
                      label: Text('Alterado'),
                      icon: Icon(Icons.error_outline),
                    ),
                  ],
                  selected: {condicion},
                  onSelectionChanged: (value) =>
                      setDialogState(() => condicion = value.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: observacion,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Observación clínica',
                    hintText: 'Describe el hallazgo, ubicación y aspecto',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                EvaluacionTejidoBlando(
                  condicion: condicion,
                  observacion: observacion.text,
                ),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (resultado == null) return;
    final nuevos = Map<TejidoBlando, EvaluacionTejidoBlando>.from(
      widget.odontograma.tejidosBlandos,
    );
    nuevos[tejido] = resultado;
    widget.onTejidosChanged?.call(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final surface = widget.modoImpresion ? Colors.white : ac.cardBg;
    return Semantics(
      label: 'Odontograma clínico FDI',
      child: Container(
        color: surface,
        padding: EdgeInsets.all(widget.modoImpresion ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 14),
            if (widget.editable) ...[
              _selectorEstado(context),
              const SizedBox(height: 14),
            ],
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: constraints.maxWidth.clamp(620, 920),
                  child: _diagrama(context),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _leyenda(context),
            const SizedBox(height: 18),
            _tejidosBlandos(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final ac = context.appColors;
    final titulo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Odontograma clínico',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Nomenclatura FDI · vista oclusal compacta',
          style: TextStyle(color: ac.textMuted, fontSize: 11),
        ),
      ],
    );
    final selector = SegmentedButton<Denticion>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: Denticion.permanente, label: Text('Permanente')),
        ButtonSegment(value: Denticion.temporal, label: Text('Temporal')),
      ],
      selected: {_denticion},
      onSelectionChanged: (value) => setState(() => _denticion = value.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
      ),
    );
    if (widget.modoImpresion) return titulo;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titulo, const SizedBox(height: 10), selector],
          );
        }
        return Row(
          children: [
            Expanded(child: titulo),
            selector,
          ],
        );
      },
    );
  }

  Widget _selectorEstado(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final item in widget.leyenda)
          ChoiceChip(
            selected: _estadoActivo == item.estado,
            onSelected: (_) => setState(() => _estadoActivo = item.estado),
            avatar: Icon(item.icon, size: 14, color: item.color),
            label: Text(item.label),
            visualDensity: VisualDensity.compact,
            labelStyle: const TextStyle(fontSize: 10),
          ),
      ],
    );
  }

  Widget _diagrama(BuildContext context) {
    final superior = _denticion == Denticion.permanente
        ? const [
            [18, 17, 16, 15, 14, 13, 12, 11],
            [21, 22, 23, 24, 25, 26, 27, 28],
          ]
        : const [
            [55, 54, 53, 52, 51],
            [61, 62, 63, 64, 65],
          ];
    final inferior = _denticion == Denticion.permanente
        ? const [
            [48, 47, 46, 45, 44, 43, 42, 41],
            [31, 32, 33, 34, 35, 36, 37, 38],
          ]
        : const [
            [85, 84, 83, 82, 81],
            [71, 72, 73, 74, 75],
          ];

    return Column(
      children: [
        _arcada(context, 'MAXILAR', 'C1', 'C2', superior),
        const SizedBox(height: 10),
        _arcada(context, 'MANDÍBULA', 'C4', 'C3', inferior),
      ],
    );
  }

  Widget _arcada(
    BuildContext context,
    String titulo,
    String izquierda,
    String derecha,
    List<List<int>> cuadrantes,
  ) {
    final ac = context.appColors;
    return Column(
      children: [
        Row(
          children: [
            Text(izquierda, style: _quadrantStyle(ac)),
            Expanded(
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ac.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            Text(derecha, style: _quadrantStyle(ac)),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(child: _cuadrante(context, cuadrantes[0])),
            Container(width: 2, height: 58, color: ac.textPrimary),
            Expanded(child: _cuadrante(context, cuadrantes[1])),
          ],
        ),
      ],
    );
  }

  TextStyle _quadrantStyle(AppColors ac) => TextStyle(
    color: ac.primaryBlue,
    fontSize: 10,
    fontWeight: FontWeight.w800,
  );

  Widget _cuadrante(BuildContext context, List<int> piezas) {
    return Row(
      children: [
        for (final fdi in piezas) Expanded(child: _pieza(context, fdi)),
      ],
    );
  }

  Widget _pieza(BuildContext context, int fdi) {
    final ac = context.appColors;
    final hallazgo = widget.odontograma.hallazgos[fdi];
    final entrada = hallazgo == null ? null : _entrada(hallazgo.estado);
    return Semantics(
      button: widget.editable,
      label:
          'Pieza $fdi${hallazgo == null ? ', sin hallazgo' : ', ${hallazgo.estado.label}'}',
      child: InkWell(
        key: ValueKey('pieza_fdi_$fdi'),
        onTap: widget.editable ? () => _marcar(fdi) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              Text(
                '$fdi',
                style: TextStyle(
                  color: entrada?.color ?? ac.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: entrada?.color.withValues(alpha: 0.12) ?? Colors.white,
                  border: Border.all(
                    color: entrada?.color ?? ac.divider,
                    width: entrada == null ? 1 : 1.7,
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: entrada == null
                    ? Icon(
                        Icons.crop_square_rounded,
                        size: 17,
                        color: ac.textDisabled,
                      )
                    : Icon(entrada.icon, size: 17, color: entrada.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leyenda(BuildContext context) {
    final ac = context.appColors;
    return Wrap(
      spacing: 12,
      runSpacing: 7,
      children: [
        for (final item in widget.leyenda)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 12, color: item.color),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: TextStyle(color: ac.textSecondary, fontSize: 10),
              ),
            ],
          ),
      ],
    );
  }

  Widget _tejidosBlandos(BuildContext context) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evaluación de tejidos blandos',
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tejido in TejidoBlando.values)
              _tejidoChip(context, tejido),
          ],
        ),
      ],
    );
  }

  Widget _tejidoChip(BuildContext context, TejidoBlando tejido) {
    final ac = context.appColors;
    final evaluacion = widget.odontograma.tejidosBlandos[tejido];
    final alterado =
        evaluacion?.condicion == CondicionTejidoBlando.conAlteracion;
    final color = alterado ? ac.red : ac.green;
    return ActionChip(
      key: ValueKey('tejido_${tejido.dbValue}'),
      onPressed: widget.editable ? () => _editarTejido(tejido) : null,
      avatar: Icon(
        alterado ? Icons.error_outline_rounded : Icons.check_circle_outline,
        size: 15,
        color: color,
      ),
      label: Text(
        '${tejido.label}: ${alterado ? 'Alterado' : 'Normal'}'
        '${(evaluacion?.observacion ?? '').isEmpty ? '' : ' · ${evaluacion!.observacion}'}',
      ),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      labelStyle: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
