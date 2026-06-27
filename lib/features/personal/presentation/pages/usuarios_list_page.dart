import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_state.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/widgets/perfil_card.dart';
// Importación de la página de creación
import 'package:salud_dental_clinic_management/features/personal/presentation/pages/crear_usuario_page.dart';

class UsuariosListPage extends StatefulWidget {
  const UsuariosListPage({super.key});

  @override
  State<UsuariosListPage> createState() => _UsuariosListPageState();
}

class _UsuariosListPageState extends State<UsuariosListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<PersonalPerfilesCubit>().cargarUsuarios();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<PersonalPerfilesCubit>().aplicarFiltros(query: query);
      }
    });
  }

  // Método auxiliar para navegar limpiamente a la página de creación
  void _navegarACrearUsuario() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PersonalPerfilesCubit>(),
          child: const CrearUsuarioPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      // Botón flotante para acceder rápidamente a la creación
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarACrearUsuario,
        backgroundColor: ac.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: SafeArea(
        child: BlocBuilder<PersonalPerfilesCubit, PersonalPerfilesState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderAndSearch(context, state, colorScheme, ac),
                _buildFilterChips(context, state, colorScheme),
                Expanded(child: _buildBody(context, state, colorScheme, ac)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch(
    BuildContext context,
    PersonalPerfilesState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Control de Usuarios',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.6,
                ),
              ),
              // Botón alternativo directo en la cabecera
              IconButton(
                onPressed: _navegarACrearUsuario,
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: ac.primaryBlue,
                  size: 28,
                ),
                tooltip: 'Crear nuevo usuario',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Administración de credenciales, roles y accesos del personal de la clínica.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, cédula o usuario...',
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
                        context.read<PersonalPerfilesCubit>().aplicarFiltros(
                          query: '',
                        );
                      },
                    )
                  : null,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
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

  Widget _buildFilterChips(
    BuildContext context,
    PersonalPerfilesState state,
    ColorScheme colorScheme,
  ) {
    if (state is! PerfilLoaded) return const SizedBox.shrink();

    final rolesAMostrar = [
      (label: 'Todos', rol: null),
      (label: 'Admin', rol: RolUsuario.admin),
      (label: 'Doctor', rol: RolUsuario.doctor),
      (label: 'Asistente', rol: RolUsuario.asistente),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        children: rolesAMostrar.map((item) {
          final isSelected = state.rolFiltro == item.rol;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(item.label),
              selected: isSelected,
              onSelected: (_) {
                context.read<PersonalPerfilesCubit>().aplicarFiltros(
                  rolFiltro: () => item.rol,
                );
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              selectedColor: colorScheme.secondaryContainer,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PersonalPerfilesState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    if (state is PerfilLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PerfilError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  context.read<PersonalPerfilesCubit>().cargarUsuarios(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is PerfilLoaded) {
      if (state.filtrados.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: colorScheme.onSurfaceVariant.withAlpha(100),
              ),
              const SizedBox(height: 12),
              Text(
                'No hay usuarios que coincidan',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              itemCount: state.filtrados.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return PerfilCard(usuario: state.filtrados[index]);
              },
            ),
          ),
          _buildFooter(state, ac, colorScheme),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFooter(
    PerfilLoaded state,
    AppColors ac,
    ColorScheme colorScheme,
  ) {
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
                  ? '$total usuario${total == 1 ? '' : 's'} en total'
                  : '$shown de $total usuario${total == 1 ? '' : 's'}',
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
}
