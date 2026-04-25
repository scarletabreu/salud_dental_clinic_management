import 'package:flutter/material.dart';

enum DoctorAvailability { disponible, ocupado }

class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String sectionTitle;
  final DoctorAvailability availability;
  final ValueChanged<DoctorAvailability> onAvailabilityChanged;
  final bool compact;

  const ShellAppBar({
    super.key,
    required this.sectionTitle,
    required this.availability,
    required this.onAvailabilityChanged,
    this.compact = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(
              sectionTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 16),
            if (!compact) _AvailabilityToggle(
              value: availability,
              onChanged: onAvailabilityChanged,
            ),
            const Spacer(),
            if (!compact) const _DoctorChip(),
            if (compact)
              PopupMenuButton<DoctorAvailability>(
                tooltip: 'Disponibilidad',
                icon: Icon(
                  availability == DoctorAvailability.disponible
                      ? Icons.check_circle_rounded
                      : Icons.do_not_disturb_on_rounded,
                  color: availability == DoctorAvailability.disponible
                      ? Colors.green.shade600
                      : colorScheme.error,
                ),
                onSelected: onAvailabilityChanged,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: DoctorAvailability.disponible,
                    child: Text('Disponible'),
                  ),
                  PopupMenuItem(
                    value: DoctorAvailability.ocupado,
                    child: Text('Ocupado'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityToggle extends StatelessWidget {
  final DoctorAvailability value;
  final ValueChanged<DoctorAvailability> onChanged;

  const _AvailabilityToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget pill({
      required DoctorAvailability target,
      required String label,
      required Color dotColor,
    }) {
      final selected = value == target;
      return InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => onChanged(target),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected ? dotColor : colorScheme.outline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(
            target: DoctorAvailability.disponible,
            label: 'Disponible',
            dotColor: Colors.green.shade500,
          ),
          pill(
            target: DoctorAvailability.ocupado,
            label: 'Ocupado',
            dotColor: colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _DoctorChip extends StatelessWidget {
  const _DoctorChip();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Dr. Javier Méndez',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Odontólogo Especialista',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary,
          child: Text(
            'JM',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
