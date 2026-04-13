import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class ContraindicacionesCard extends StatelessWidget {
  final List<Contraindicacion> contraindicaciones;

  const ContraindicacionesCard({super.key, required this.contraindicaciones});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.block_rounded, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Contraindicaciones',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onErrorContainer,
                      ),
                ),
                const Spacer(),
                if (contraindicaciones.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${contraindicaciones.length}',
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (contraindicaciones.isEmpty)
              Text(
                'Ninguna registrada',
                style: TextStyle(
                  color: colorScheme.onErrorContainer.withAlpha(153),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...contraindicaciones.map(
                (c) => _ContraindicacionItem(
                  contraindicacion: c,
                  colorScheme: colorScheme,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContraindicacionItem extends StatelessWidget {
  final Contraindicacion contraindicacion;
  final ColorScheme colorScheme;

  const _ContraindicacionItem({
    required this.contraindicacion,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsoluta =
        contraindicacion.tipoContraindicacion == TipoContraindicacion.absoluta;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAbsoluta
                  ? colorScheme.error
                  : colorScheme.error.withAlpha(153),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              contraindicacion.tipoContraindicacion.name,
              style: TextStyle(
                color: colorScheme.onError,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contraindicacion.descripcion,
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
                if (contraindicacion.efectosAdversos.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: contraindicacion.efectosAdversos
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: colorScheme.error.withAlpha(77)),
                            ),
                            child: Text(
                              e.name,
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
