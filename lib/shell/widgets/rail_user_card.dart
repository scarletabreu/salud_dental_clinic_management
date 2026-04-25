import 'package:flutter/material.dart';

class RailUserCard extends StatelessWidget {
  final bool extended;

  const RailUserCard({super.key, required this.extended});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.primary,
      child: Text(
        'JM',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: avatar,
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Javier Méndez',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Odontólogo Especialista',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
