import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_state.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/pages/crear_editar_equipo_page.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/widgets/equipo_card.dart';

class EquipoListPage extends StatefulWidget {
  const EquipoListPage({super.key});

  @override
  State<EquipoListPage> createState() => _EquipoListPageState();
}

class _EquipoListPageState extends State<EquipoListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<EquipoCubit>().cargarEquipos();
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
      if (mounted) context.read<EquipoCubit>().aplicarFiltros(query: query);
    });
  }

  void _navegarACrear() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EquipoCubit>(),
          child: const CrearEditarEquipoPage(),
        ),
      ),
    );
  }

  void _navegarAEditar(Equipo equipo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<EquipoCubit>(),
          child: CrearEditarEquipoPage(equipo: equipo),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(Equipo equipo) async {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar equipo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Estás segura de que deseas eliminar "${equipo.nombre}"?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ac.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    final ok = await context.read<EquipoCubit>().eliminarEquipo(equipo.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Equipo eliminado correctamente.'
              : 'No se pudo eliminar el equipo.',
        ),
        backgroundColor: ok ? ac.green : ac.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarACrear,
        backgroundColor: ac.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: BlocBuilder<EquipoCubit, EquipoState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, colorScheme, ac),
                Expanded(child: _buildBody(context, state, colorScheme, ac)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
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
                'Equipos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.6,
                ),
              ),
              IconButton(
                onPressed: _navegarACrear,
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: ac.primaryBlue,
                  size: 28,
                ),
                tooltip: 'Registrar nuevo equipo',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Inventario y control de mantenimiento del equipamiento clínico.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o descripción...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
                        context.read<EquipoCubit>().aplicarFiltros(query: '');
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

  Widget _buildBody(
    BuildContext context,
    EquipoState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    if (state is EquipoLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is EquipoError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                onPressed: () => context.read<EquipoCubit>().cargarEquipos(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is EquipoLoaded) {
      if (state.filtrados.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.build_circle_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 12),
              Text(
                state.searchQuery.isNotEmpty
                    ? 'Sin resultados para "${state.searchQuery}"'
                    : 'Aún no hay equipos registrados',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.searchQuery.isEmpty) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _navegarACrear,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar primer equipo'),
                ),
              ],
            ],
          ),
        );
      }

      return Column(
        children: [
          // Indicador sutil de operación en curso (guardando/eliminando)
          if (state is EquipoOperating)
            LinearProgressIndicator(
              backgroundColor: ac.primaryBlue.withValues(alpha: 0.1),
              color: ac.primaryBlue,
              minHeight: 2,
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 100),
              itemCount: state.filtrados.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final equipo = state.filtrados[index];
                return EquipoCard(
                  equipo: equipo,
                  onTap: () => _navegarAEditar(equipo),
                  onEliminar: equipo.id != null
                      ? () => _confirmarEliminacion(equipo)
                      : () {},
                );
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
    EquipoLoaded state,
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
                  ? '$total equipo${total == 1 ? '' : 's'} en total'
                  : '$shown de $total equipo${total == 1 ? '' : 's'}',
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
