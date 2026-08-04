import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/pages/caja_diaria_page.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/pages/mis_citas_del_dia_page.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/pages/configuracion_page.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_cubit.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/pages/inventario_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consultas_list_page.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/cuentas_por_cobrar_page.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/presentation/pages/diagnosos_list_page.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/pages/inicio_page.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_list_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/pacientes_page.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/asistente.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/pages/usuarios_list_page.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/presentarion/pages/procedimiento_list_page.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/screens/tratamiento_screen.dart';
import 'package:salud_dental_clinic_management/shell/lazy_destination_stack.dart';
import 'package:salud_dental_clinic_management/shell/responsive_shell_layout.dart';
import 'package:salud_dental_clinic_management/shell/shell_destination.dart';
import 'package:salud_dental_clinic_management/shell/widgets/connectivity_banner.dart';
import 'package:salud_dental_clinic_management/shell/widgets/rail_user_card.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_app_bar.dart';
import 'package:salud_dental_clinic_management/shell/widgets/shell_logo.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    // El `AuthCubit` es el de `main.dart` y no uno propio: `sl<AuthCubit>()`
    // está registrado como *factory*, así que crear otro aquí devolvía un cubit
    // recién nacido —sin usuario— mientras la sesión real vivía en el de
    // arriba. Todo lo que se decidiera en el `initState` de la shell miraba ese
    // estado vacío: por eso el listado de consultas se cargaba sin recortar por
    // doctor y ofrecía el filtro de doctores a quien sólo ejerce. La pantalla
    // parecía correcta un instante después, cuando el cubit duplicado
    // restauraba la sesión por su cuenta y repintaba lo que sí depende del
    // estado; lo decidido en el arranque, no.
    return BlocProvider<PacienteCubit>(
      create: (_) => sl<PacienteCubit>()..load(),
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
    // Quien gestiona la agenda completa ve todas las consultas; quien sólo
    // ejerce ve las suyas. El administrador entra por la primera vía sin dejar
    // de ser clínico.
    final restringidoA = context
        .read<AuthCubit>()
        .state
        .doctorIdParaFiltrarAgenda;
    _consultasListCubit.cargar(restringidoADoctorId: restringidoA);
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
      builder: (_) => const _CitasDelDiaDestination(),
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
    // Equipos NO es un destino de primer nivel: vive como pestaña dentro de
    // Inventario, que es donde se gestiona todo lo material de la clínica.
    // Tenerlo en los dos sitios duplicaba la entrada en el menú (defecto D19
    // de la jornada de QA del 1 ago 2026) y dejaba dos caminos con
    // dependencias distintas hacia la misma pantalla.
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
      id: ShellDestinationId.procedimientos,
      icon: Icons.healing_outlined,
      selectedIcon: Icons.healing_rounded,
      label: 'Procedimientos',
      builder: (_) =>
          ProcedimientoListPage(repository: sl<ProcedimientoRepository>()),
    ),
    ShellDestination(
      id: ShellDestinationId.diagnosticos,
      icon: Icons.assignment_late_outlined,
      selectedIcon: Icons.assignment_late_rounded,
      label: 'Diagnósticos',
      builder: (_) => DiagnosisListPage(repository: sl<DiagnosisRepository>()),
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
        ShellDestinationId.procedimientos,
        ShellDestinationId.diagnosticos,
        ShellDestinationId.medicinas,
        ShellDestinationId.inventario,
      ]),
    ),
    ShellSection(
      title: 'Administración',
      destinations: _destinationsFor(const [ShellDestinationId.perfiles]),
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
      body: Stack(
        children: [
          Column(
            children: [
              const ConnectivityBanner(),
              Expanded(
                child: SafeArea(
                  top: false,
                  bottom: !layout.usesBottomNavigation,
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

          if (layout.usesBottomNavigation)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShellMobileNavigation(
                destinations: destinos,
                primaryDestinations: _visibleSections.isEmpty
                    ? const []
                    : _visibleSections.first.destinations,
                selectedIndex: selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                onNavigateTo: _navigateTo,
              ),
            ),
        ],
      ),
    );
  }
}

class _CitasDelDiaDestination extends StatefulWidget {
  const _CitasDelDiaDestination();

  @override
  State<_CitasDelDiaDestination> createState() =>
      _CitasDelDiaDestinationState();
}

class _CitasDelDiaDestinationState extends State<_CitasDelDiaDestination> {
  late final CitaCubit _citaCubit = sl<CitaCubit>();

  @override
  void initState() {
    super.initState();
    _cargarSegunRol();
  }

  Future<void> _cargarSegunRol() async {
    final authState = context.read<AuthCubit>().state;
    final usuario = authState.usuario;

    final restringidoA = authState.doctorIdParaFiltrarAgenda;
    if (restringidoA != null) {
      _citaCubit.load(restringidoADoctorId: restringidoA);
      return;
    }

    if (authState.rol == RolUsuario.asistente &&
        usuario is Asistente &&
        usuario.id != null) {
      final doctorIds = await sl<DoctorRepository>().getDoctorIdsAsignados(
        usuario.id!,
      );
      if (!mounted) return;
      _citaCubit.load(doctorIdsPermitidos: doctorIds);
      return;
    }

    _citaCubit.load();
  }

  @override
  void dispose() {
    _citaCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _citaCubit,
      child: const MisCitasDelDiaPage(),
    );
  }
}

