import 'package:flutter/foundation.dart' show listEquals;
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
import 'package:salud_dental_clinic_management/shell/lazy_destination_stack.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';
import 'package:salud_dental_clinic_management/shell/responsive_shell_layout.dart';
import 'package:salud_dental_clinic_management/shell/widgets/rail_user_card.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_app_bar.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_logo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/pages/equipo_list_page.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/cuentas_por_cobrar_page.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/pages/caja_diaria_page.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_cubit.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/pages/inventario_page.dart';

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
  ShellDestinationId _selectedId = ShellDestinationId.inicio;

  final ConsultasListCubit _consultasListCubit = sl<ConsultasListCubit>();

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final usuario = authState.usuario;
    if (authState.rol == RolUsuario.doctor &&
        usuario is Doctor &&
        usuario.id != null) {
      _consultasListCubit.cargar(restringidoADoctorId: usuario.id);
    } else {
      _consultasListCubit.cargar();
    }
  }

  @override
  void dispose() {
    _consultasListCubit.close();
    super.dispose();
  }

  late final List<ShellDestination> _allDestinations = [
    ShellDestination(
      id: ShellDestinationId.inicio,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Inicio',
      builder: (_) => BlocProvider(
        create: (context) {
          final cubit = sl<DashboardCubit>();
          final authState = context.read<AuthCubit>().state;
          final usuario = authState.usuario;

          String? nombreUsuario;
          if (usuario != null) {
            nombreUsuario = '${usuario.nombre} ${usuario.apellido}'.trim();
          }

          cubit.load(
            roles: authState.roles,
            doctorId: usuario is Doctor ? usuario.id : null,
            doctorName: nombreUsuario,
          );
          return cubit;
        },
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.usuario != current.usuario,
          listener: (context, authState) {
            final usuario = authState.usuario;
            String? nombreUsuario;
            if (usuario != null) {
              nombreUsuario = '${usuario.nombre} ${usuario.apellido}'.trim();
            }

            context.read<DashboardCubit>().load(
              roles: authState.roles,
              doctorId: usuario is Doctor ? usuario.id : null,
              doctorName: nombreUsuario,
            );
          },
          child: InicioPage(
            onNavigateToCitas: () =>
                _navigateTo(ShellDestinationId.citasDelDia),
            onNavigateToPacientes: () =>
                _navigateTo(ShellDestinationId.pacientes),
            onNavigateToMedicinas: () =>
                _navigateTo(ShellDestinationId.medicinas),
            onNavigateToConfiguracion: () =>
                _navigateTo(ShellDestinationId.configuracion),
            onNavigateToInventario: () =>
                _navigateTo(ShellDestinationId.inventario),
            onNavigateToCaja: () => _navigateTo(ShellDestinationId.caja),
          ),
        ),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.citasDelDia,
      icon: Icons.today_outlined,
      selectedIcon: Icons.today_rounded,
      label: 'Mis Citas del Día',
      builder: (_) => BlocProvider(
        create: (_) => sl<CitaCubit>()..load(),
        child: const MisCitasDelDiaPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.consultas,
      icon: Icons.medical_information_outlined,
      selectedIcon: Icons.medical_information_rounded,
      label: 'Consultas',
      builder: (_) => BlocProvider.value(
        value: _consultasListCubit,
        child: const ConsultasListPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.pacientes,
      icon: Icons.people_alt_outlined,
      selectedIcon: Icons.people_alt_rounded,
      label: 'Pacientes',
      builder: (_) => const PacientesPage(),
    ),
    ShellDestination(
      id: ShellDestinationId.cuentasPorCobrar,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Cuentas por Cobrar',
      builder: (_) => BlocProvider(
        create: (_) => sl<CuentasPorCobrarCubit>(),
        child: const CuentasPorCobrarPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.inventario,
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2_rounded,
      label: 'Inventario',
      builder: (_) => BlocProvider(
        create: (_) => sl<InventarioCubit>(),
        child: const InventarioPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.perfiles,
      icon: Icons.admin_panel_settings_outlined,
      selectedIcon: Icons.admin_panel_settings_rounded,
      label: 'Perfiles',
      builder: (_) => BlocProvider(
        create: (_) => sl<PersonalPerfilesCubit>(),
        child: const UsuariosListPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.caja,
      icon: Icons.point_of_sale_outlined,
      selectedIcon: Icons.point_of_sale_rounded,
      label: 'Caja',
      builder: (_) => BlocProvider(
        create: (_) => sl<CajaDiariaCubit>(),
        child: const CajaDiariaPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.equipos,
      icon: Icons.build_outlined,
      selectedIcon: Icons.build_rounded,
      label: 'Equipos',
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => sl<EquipoCubit>()),
          BlocProvider(create: (_) => sl<SuplidorCubit>()),
        ],
        child: const EquipoListPage(),
      ),
    ),
    ShellDestination(
      id: ShellDestinationId.medicinas,
      icon: Icons.medication_outlined,
      selectedIcon: Icons.medication_rounded,
      label: 'Medicinas',
      builder: (_) => MedicinaListPage(repository: sl<IMedicinaRepository>()),
    ),
    ShellDestination(
      id: ShellDestinationId.tratamientos,
      icon: Icons.medical_services_outlined,
      selectedIcon: Icons.medical_services_rounded,
      label: 'Tratamientos',
      builder: (_) => const TratamientosScreen(),
    ),
    ShellDestination(
      id: ShellDestinationId.configuracion,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Configuración',
      builder: (_) => const ConfiguracionPage(),
    ),
  ];

  late final List<ShellSection> _allSections = [
    ShellSection(
      title: 'Atención',
      destinations: _destinationsFor(const [
        ShellDestinationId.inicio,
        ShellDestinationId.citasDelDia,
        ShellDestinationId.consultas,
        ShellDestinationId.pacientes,
      ]),
    ),
    ShellSection(
      title: 'Facturación',
      destinations: _destinationsFor(const [
        ShellDestinationId.cuentasPorCobrar,
        ShellDestinationId.caja,
      ]),
    ),
    ShellSection(
      title: 'Catálogos',
      destinations: _destinationsFor(const [
        ShellDestinationId.tratamientos,
        ShellDestinationId.medicinas,
        ShellDestinationId.inventario,
      ]),
    ),
    ShellSection(
      title: 'Administración',
      destinations: _destinationsFor(const [
        ShellDestinationId.perfiles,
        ShellDestinationId.equipos,
      ]),
    ),
  ];

  List<ShellDestination> _destinationsFor(List<ShellDestinationId> ids) => [
    for (final id in ids)
      _allDestinations.firstWhere((destination) => destination.id == id),
  ];

  ShellDestination get _configuracion => _allDestinations.firstWhere(
    (destination) => destination.id == ShellDestinationId.configuracion,
  );

  List<ShellDestination> _visibleDestinations = const [];
  List<ShellSection> _visibleSections = const [];
  ShellDestination? _visibleConfiguracion;

  List<RolUsuario>? _rolesResueltos;
  List<ShellDestination> _destinosPara(List<RolUsuario> roles) {
    if (_rolesResueltos != null && listEquals(_rolesResueltos, roles)) {
      return _visibleDestinations;
    }
    _rolesResueltos = List<RolUsuario>.unmodifiable(roles);

    final validSections = <ShellSection>[];
    for (final section in _allSections) {
      final validDestinations = section.destinations
          .where((d) => ShellDestinationAccess.allows(d.id, roles))
          .toList();

      if (validDestinations.isNotEmpty) {
        validSections.add(
          ShellSection(title: section.title, destinations: validDestinations),
        );
      }
    }

    _visibleSections = List<ShellSection>.unmodifiable(validSections);

    _visibleConfiguracion =
        ShellDestinationAccess.allows(_configuracion.id, roles)
        ? _configuracion
        : null;

    _visibleDestinations = List<ShellDestination>.unmodifiable([
      for (final section in _visibleSections) ...section.destinations,
      ...[_visibleConfiguracion].whereType<ShellDestination>(),
    ]);

    return _visibleDestinations;
  }

  void _onDestinationSelected(int index) {
    final destinos = _visibleDestinations;
    if (index < 0 || index >= destinos.length) return;

    final id = destinos[index].id;
    if (_selectedId == id) return;

    setState(() => _selectedId = id);

    if (id == ShellDestinationId.consultas) {
      _consultasListCubit.recargar();
    }
  }

  void _navigateTo(ShellDestinationId id) {
    final index = _visibleDestinations.indexWhere((d) => d.id == id);
    if (index != -1) _onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.select((AuthCubit cubit) => cubit.state.roles);
    final destinos = _destinosPara(roles);

    var selectedIndex = destinos.indexWhere((d) => d.id == _selectedId);
    if (selectedIndex == -1) selectedIndex = 0;

    final mediaQuery = MediaQuery.of(context);
    final layout = ShellLayoutResolution.of(mediaQuery);
    final colorScheme = Theme.of(context).colorScheme;

    if (destinos.isEmpty) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final content = LazyDestinationStack(
      destinations: destinos,
      selectedIndex: selectedIndex,
    );

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: ShellAppBar(
        sectionTitle: destinos[selectedIndex].label,
        compact:
            layout.usesBottomNavigation || mediaQuery.viewInsets.bottom > 0,
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: SafeArea(
              top: false,
              child: layout.usesBottomNavigation
                  ? content
                  : Padding(
                      padding: ShellLayoutResolution.contentPadding(
                        mediaQuery,
                        layout,
                      ),
                      child: Row(
                        children: [
                          _SideRail(
                            extended: layout.usesExtendedRail,
                            sections: _visibleSections,
                            configuration: _visibleConfiguracion,
                            selectedIndex: selectedIndex,
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
      bottomNavigationBar: layout.usesBottomNavigation
          ? ShellMobileNavigation(
              destinations: destinos,
              primaryDestinations: _visibleSections.isEmpty
                  ? const []
                  : _visibleSections.first.destinations,
              selectedIndex: selectedIndex,
              onDestinationSelected: _onDestinationSelected,
            )
          : null,
    );
  }
}

class ShellMobileNavigation extends StatelessWidget {
  const ShellMobileNavigation({
    super.key,
    required this.destinations,
    required this.primaryDestinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<ShellDestination> destinations;
  final List<ShellDestination> primaryDestinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final primary = primaryDestinations;
    final secondary = destinations
        .where(
          (destination) =>
              !primary.map((item) => item.id).contains(destination.id),
        )
        .toList();
    final selectedId = destinations[selectedIndex].id;
    final selectedIsSecondary = secondary.any((item) => item.id == selectedId);
    final hasMore = secondary.isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: ac.railBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ac.railDivider.withValues(alpha: 0.6),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              for (var index = 0; index < primary.length; index++)
                Expanded(
                  child: _MobileRailItem(
                    destination: primary[index],
                    label: _shortLabel(primary[index].label),
                    selected: selectedId == primary[index].id,
                    onTap: () => onDestinationSelected(
                      destinations.indexWhere(
                        (item) => item.id == primary[index].id,
                      ),
                    ),
                  ),
                ),
              if (hasMore)
                Expanded(
                  child: _MobileRailItem(
                    destination: const ShellDestination(
                      id: ShellDestinationId.configuracion,
                      icon: Icons.more_horiz_rounded,
                      selectedIcon: Icons.more_horiz_rounded,
                      label: 'Más',
                      builder: _emptyBuilder,
                    ),
                    label: 'Más',
                    selected: selectedIsSecondary,
                    onTap: () => _showMoreDestinations(context, secondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _emptyBuilder(BuildContext context) => const SizedBox.shrink();

  void _showMoreDestinations(
    BuildContext context,
    List<ShellDestination> secondary,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final ac = sheetContext.appColors;
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, controller) => Container(
            decoration: BoxDecoration(
              color: ac.railBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: ac.railDivider.withValues(alpha: 0.6),
                width: 0.5,
              ),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ac.railDivider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Más módulos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: ac.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < secondary.length; index++)
                  _MoreRailItem(
                    destination: secondary[index],
                    selected:
                        destinations[selectedIndex].id == secondary[index].id,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDestinationSelected(
                        destinations.indexWhere(
                          (item) => item.id == secondary[index].id,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _shortLabel(String label) {
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

class _MobileRailItem extends StatelessWidget {
  const _MobileRailItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final foreground = selected ? ac.railTextSelected : ac.railText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('mobile-navigation-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? ac.railSelectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 21,
                color: foreground,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreRailItem extends StatelessWidget {
  const _MoreRailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final foreground = selected ? ac.railTextSelected : ac.railText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? ac.railSelectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 22,
                  color: foreground,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destination.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.extended,
    required this.sections,
    required this.configuration,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final bool extended;
  final List<ShellSection> sections;
  final ShellDestination? configuration;
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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                children: [
                  for (
                    var sectionIndex = 0;
                    sectionIndex < sections.length;
                    sectionIndex++
                  ) ...[
                    if (sectionIndex > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: ac.railDivider,
                        ),
                      ),
                    if (extended)
                      _RailSectionTitle(title: sections[sectionIndex].title),
                    for (final destination
                        in sections[sectionIndex].destinations)
                      _RailItem(
                        destination: destination,
                        selected: _selected(destination),
                        extended: extended,
                        onTap: () =>
                            onDestinationSelected(_indexOf(destination)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (configuration case final destination?) ...[
            Divider(height: 1, thickness: 0.5, color: ac.railDivider),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: _RailItem(
                destination: destination,
                selected: _selected(destination),
                extended: extended,
                onTap: () => onDestinationSelected(_indexOf(destination)),
              ),
            ),
          ],
          Divider(height: 1, thickness: 0.5, color: ac.railDivider),
          const SizedBox(height: 8),
          RailUserCard(extended: extended),
        ],
      ),
    );
  }

  bool _selected(ShellDestination destination) =>
      _indexOf(destination) == selectedIndex;

  int _indexOf(ShellDestination destination) {
    var index = 0;
    for (final section in sections) {
      for (final item in section.destinations) {
        if (item.id == destination.id) return index;
        index++;
      }
    }
    return configuration?.id == destination.id ? index : -1;
  }
}

class _RailSectionTitle extends StatelessWidget {
  const _RailSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ac.railText.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
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
