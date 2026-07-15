import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/shell/widgets/connectivity_banner.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_list_page.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/pages/inicio_page.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/pacientes_page.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/screens/tratamiento_screen.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/pages/usuarios_list_page.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';
import 'package:salud_dental_clinic_management/shell/widgets/rail_user_card.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_app_bar.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_logo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/pages/equipo_list_page.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/cuentas_por_cobrar_page.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (_) => sl<AuthCubit>()),
        BlocProvider<PacienteCubit>(create: (_) => sl<PacienteCubit>()..load()),
      ],
      child: const _DashboardShellView(),
    );
  }
}

class _DashboardShellView extends StatefulWidget {
  const _DashboardShellView();

  @override
  State<_DashboardShellView> createState() => _DashboardShellViewState();
}

class _DashboardShellViewState extends State<_DashboardShellView> {
  int _selectedIndex = 0;

  late final List<ShellDestination> _allDestinations = [
    ShellDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Inicio',
      builder: (_) => BlocProvider(
        create: (context) {
          final cubit = sl<DashboardCubit>();
          final authState = context.read<AuthCubit>().state;
          final usuario = authState.usuario;
          cubit.load(
            roles: authState.roles,
            doctorId: usuario is Doctor ? usuario.id : null,
            doctorName: usuario is Doctor
                ? '${usuario.nombre} ${usuario.apellido}'
                : null,
          );
          return cubit;
        },
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.usuario != current.usuario,
          listener: (context, authState) {
            final usuario = authState.usuario;
            context.read<DashboardCubit>().load(
              roles: authState.roles,
              doctorId: usuario is Doctor ? usuario.id : null,
              doctorName: usuario is Doctor
                  ? '${usuario.nombre} ${usuario.apellido}'
                  : null,
            );
          },
          child: InicioPage(
            onNavigateToCitas: () => _navigateToLabel('Mis Citas del Día'),
            onNavigateToPacientes: () => _navigateToLabel('Pacientes'),
            onNavigateToMedicinas: () => _navigateToLabel('Medicinas'),
            onNavigateToConfiguracion: () => _navigateToLabel('Configuración'),
          ),
        ),
      ),
    ),
    ShellDestination(
      icon: Icons.today_outlined,
      selectedIcon: Icons.today_rounded,
      label: 'Mis Citas del Día',
      builder: (_) => BlocProvider(
        create: (_) => sl<CitaCubit>()..load(),
        child: const MisCitasDelDiaPage(),
      ),
    ),
    ShellDestination(
      icon: Icons.medical_information_outlined,
      selectedIcon: Icons.medical_information_rounded,
      label: 'Consultas',
      builder: (_) => BlocProvider(
        create: (context) {
          final cubit = sl<ConsultasListCubit>();
          final authState = context.read<AuthCubit>().state;
          final usuario = authState.usuario;
          if (authState.rol == RolUsuario.doctor &&
              usuario is Doctor &&
              usuario.id != null) {
            cubit.cargar(restringidoADoctorId: usuario.id);
          } else {
            cubit.cargar();
          }
          return cubit;
        },
        child: const ConsultasListPage(),
      ),
    ),
    ShellDestination(
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt_rounded,
      label: 'Pacientes',
      builder: (_) => const PacientesPage(),
    ),
    ShellDestination(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Cuentas por Cobrar',
      builder: (_) => BlocProvider(
        create: (_) => sl<CuentasPorCobrarCubit>(),
        child: const CuentasPorCobrarPage(),
      ),
    ),
    ShellDestination(
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings_rounded,
      label: 'Perfiles',
      builder: (_) => BlocProvider(
        create: (_) => sl<PersonalPerfilesCubit>(),
        child: const UsuariosListPage(),
      ),
    ),
    ShellDestination(
      icon: Icons.build_outlined,
      selectedIcon: Icons.build_rounded,
      label: 'Equipos',
      builder: (_) => BlocProvider(
        create: (_) => sl<EquipoCubit>(),
        child: const EquipoListPage(),
      ),
    ),
    ShellDestination(
      icon: Icons.medication_outlined,
      selectedIcon: Icons.medication_rounded,
      label: 'Medicinas',
      builder: (_) => MedicinaListPage(repository: sl<IMedicinaRepository>()),
    ),
    ShellDestination(
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      label: 'Tratamientos',
      builder: (_) => const TratamientosScreen(),
    ),
    ShellDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Configuración',
      builder: (_) => const ConfiguracionPage(),
    ),
  ];

  List<ShellDestination> _visibleDestinations = [];

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _navigateToLabel(String label) {
    final index = _visibleDestinations.indexWhere((d) => d.label == label);
    if (index != -1) _onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.select((AuthCubit cubit) => cubit.state.roles);

    _visibleDestinations = _allDestinations.where((destination) {
      if (roles.isEmpty) return false;
      switch (destination.label) {
        case 'Configuración':
          return roles.contains(RolUsuario.admin) ||
              roles.contains(RolUsuario.doctor) ||
              roles.contains(RolUsuario.asistente);
        case 'Perfiles':
          return roles.contains(RolUsuario.admin);
        case 'Equipos':
          return roles.contains(RolUsuario.admin);
        case 'Consultas':
        case 'Medicinas':
        case 'Tratamientos':
          return roles.contains(RolUsuario.admin) ||
              roles.contains(RolUsuario.doctor);
        case 'Pacientes':
        case 'Mis Citas del Día':
        case 'Cuentas por Cobrar':
          return roles.contains(RolUsuario.admin) ||
              roles.contains(RolUsuario.doctor) ||
              roles.contains(RolUsuario.asistente);
        case 'Inicio':
          return true;
        default:
          return false;
      }
    }).toList();

    if (_selectedIndex >= _visibleDestinations.length) {
      _selectedIndex = 0;
    }

    final width = MediaQuery.sizeOf(context).width;
    final layout = _ShellLayout.forWidth(width);
    final colorScheme = Theme.of(context).colorScheme;

    final content = IndexedStack(
      index: _selectedIndex,
      children: [
        for (final d in _visibleDestinations) Builder(builder: d.builder),
      ],
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: ShellAppBar(
        sectionTitle: _visibleDestinations.isNotEmpty
            ? _visibleDestinations[_selectedIndex].label
            : '',
        compact: layout == _ShellLayout.mobile,
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: SafeArea(
              top: false,
              child: layout == _ShellLayout.mobile
                  ? content
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          _SideRail(
                            extended: layout == _ShellLayout.desktop,
                            destinations: _visibleDestinations,
                            selectedIndex: _selectedIndex,
                            onDestinationSelected: _onDestinationSelected,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: content,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: layout == _ShellLayout.mobile
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: [
                for (final d in _visibleDestinations)
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
      case 'Tratamientos':
        return 'Servicios';
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
  const _SideRail({
    required this.extended,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final bool extended;
  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Container(
      width: extended ? 240 : 76,
      decoration: BoxDecoration(
        color: ac.railBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ac.railDivider.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShellLogo(extended: extended),
          Divider(height: 1, thickness: 0.5, color: ac.railDivider),
          const SizedBox(height: 8),
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
          RailUserCard(extended: extended),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    final bg = selected ? ac.railSelectedBg : Colors.transparent;
    final fg = selected ? ac.railTextSelected : ac.railText;

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
      case 'Tratamientos':
        return 'Servicios';
      default:
        return label;
    }
  }
}
