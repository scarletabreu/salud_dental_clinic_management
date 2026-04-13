import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';

class EfectosSecundariosCard extends StatelessWidget {
  final List<EfectoSecundario> efectos;

  const EfectosSecundariosCard({super.key, required this.efectos});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'Efectos secundarios',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondaryContainer,
                      ),
                ),
                const Spacer(),
                if (efectos.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${efectos.length}',
                      style: TextStyle(
                        color: colorScheme.onSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (efectos.isEmpty)
              Text(
                'Ninguno registrado',
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer.withAlpha(153),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: efectos
                    .map(
                      (e) => Chip(
                        label: Text(
                          e.nombre,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        backgroundColor:
                            colorScheme.secondary.withAlpha(38),
                        side: BorderSide(
                          color: colorScheme.secondary.withAlpha(77),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
