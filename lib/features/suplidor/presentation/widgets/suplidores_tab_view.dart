import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/enums/tipo_suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_cubit.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_state.dart';

class SuplidoresTabView extends StatefulWidget {
  const SuplidoresTabView({super.key});

  @override
  State<SuplidoresTabView> createState() => _SuplidoresTabViewState();
}

class _SuplidoresTabViewState extends State<SuplidoresTabView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<SuplidorCubit>().cargar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<SuplidorCubit>().filtrarPorBusqueda(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return BlocBuilder<SuplidorCubit, SuplidorState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state, colorScheme, ac),
            Expanded(child: _buildBody(context, state, colorScheme, ac)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SuplidorState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    return Padding(
      padding: context.pageInsets(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Directorio de Suplidores',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _mostrarDialogoFormulario(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo suplidor'),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar suplidor por nombre o reseña...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
              filled: true,
              fillColor: context.appColors.searchFill,
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
    SuplidorState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    if (state is SuplidorLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is SuplidorError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: ac.red),
            const SizedBox(height: 12),
            Text(state.mensaje),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.read<SuplidorCubit>().cargar(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is SuplidorLoaded) {
      final items = state.suplidoresFiltrados;

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 48,
                color: ac.textMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'No hay suplidores registrados',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: context.pageInsets(top: 8, bottom: 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ac.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ac.divider.withValues(alpha: 0.5),
                width: 0.6,
              ),
              boxShadow: [ac.cardShadow],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: ac.primaryGreen.withValues(alpha: 0.1),
                  child: Icon(Icons.store_rounded, color: ac.primaryGreen),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _TipoSuplidorBadge(tipo: item.tipoSuplidor, ac: ac),
                        ],
                      ),
                      if (item.summary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.summary,
                          style: TextStyle(
                            color: ac.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Editar datos',
                  onPressed: () =>
                      _mostrarDialogoFormulario(context, suplidor: item),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: ac.red,
                    size: 18,
                  ),
                  tooltip: 'Eliminar',
                  onPressed: () => _confirmarEliminacion(context, item),
                ),
              ],
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _TipoSuplidorBadge extends StatelessWidget {
  const _TipoSuplidorBadge({required this.tipo, required this.ac});
  final TipoSuplidor tipo;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tipo) {
      TipoSuplidor.consumible => ('Consumibles', ac.primaryGreen),
      TipoSuplidor.servicio => ('Servicios', ac.teal),
      TipoSuplidor.mixto => ('Mixto', ac.purple),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

Future<void> _mostrarDialogoFormulario(
  BuildContext context, {
  Suplidor? suplidor,
}) async {
  final nombreController = TextEditingController(text: suplidor?.nombre);
  final summaryController = TextEditingController(text: suplidor?.summary);
  TipoSuplidor tipo = suplidor?.tipoSuplidor ?? TipoSuplidor.consumible;
  final formKey = GlobalKey<FormState>();

  final ac = context.appColors;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: ac.cardBg,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Modal ─────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ac.primaryGreen.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.store_rounded,
                            color: ac.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suplidor == null
                                    ? 'Nuevo Suplidor'
                                    : 'Editar Suplidor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ac.textPrimary,
                                ),
                              ),
                              Text(
                                'Registra los datos de contacto y servicios',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ac.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: ac.divider),
                    const SizedBox(height: 20),

                    // ── Campos Formulario ────────────────────────────────────
                    TextFormField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre / Empresa *',
                        prefixIcon: const Icon(
                          Icons.business_rounded,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<TipoSuplidor>(
                      value: tipo,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Servicio',
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TipoSuplidor.consumible,
                          child: Text('Consumibles / Materiales'),
                        ),
                        DropdownMenuItem(
                          value: TipoSuplidor.servicio,
                          child: Text('Servicios / Mantenimiento'),
                        ),
                        DropdownMenuItem(
                          value: TipoSuplidor.mixto,
                          child: Text('Mixto (Ambos)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => tipo = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: summaryController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Reseña / Notas de contacto',
                        prefixIcon: const Icon(
                          Icons.description_outlined,
                          size: 20,
                        ),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Acciones Modal ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Guardar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: ac.primaryGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(dialogCtx, true);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  if (ok != true || !context.mounted) return;

  final nuevo = Suplidor(
    id: suplidor?.id,
    nombre: nombreController.text.trim(),
    tipoSuplidor: tipo,
    contactos: const [],
    summary: summaryController.text.trim(),
  );

  final error = await context.read<SuplidorCubit>().guardar(nuevo);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: ac.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

Future<void> _confirmarEliminacion(BuildContext context, Suplidor item) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Eliminar suplidor'),
      content: Text('¿Deseas eliminar a "${item.nombre}" de la lista?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: context.appColors.red),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );

  if (res == true && context.mounted) {
    await context.read<SuplidorCubit>().eliminar(item.id!);
  }
}
