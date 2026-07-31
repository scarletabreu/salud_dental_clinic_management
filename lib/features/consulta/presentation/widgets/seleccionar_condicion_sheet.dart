import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';

/// Registra una condición descubierta durante la consulta (HFX-CLIN-003).
///
/// Pide la condición del catálogo, su severidad y si pasa al expediente. Solo
/// así puede participar en contraindicaciones: una línea de texto libre no
/// cruza con nada.
Future<CondicionDetectada?> seleccionarCondicionDetectada(
  BuildContext context,
  List<Condicion> catalogo,
) {
  return showDialog<CondicionDetectada>(
    context: context,
    builder: (ctx) => _DialogoCondicionDetectada(catalogo: catalogo),
  );
}

class _DialogoCondicionDetectada extends StatefulWidget {
  const _DialogoCondicionDetectada({required this.catalogo});

  final List<Condicion> catalogo;

  @override
  State<_DialogoCondicionDetectada> createState() =>
      _DialogoCondicionDetectadaState();
}

class _DialogoCondicionDetectadaState
    extends State<_DialogoCondicionDetectada> {
  final _busqueda = TextEditingController();
  final _notas = TextEditingController();
  Condicion? _elegida;
  SeveridadCondicion _severidad = SeveridadCondicion.moderada;
  bool _incorporar = true;

  @override
  void dispose() {
    _busqueda.dispose();
    _notas.dispose();
    super.dispose();
  }

  List<Condicion> get _filtradas {
    final texto = _busqueda.text.trim().toLowerCase();
    if (texto.isEmpty) return widget.catalogo;
    return [
      for (final c in widget.catalogo)
        if (c.nombre.toLowerCase().contains(texto)) c,
    ];
  }

  void _confirmar() {
    final elegida = _elegida;
    if (elegida?.id == null) return;
    Navigator.of(context).pop(
      CondicionDetectada(
        condicionId: elegida!.id!,
        condicion: elegida,
        severidad: _severidad,
        notas: _notas.text.trim().isEmpty ? null : _notas.text.trim(),
        incorporarAlExpediente: _incorporar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final filtradas = _filtradas;

    return AppDialog(
      preferredWidth: 460,
      title: Row(
        children: [
          Icon(Icons.medical_information_rounded, size: 20, color: ac.amber),
          const SizedBox(width: 8),
          const Expanded(child: Text('Condición detectada hoy')),
        ],
      ),
      scrollable: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elígela del catálogo para que cuente en contraindicaciones y '
            'alertas desde ahora.',
            style: TextStyle(fontSize: 12.5, color: ac.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar condición…',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: filtradas.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Ninguna condición del catálogo coincide.',
                      style: TextStyle(fontSize: 13, color: ac.textMuted),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtradas.length,
                    itemBuilder: (_, i) {
                      final condicion = filtradas[i];
                      final elegida = condicion.id == _elegida?.id;
                      return ListTile(
                        dense: true,
                        selected: elegida,
                        selectedTileColor: ac.primaryGreen.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        title: Text(
                          condicion.nombre,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                        subtitle: Text(
                          '${condicion.tipo.displayName} · '
                          '${condicion.categoria.displayName}',
                          style: TextStyle(fontSize: 11, color: ac.textMuted),
                        ),
                        trailing: elegida
                            ? Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: ac.primaryGreen,
                              )
                            : null,
                        onTap: () => setState(() => _elegida = condicion),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Severidad',
                style: TextStyle(fontSize: 12.5, color: ac.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<SeveridadCondicion>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    for (final s in SeveridadCondicion.values)
                      ButtonSegment(
                        value: s,
                        label: Text(
                          s.etiqueta,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                  ],
                  selected: {_severidad},
                  onSelectionChanged: (sel) =>
                      setState(() => _severidad = sel.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notas,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notas (opcional)',
              hintText: 'Qué se observó y en qué contexto',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _incorporar,
            onChanged: (v) => setState(() => _incorporar = v ?? false),
            title: const Text(
              'Incorporar al expediente al cerrar',
              style: TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              'Sin esto vale para hoy, pero no queda en el historial.',
              style: TextStyle(fontSize: 11, color: ac.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _elegida == null ? null : _confirmar,
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Registrar condición'),
        ),
      ],
    );
  }
}
