import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_page.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/pages/inicio_page.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/pacientes_page.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';
import 'package:salud_dental_clinic_management/shell/widgets/rail_user_card.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_app_bar.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_logo.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  DoctorAvailability _availability = DoctorAvailability.disponible;

  late final List<ShellDestination> _destinations = [
    ShellDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Inicio',
      builder: (_) => const InicioPage(),
    ),
    ShellDestination(
      icon: Icons.today_outlined,
      selectedIcon: Icons.today_rounded,
      label: 'Mis Citas del Día',
      builder: (_) => const MisCitasDelDiaPage(),
    ),
    ShellDestination(
      icon: Icons.medical_information_outlined,
      selectedIcon: Icons.medical_information_rounded,
      label: 'Consultas',
      builder: (_) => const ConsultasPage(),
    ),
    ShellDestination(
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt_rounded,
      label: 'Pacientes',
      builder: (_) => const PacientesPage(),
    ),
    ShellDestination(
      icon: Icons.medication_outlined,
      selectedIcon: Icons.medication_rounded,
      label: 'Medicinas',
      builder: (_) => MedicinaListPage(repository: sl<IMedicinaRepository>()),
    ),
    ShellDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Configuración',
      builder: (_) => const ConfiguracionPage(),
    ),
  ];

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final layout = _ShellLayout.forWidth(width);
    final colorScheme = Theme.of(context).colorScheme;

    final content = IndexedStack(
      index: _selectedIndex,
      children: [for (final d in _destinations) Builder(builder: d.builder)],
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: ShellAppBar(
        sectionTitle: _destinations[_selectedIndex].label,
        availability: _availability,
        onAvailabilityChanged: (v) => setState(() => _availability = v),
        compact: layout == _ShellLayout.mobile,
      ),
      body: SafeArea(
        top: false,
        child: layout == _ShellLayout.mobile
            ? content
            : Row(
                children: [
                  _SideRail(
                    extended: layout == _ShellLayout.desktop,
                    destinations: _destinations,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                  ),
                  Expanded(child: content),
                ],
              ),
      ),
      bottomNavigationBar: layout == _ShellLayout.mobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: _shortLabel(d.label),
                  ),
              ],
            )
          : null,
    );
  }

  String _shortLabel(String label) {
    switch (label) {
      case 'Mis Citas del Día':
        return 'Citas';
      case 'Configuración':
        return 'Ajustes';
      default:
        return label;
    }
  }
}

enum _ShellLayout {
  desktop,
  tablet,
  mobile;

  static _ShellLayout forWidth(double width) {
    if (width >= 1024) return _ShellLayout.desktop;
    if (width >= 600) return _ShellLayout.tablet;
    return _ShellLayout.mobile;
  }
}

class _SideRail extends StatelessWidget {
  final bool extended;
  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _SideRail({
    required this.extended,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: extended ? 248 : 88,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShellLogo(extended: extended),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  for (int i = 0; i < destinations.length; i++)
                    _RailItem(
                      destination: destinations[i],
                      selected: selectedIndex == i,
                      extended: extended,
                      onTap: () => onDestinationSelected(i),
                    ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          RailUserCard(extended: extended),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final ShellDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bg = selected ? colorScheme.primaryContainer : Colors.transparent;
    final fg = selected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      size: 22,
      color: fg,
    );

    final label = Text(
      destination.label,
      style: textTheme.labelLarge?.copyWith(
        color: fg,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: extended ? '' : destination.label,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: extended ? 14 : 0,
                vertical: extended ? 12 : 14,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: extended
                  ? Row(
                      children: [
                        icon,
                        const SizedBox(width: 14),
                        Expanded(child: label),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(height: 6),
                        Text(
                          _shortRailLabel(destination.label),
                          style: textTheme.labelSmall?.copyWith(
                            color: fg,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String _shortRailLabel(String label) {
    switch (label) {
      case 'Mis Citas del Día':
        return 'Citas';
      case 'Configuración':
        return 'Ajustes';
      default:
        return label;
    }
  }
}
