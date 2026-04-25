import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/widgets/siguiente_paciente_card.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buen día';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                _GreetingHeader(greeting: _greeting()),
                const SizedBox(height: 24),
                const SiguientePacienteCard(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth <= 600;
                    const porAutorizar = _EmptyMetricCard(
                      icon: Icons.assignment_outlined,
                      label: 'Por Autorizar',
                    );
                    const productividad = _EmptyMetricCard(
                      icon: Icons.trending_up_rounded,
                      label: 'Productividad Hoy',
                    );

                    if (narrow) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          porAutorizar,
                          SizedBox(height: 16),
                          productividad,
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Expanded(child: porAutorizar),
                          SizedBox(width: 16),
                          Expanded(child: productividad),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Agenda de Hoy',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No hay citas programadas para hoy. Conecta el módulo de Citas para ver la agenda.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  const _GreetingHeader({required this.greeting});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 600;
        final title = RichText(
          text: TextSpan(
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            children: [
              TextSpan(text: '$greeting, '),
              TextSpan(
                text: 'Dr. Méndez',
                style: TextStyle(color: colorScheme.primary),
              ),
            ],
          ),
        );

        final subtitle = Text(
          'Conecta los módulos de pacientes y citas para ver tu resumen diario.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        );

        final cta = FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nueva consulta — disponible próximamente.'),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Nueva Consulta'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 8),
              subtitle,
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: cta),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 8), subtitle],
              ),
            ),
            const SizedBox(width: 24),
            cta,
          ],
        );
      },
    );
  }
}

class _EmptyMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _EmptyMetricCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '—',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Sin datos',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
