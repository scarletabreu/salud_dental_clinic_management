import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/cubit/settings_cubit.dart';

class ConfiguracionPage extends StatelessWidget {
  const ConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
            children: [
              _PageHeader(totalSections: 3),

              const SizedBox(height: 28),

              // ── Interfaz y Apariencia ──────────────────────────────────────
              _SectionCard(
                icon: Icons.palette_outlined,
                title: 'Interfaz y Apariencia',
                children: [
                  _SettingRow(
                    icon: Icons.contrast_rounded,
                    label: 'Tema de la Aplicación',
                    subtitle: 'Claro, oscuro o según el sistema',
                    trailing: _StyledDropdown<ThemeMode>(
                      value: state.themeMode,
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Sistema'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Claro'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Oscuro'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          context.read<SettingsCubit>().updateThemeMode(v);
                        }
                      },
                    ),
                  ),
                  _RowDivider(),
                  _SettingRow(
                    icon: Icons.translate_outlined,
                    label: 'Idioma de la Interfaz',
                    subtitle: 'Español o English',
                    trailing: _StyledDropdown<String>(
                      value: state.languageCode,
                      items: const [
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'en', child: Text('English')),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          context.read<SettingsCubit>().updateLanguage(v);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Seguridad ──────────────────────────────────────────────────
              _SectionCard(
                icon: Icons.shield_outlined,
                title: 'Seguridad',
                children: [
                  _SettingRow(
                    icon: Icons.lock_outline_rounded,
                    label: 'Cambiar Contraseña',
                    subtitle: 'Actualiza tu contraseña de acceso',
                    trailing: _ChevronButton(
                      onTap: () {
                        // TODO: navegar
                      },
                    ),
                  ),
                  _RowDivider(),
                  _SwitchSettingRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'Autenticación Biométrica',
                    subtitle: 'Usar huella o Face ID para ingresar',
                    value: false,
                    onChanged: (_) {
                      // TODO: implementar
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Información de la Aplicación ───────────────────────────────
              _SectionCard(
                icon: Icons.info_outline_rounded,
                title: 'Acerca del Sistema',
                children: [
                  _SettingRow(
                    icon: Icons.tag_rounded,
                    label: 'Versión del Sistema',
                    subtitle: 'Build actual instalado',
                    trailing: _VersionBadge(version: '1.0.0', buildNumber: 42),
                  ),
                  _RowDivider(),
                  _SettingRow(
                    icon: Icons.description_outlined,
                    label: 'Términos y Condiciones',
                    subtitle: 'Política de uso y privacidad',
                    trailing: _ChevronButton(
                      icon: Icons.open_in_new_rounded,
                      onTap: () {
                        // TODO: abrir URL
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.totalSections});
  final int totalSections;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Configuración',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ac.primaryBlue.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$totalSections',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ac.primaryBlue,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.tune_rounded,
                          color: ac.primaryBlue,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Personaliza la apariencia, seguridad e información del sistema.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 14, color: ac.primaryBlue),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ac.primaryBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: ac.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.4),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _SwitchSettingRow extends StatelessWidget {
  const _SwitchSettingRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ac.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 70,
      endIndent: 20,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.25),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ac.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ac.primaryBlue.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: ac.primaryBlue,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ac.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dropdownColor: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({this.icon = Icons.chevron_right_rounded, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.version, required this.buildNumber});

  final String version;
  final int buildNumber;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ac.primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$version · b$buildNumber',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: ac.primaryBlue,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