class ShellMobileNavigation extends StatefulWidget {
  const ShellMobileNavigation({
    super.key,
    required this.destinations,
    required this.primaryDestinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onNavigateTo,
  });

  final List<ShellDestination> destinations;
  final List<ShellDestination> primaryDestinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ValueChanged<ShellDestinationId> onNavigateTo;

  @override
  State<ShellMobileNavigation> createState() => _ShellMobileNavigationState();
}

class _ShellMobileNavigationState extends State<ShellMobileNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _menuAbierto = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.375).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _menuAbierto = !_menuAbierto;
      if (_menuAbierto) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _cerrarMenu() {
    if (_menuAbierto) {
      setState(() {
        _menuAbierto = false;
        _animController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final primary = widget.primaryDestinations;
    final leftDestinations = primary.take(2).toList();
    final rightDestinations = primary.skip(2).take(2).toList();

    final secondary = widget.destinations
        .where((d) => !primary.map((p) => p.id).contains(d.id))
        .toList();

    return PopScope(
      canPop: !_menuAbierto,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _menuAbierto) {
          _cerrarMenu();
        }
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          if (_menuAbierto)
            GestureDetector(
              onTap: _cerrarMenu,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Container(
                    color: Colors.black.withValues(
                      alpha: disableAnimations
                          ? 0.35
                          : 0.35 * _animController.value,
                    ),
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height,
                  );
                },
              ),
            ),

          Positioned(
            bottom: 86,
            child: ScaleTransition(
              scale: disableAnimations
                  ? const AlwaysStoppedAnimation(1.0)
                  : _expandAnimation,
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: disableAnimations
                    ? const AlwaysStoppedAnimation(1.0)
                    : _animController,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 230,
                    maxHeight: 280,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ac.primaryGreen,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: ac.primaryGreen.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < secondary.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 0.5,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          _QuickVerticalActionButton(
                            icon: secondary[i].selectedIcon,
                            label: secondary[i].label,
                            onTap: () {
                              _cerrarMenu();
                              widget.onNavigateTo(secondary[i].id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: ac.primaryGreen,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: ac.primaryGreen.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        for (final dest in leftDestinations)
                          Expanded(
                            child: _NavItem(
                              destination: dest,
                              selected:
                                  widget
                                      .destinations[widget.selectedIndex]
                                      .id ==
                                  dest.id,
                              onTap: () {
                                _cerrarMenu();
                                widget.onDestinationSelected(
                                  widget.destinations.indexOf(dest),
                                );
                              },
                            ),
                          ),

                        const SizedBox(width: 56),

                        for (final dest in rightDestinations)
                          Expanded(
                            child: _NavItem(
                              destination: dest,
                              selected:
                                  widget
                                      .destinations[widget.selectedIndex]
                                      .id ==
                                  dest.id,
                              onTap: () {
                                _cerrarMenu();
                                widget.onDestinationSelected(
                                  widget.destinations.indexOf(dest),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: -14,
                    child: Semantics(
                      button: true,
                      label: _menuAbierto ? 'Cerrar opciones' : 'Más módulos',
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _toggleMenu,
                            customBorder: const CircleBorder(),
                            child: Center(
                              child: RotationTransition(
                                turns: disableAnimations
                                    ? const AlwaysStoppedAnimation(0)
                                    : _rotationAnimation,
                                child: Icon(
                                  Icons.add_rounded,
                                  color: ac.primaryGreen,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickVerticalActionButton extends StatelessWidget {
  const _QuickVerticalActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final ocultarTexto = width < 360;

    final foreground = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              size: 22,
              color: foreground,
            ),
            if (!ocultarTexto) ...[
              const SizedBox(height: 3),
              Text(
                _shortLabel(destination.label),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
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
      case 'Procedimientos':
        return 'Procedimientos';
      case 'Diagnósticos':
        return 'Diagnósticos';
      default:
        return label;
    }
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
      case 'Procedimientos':
        return 'Procedimientos';
      case 'Diagnósticos':
        return 'Diagnósticos';
      default:
        return label;
    }
  }
}
