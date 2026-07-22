import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── core ──────────────────────────────────────────────────────────────────────
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

// ── features ──────────────────────────────────────────────────────────────────
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_list_page.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/pages/inicio_page.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_detail_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/screens/tratamiento_screen.dart';

// ── shell ─────────────────────────────────────────────────────────────────────
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';
import 'package:salud_dental_clinic_management/shell/widgets/rail_user_card.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_app_bar.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_logo.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  late final DashboardCubit _dashboardCubit;
  late final CitaCubit _citaCubit;
  late final PacienteCubit _pacienteCubit;
  late final ConsultasListCubit _consultaCubit;
  late final List<ShellDestination> _allDestinations;

  List<ShellDestination> _visibleDestinations = [];

  @override
  void initState() {
    super.initState();

    _dashboardCubit = sl<DashboardCubit>();
    _citaCubit = sl<CitaCubit>()..load();
    _pacienteCubit = sl<PacienteCubit>()..load();
    _consultaCubit = sl<ConsultasListCubit>()..cargar();

    _allDestinations = [
      ShellDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard_rounded,
        label: 'Inicio',
        builder: (_) => BlocProvider.value(
          value: _dashboardCubit,
          child: BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) => prev.usuario != curr.usuario,
            listener: (context, authState) {
              final usuario = authState.usuario;
              _dashboardCubit.load(
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
              onNavigateToConfiguracion: () =>
                  _navigateToLabel('Configuración'),
            ),
          ),
        ),
      ),
      ShellDestination(
        icon: Icons.today_outlined,
        selectedIcon: Icons.today_rounded,
        label: 'Mis Citas del Día',
        builder: (_) => BlocProvider.value(
          value: _citaCubit,
          child: const MisCitasDelDiaPage(),
        ),
      ),
      ShellDestination(
        icon: Icons.medical_information_outlined,
        selectedIcon: Icons.medical_information_rounded,
        label: 'Consultas',
        builder: (_) => BlocProvider.value(
          value: _consultaCubit,
          child: const ConsultasListPage(),
        ),
      ),
      ShellDestination(
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt_rounded,
        label: 'Pacientes',
        builder: (_) => BlocProvider.value(
          value: _pacienteCubit,
          child: const PacientesPage(),
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthCubit>().state;
    final usuario = authState.usuario;
    _dashboardCubit.load(
      roles: authState.roles,
      doctorId: usuario is Doctor ? usuario.id : null,
      doctorName: usuario is Doctor
          ? '${usuario.nombre} ${usuario.apellido}'
          : null,
    );
  }

  @override
  void dispose() {
    _dashboardCubit.close();
    _citaCubit.close();
    _pacienteCubit.close();
    _consultaCubit.close();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _navigateToLabel(String label) {
    final index = _visibleDestinations.indexWhere((d) => d.label == label);
    if (index != -1) _onDestinationSelected(index);
  }

  List<ShellDestination> _buildVisibleDestinations(List<RolUsuario> roles) {
    if (roles.isEmpty) return [];
    return _allDestinations.where((d) {
      switch (d.label) {
        case 'Configuración':
          return roles.contains(RolUsuario.admin);
        case 'Consultas':
        case 'Medicinas':
        case 'Tratamientos':
          return roles.contains(RolUsuario.admin) ||
              roles.contains(RolUsuario.doctor);
        case 'Inicio':
        case 'Mis Citas del Día':
        case 'Pacientes':
          return true;
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.select((AuthCubit cubit) => cubit.state.roles);

    _visibleDestinations = _buildVisibleDestinations(roles);

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
      body: SafeArea(
        top: false,
        child: layout == _ShellLayout.mobile
            ? content
            : Row(
                children: [
                  _SideRail(
                    extended: layout == _ShellLayout.desktop,
                    destinations: _visibleDestinations,
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

  String _shortLabel(String label) => switch (label) {
    'Mis Citas del Día' => 'Citas',
    'Configuración' => 'Ajustes',
    'Tratamientos' => 'Servicios',
    _ => label,
  };
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
      width: extended ? 248 : 88,
      decoration: BoxDecoration(
        color: ac.railBg,
        border: Border(right: BorderSide(color: ac.railDivider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShellLogo(extended: extended),
          Divider(height: 1, color: ac.railDivider),
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
          Divider(height: 1, color: ac.railDivider),
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

  String _shortRailLabel(String label) => switch (label) {
    'Mis Citas del Día' => 'Citas',
    'Configuración' => 'Ajustes',
    'Tratamientos' => 'Servicios',
    _ => label,
  };
}

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) context.read<PacienteCubit>().search(_searchController.text);
    });
  }

  Future<void> _openForm({Paciente? paciente}) async {
    final cubit = context.read<PacienteCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PacienteFormPage(paciente: paciente),
        ),
      ),
    );
    if (mounted) cubit.load();
  }

  Future<void> _openDetalle(Paciente paciente) async {
    final cubit = context.read<PacienteCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PacienteDetailPage(pacienteId: paciente.id!),
        ),
      ),
    );
    if (mounted) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: BlocBuilder<PacienteCubit, PacienteState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderAndSearch(context, state),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch(BuildContext context, PacienteState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: context.pageInsets(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A Row would clip the counter badge once the title and the action
          // button no longer fit; wrapping drops the button to its own line.
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Pacientes',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.6,
                    ),
                  ),
                  if (state is PacienteLoaded) ...[
                    const SizedBox(width: 14),
                    Builder(
                      builder: (context) {
                        final ac = context.appColors;
                        return Container(
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
                                '${state.todos.length}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: ac.primaryBlue,
                                    ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.people_alt_rounded,
                                color: ac.primaryBlue,
                                size: 13,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Nuevo Paciente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.appColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Listado completo de pacientes registrados en el sistema.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => _onSearch(),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o cédula...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.45),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color: colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        context.read<PacienteCubit>().search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.appColors.searchFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.appColors.primaryBlue,
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PacienteState state) {
    if (state is PacienteLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is PacienteError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.read<PacienteCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (state is PacienteLoaded) {
      final compact = MediaQuery.sizeOf(context).width < 600;
      return Column(
        children: [
          if (!compact) _buildTableHeader(context),
          if (state.filtrados.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 56,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(100),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No hay pacientes registrados.\nPresiona "Nuevo Paciente" para comenzar.'
                          : 'Sin resultados para "${_searchController.text}".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                padding: context.pageInsets(top: 4, bottom: 24),
                itemCount: state.filtrados.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PacienteRow(
                  paciente: state.filtrados[i],
                  onEdit: () => _openForm(paciente: state.filtrados[i]),
                  onVerDetalle: () => _openDetalle(state.filtrados[i]),
                ),
              ),
            ),
            _buildFooter(context, state),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTableHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(48, 8, 48, 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderLabel(text: 'NOMBRE COMPLETO')),
          Expanded(flex: 2, child: _HeaderLabel(text: 'CÉDULA')),
          Expanded(flex: 2, child: _HeaderLabel(text: 'TELÉFONO')),
          Expanded(flex: 1, child: _HeaderLabel(text: 'EDAD')),
          SizedBox(width: 108),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 10,
      ),
    );
  }
}

Widget _buildFooter(BuildContext context, PacienteLoaded state) {
  final ac = context.appColors;
  final shown = state.filtrados.length;
  final total = state.todos.length;

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: shown == total ? ac.primaryBlue : ac.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            shown == total
                ? '$total paciente${total == 1 ? '' : 's'} en total'
                : '$shown de $total paciente${total == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ac.textSecondary,
            ),
          ),
          if (shown != total) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ac.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'filtrado',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ac.amber,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _PacienteRow extends StatefulWidget {
  final Paciente paciente;
  final VoidCallback onEdit;
  final VoidCallback onVerDetalle;

  const _PacienteRow({
    required this.paciente,
    required this.onEdit,
    required this.onVerDetalle,
  });

  @override
  State<_PacienteRow> createState() => _PacienteRowState();
}

class _PacienteRowState extends State<_PacienteRow> {
  bool _expanded = false;

  dynamic get _contacto => widget.paciente.contactos.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = widget.paciente;
    final ac = context.appColors;

    final fondoTarjeta = _expanded
        ? ac.primaryBlue.withValues(alpha: 0.04)
        : ac.cardBg;
    final colorBorde = _expanded
        ? ac.primaryBlue.withValues(alpha: 0.25)
        : colorScheme.outlineVariant.withOpacity(0.4);

    final compact = MediaQuery.sizeOf(context).width < 600;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(_expanded ? 0.03 : 0.01),
            blurRadius: _expanded ? 10 : 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            hoverColor: ac.primaryBlue.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: compact
                  ? _buildCompactRow(context, p, ac)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurface.withOpacity(
                                    0.04,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  p.fullName,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                        fontSize: 15,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            p.govID,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _contacto?.numeroTelefono.isNotEmpty == true
                                ? _contacto!.numeroTelefono
                                : '—',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.8),
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${p.age} años',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        SizedBox(
                          width: 108,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ActionIcon(
                                icon: Icons.visibility_outlined,
                                tooltip: 'Ver expediente',
                                color: ac.primaryBlue,
                                onTap: widget.onVerDetalle,
                              ),
                              const SizedBox(width: 6),
                              _ActionIcon(
                                icon: Icons.edit_outlined,
                                tooltip: 'Editar',
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                                onTap: widget.onEdit,
                              ),
                              const SizedBox(width: 6),
                              _ActionIcon(
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'Eliminar',
                                color: colorScheme.error.withOpacity(0.7),
                                onTap: () => _showDeleteConfirmation(
                                  context,
                                  widget.paciente,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_expanded) _buildDetail(context, p),
        ],
      ),
    );
  }

  Widget _buildCompactRow(BuildContext context, Paciente p, AppColors ac) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                p.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            _ActionIcon(
              icon: Icons.visibility_outlined,
              tooltip: 'Ver expediente',
              color: ac.primaryBlue,
              onTap: widget.onVerDetalle,
            ),
            _ActionIcon(
              icon: Icons.edit_outlined,
              tooltip: 'Editar',
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              onTap: widget.onEdit,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _compactField('Cédula', p.govID),
            _compactField(
              'Teléfono',
              _contacto?.numeroTelefono.isNotEmpty == true
                  ? _contacto!.numeroTelefono
                  : '—',
            ),
            _compactField('Edad', '${p.age} años'),
          ],
        ),
      ],
    );
  }

  Widget _compactField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        ),
      ),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _buildDetail(BuildContext context, Paciente p) {
    final colorScheme = Theme.of(context).colorScheme;
    final telefono = _contacto?.numeroTelefono ?? '';
    final email = _contacto?.email ?? '';
    final direccion = _contacto?.direccion ?? '';

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBg.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: colorScheme.outlineVariant.withOpacity(0.25),
            height: 1,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 40,
            runSpacing: 16,
            children: [
              _DetailItem(label: 'Género', value: _generoLabel(p.genero.name)),
              _DetailItem(
                label: 'Tipo de Paciente',
                value: _capitalize(p.tipoPaciente.name),
              ),
              _DetailItem(
                label: 'Ocupación',
                value: p.trabajo.isEmpty ? '—' : p.trabajo,
              ),
              _DetailItem(
                label: 'Referencia',
                value: p.referencia.isEmpty ? '—' : p.referencia,
              ),
              _DetailItem(
                label: 'Teléfono',
                value: telefono.isEmpty ? '—' : telefono,
              ),
              _DetailItem(label: 'Email', value: email.isEmpty ? '—' : email),
              _DetailItem(
                label: 'Dirección Residencia',
                value: direccion.isEmpty ? '—' : direccion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _generoLabel(String name) => switch (name) {
    'masculino' => 'Masculino',
    'femenino' => 'Femenino',
    'otro' => 'Otro',
    'noPrefiereDecir' => 'No prefiere decir',
    _ => name,
  };

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showDeleteConfirmation(BuildContext context, Paciente paciente) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de que desea eliminar a ${paciente.fullName}?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción eliminará el registro del paciente de forma lógica.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PacienteCubit>().deletePaciente(paciente.id!);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
