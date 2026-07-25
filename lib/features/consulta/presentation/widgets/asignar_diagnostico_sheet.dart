import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/domain/entities/diagnostico_aplicado.dart';

class DiagnosticoSeleccionado {
  final Diagnosis diagnostico;
  final SeveridadDiagnosis severidad;
  final OrigenMarcaOdontograma origen;
  final String notas;

  const DiagnosticoSeleccionado({
    required this.diagnostico,
    required this.severidad,
    required this.origen,
    required this.notas,
  });
}

Future<DiagnosticoSeleccionado?> seleccionarDiagnostico(
  BuildContext context,
  List<Diagnosis> catalogo,
) {
  return showModalBottomSheet<DiagnosticoSeleccionado>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SelectorDiagnostico(catalogo: catalogo),
  );
}

class _SelectorDiagnostico extends StatefulWidget {
  final List<Diagnosis> catalogo;
  const _SelectorDiagnostico({required this.catalogo});

  @override
  State<_SelectorDiagnostico> createState() => _SelectorDiagnosticoState();
}

class _SelectorDiagnosticoState extends State<_SelectorDiagnostico> {
  final _notas = TextEditingController();
  Diagnosis? _seleccionado;
  late SeveridadDiagnosis _severidad;
  var _origen = OrigenMarcaOdontograma.preexistente;

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return SafeArea(
      // El fondo lo pone un Material y no un DecoratedBox: las filas del
      // catálogo son ListTile y pintan su realce sobre el Material más
      // cercano, que sin esto quedaba tapado.
      child: Material(
        color: ac.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .82,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ac.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Asignar diagnóstico',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ac.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'El catálogo define el alcance y el glifo del odontograma.',
                style: TextStyle(fontSize: 12, color: ac.textMuted),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.catalogo.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: ac.divider, height: 1),
                  itemBuilder: (_, index) {
                    final diagnostico = widget.catalogo[index];
                    final seleccionado = diagnostico.id == _seleccionado?.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(diagnostico.nombre),
                      subtitle: Text(
                        diagnostico.alcance == Alcance.puntual
                            ? 'Por superficie'
                            : 'Por pieza',
                      ),
                      trailing: seleccionado
                          ? Icon(Icons.check_circle_rounded, color: ac.indigo)
                          : null,
                      onTap: () => setState(() {
                        _seleccionado = diagnostico;
                        _severidad = diagnostico.severidadDefault;
                      }),
                    );
                  },
                ),
              ),
              if (_seleccionado != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: SeveridadDiagnosis.values.map((severidad) {
                    return ChoiceChip(
                      label: Text(_etiquetaSeveridad(severidad)),
                      selected: _severidad == severidad,
                      onSelected: (_) => setState(() => _severidad = severidad),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                SegmentedButton<OrigenMarcaOdontograma>(
                  segments: const [
                    ButtonSegment(
                      value: OrigenMarcaOdontograma.preexistente,
                      label: Text('Preexistente'),
                    ),
                    ButtonSegment(
                      value: OrigenMarcaOdontograma.estaConsulta,
                      label: Text('Esta consulta'),
                    ),
                  ],
                  selected: {_origen},
                  showSelectedIcon: false,
                  onSelectionChanged: (valor) =>
                      setState(() => _origen = valor.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notas,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nota clínica (opcional)',
                    filled: true,
                    fillColor: ac.searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ac.divider),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _seleccionado == null
                      ? null
                      : () => Navigator.pop(
                          context,
                          DiagnosticoSeleccionado(
                            diagnostico: _seleccionado!,
                            severidad: _severidad,
                            origen: _origen,
                            notas: _notas.text.trim(),
                          ),
                        ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Asignar diagnóstico'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _etiquetaSeveridad(SeveridadDiagnosis severidad) =>
      switch (severidad) {
        SeveridadDiagnosis.leve => 'Leve',
        SeveridadDiagnosis.moderada => 'Moderada',
        SeveridadDiagnosis.grave => 'Grave',
      };
}
