import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/motivo_ajuste_stock.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_cubit.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_state.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/entities/suplidor.dart';

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<InventarioCubit>().cargar();
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
        context.read<InventarioCubit>().filtrarPorBusqueda(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: BlocBuilder<InventarioCubit, InventarioState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state, colorScheme, ac),
                if (state is InventarioLoaded)
                  _buildFilterChips(context, state, colorScheme),
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
    InventarioState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    return Padding(
      padding: context.pageInsets(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventario',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestión de materiales y suministros de la clínica.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _mostrarDialogoFormulario(
                  context,
                  consumibles: state is InventarioLoaded
                      ? state.consumibles
                      : const [],
                  suplidores: state is InventarioLoaded
                      ? state.suplidores
                      : const [],
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nuevo'),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),

          if (state is InventarioLoaded) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Total artículos',
                    value: '${state.totalArticulos}',
                    color: ac.primaryBlue,
                    icon: Icons.inventory_2_outlined,
                    ac: ac,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Stock bajo / crítico',
                    value: '${state.totalCriticos}',
                    color: state.totalCriticos > 0 ? ac.red : ac.green,
                    icon: Icons.warning_amber_rounded,
                    ac: ac,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar consumible por nombre o descripción...',
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
                        context.read<InventarioCubit>().filtrarPorBusqueda('');
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
    InventarioLoaded state,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: context.pageInsets(top: 4, bottom: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todos'),
              selected: !state.soloCriticos,
              onSelected: (_) {
                context.read<InventarioCubit>().toggleFiltroCriticos(false);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              selectedColor: colorScheme.secondaryContainer,
              showCheckmark: false,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('Sólo críticos (${state.totalCriticos})'),
              selected: state.soloCriticos,
              onSelected: (_) {
                context.read<InventarioCubit>().toggleFiltroCriticos(true);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              selectedColor: context.appColors.red.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: state.soloCriticos
                    ? context.appColors.red
                    : colorScheme.onSurfaceVariant,
                fontWeight: state.soloCriticos
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              showCheckmark: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    InventarioState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    if (state is InventarioLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is InventarioError) {
      return Center(
        child: Padding(
          padding: context.pageInsets(),
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
                state.mensaje,
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.read<InventarioCubit>().cargar(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is InventarioLoaded) {
      final items = state.consumiblesFiltrados;

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 12),
              Text(
                state.busqueda.isNotEmpty || state.soloCriticos
                    ? 'Sin resultados para el filtro aplicado'
                    : 'No hay artículos en el inventario',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<InventarioCubit>().cargar(),
              child: ListView.separated(
                padding: context.pageInsets(top: 8, bottom: 24),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ConsumibleCard(
                    consumible: item,
                    ac: ac,
                    onAjustarStock: () =>
                        _mostrarDialogoAjustarStock(context, item),
                    onEditar: () => _mostrarDialogoFormulario(
                      context,
                      consumible: item,
                      consumibles: state.consumibles,
                      suplidores: state.suplidores,
                    ),
                    onEliminar: () => _confirmarEliminacion(context, item),
                  );
                },
              ),
            ),
          ),
          _buildFooter(state, items.length, ac),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFooter(InventarioLoaded state, int shown, AppColors ac) {
    final total = state.totalArticulos;

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
            Flexible(
              child: Text(
                shown == total
                    ? '$total artículo${total == 1 ? '' : 's'} en total'
                    : '$shown de $total artículo${total == 1 ? '' : 's'}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ac.textSecondary,
                ),
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final AppColors ac;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.ac,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: ac.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumibleCard extends StatelessWidget {
  const _ConsumibleCard({
    required this.consumible,
    required this.ac,
    required this.onAjustarStock,
    required this.onEditar,
    required this.onEliminar,
  });

  final Consumible consumible;
  final AppColors ac;
  final VoidCallback onAjustarStock;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final esCritico = consumible.estaBajoStock;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esCritico
              ? ac.red.withValues(alpha: 0.4)
              : ac.divider.withValues(alpha: 0.5),
          width: esCritico ? 1 : 0.6,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consumible.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (consumible.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        consumible.descripcion,
                        style: TextStyle(color: ac.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'RD\$ ${consumible.precio.toStringAsFixed(2)}'
                      '${consumible.suplidorNombre == null ? '' : ' · ${consumible.suplidorNombre}'}',
                      style: TextStyle(color: ac.textMuted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _EstadoBadge(estado: consumible.estadoCalculado, ac: ac),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: esCritico
                          ? ac.red.withValues(alpha: 0.10)
                          : ac.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Stock: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: ac.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${consumible.stockActual}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: esCritico ? ac.red : ac.primaryBlue,
                          ),
                        ),
                        Text(
                          ' / Mín: ${consumible.stockMinimo}',
                          style: TextStyle(fontSize: 12, color: ac.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (esCritico) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ac.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        consumible.estaAgotado ? 'AGOTADO' : 'BAJO MÍNIMO',
                        style: TextStyle(
                          color: ac.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    tooltip: 'Ajustar stock',
                    visualDensity: VisualDensity.compact,
                    onPressed: onAjustarStock,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Editar datos',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEditar,
                  ),
                  IconButton(
                    icon: Icon(Icons.archive_outlined, color: ac.red, size: 18),
                    tooltip: 'Dar de baja',
                    visualDensity: VisualDensity.compact,
                    onPressed: onEliminar,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado, required this.ac});
  final EstadoConsumible estado;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      EstadoConsumible.disponible => ('Disponible', ac.green),
      EstadoConsumible.bajoStock => ('Bajo Stock', ac.orange),
      EstadoConsumible.agotado => ('Agotado', ac.red),
      EstadoConsumible.descontinuado => ('Descontinuado', ac.textMuted),
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

// -----------------------------------------------------------------------------
// DIÁLOGOS ESTILIZADOS
// -----------------------------------------------------------------------------

Future<void> _mostrarDialogoFormulario(
  BuildContext context, {
  Consumible? consumible,
  required List<Consumible> consumibles,
  required List<Suplidor> suplidores,
}) async {
  final nombreController = TextEditingController(
    text: consumible?.nombre ?? '',
  );
  final descController = TextEditingController(
    text: consumible?.descripcion ?? '',
  );
  final precioController = TextEditingController(
    text: consumible?.precio.toStringAsFixed(2) ?? '',
  );
  final stockInicialController = TextEditingController(
    text: consumible?.stockActual.toString() ?? '0',
  );
  final stockMinimoController = TextEditingController(
    text: consumible?.stockMinimo.toString() ?? '5',
  );
  String? suplidorId = consumible?.suplidorId;
  final formKey = GlobalKey<FormState>();

  final nuevoItem = await showDialog<Consumible>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          consumible == null ? 'Nuevo consumible' : 'Editar consumible',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final nombre = v?.trim() ?? '';
                    if (nombre.isEmpty) return 'El nombre es obligatorio';
                    final duplicado = consumibles.any(
                      (item) =>
                          item.id != consumible?.id &&
                          item.nombre.trim().toLowerCase() ==
                              nombre.toLowerCase(),
                    );
                    return duplicado
                        ? 'Ya existe un consumible con este nombre'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: precioController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio (RD\$) *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final precio = double.tryParse(
                      (v ?? '').replaceAll(',', '.'),
                    );
                    if (precio == null) return 'Ingresa un precio válido';
                    return precio < 0
                        ? 'El precio no puede ser negativo'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: stockInicialController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: consumible == null
                              ? 'Stock inicial *'
                              : 'Stock actual',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: consumible != null,
                        validator: (v) {
                          final stock = int.tryParse(v ?? '');
                          if (stock == null) return 'Inválido';
                          return stock < 0 ? 'No puede ser negativo' : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: stockMinimoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock mínimo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final stock = int.tryParse(v ?? '');
                          if (stock == null) return 'Inválido';
                          return stock < 0 ? 'No puede ser negativo' : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (consumible != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Para cambiar el stock actual usa la acción “Ajustar stock”.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: suplidorId,
                  decoration: const InputDecoration(
                    labelText: 'Suplidor (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Sin suplidor'),
                    ),
                    ...suplidores.map(
                      (suplidor) => DropdownMenuItem<String?>(
                        value: suplidor.id,
                        child: Text(suplidor.nombre),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() => suplidorId = val);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogCtx,
                  Consumible(
                    id: consumible?.id,
                    nombre: nombreController.text.trim(),
                    descripcion: descController.text.trim(),
                    precio: double.parse(
                      precioController.text.replaceAll(',', '.'),
                    ),
                    stockActual: int.parse(stockInicialController.text),
                    stockMinimo: int.parse(stockMinimoController.text),
                    estado: consumible?.estado ?? EstadoConsumible.disponible,
                    suplidorId: suplidorId,
                    suplidorNombre: suplidores
                        .where((suplidor) => suplidor.id == suplidorId)
                        .map((suplidor) => suplidor.nombre)
                        .firstOrNull,
                    activo: consumible?.activo ?? true,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );

  nombreController.dispose();
  descController.dispose();
  precioController.dispose();
  stockInicialController.dispose();
  stockMinimoController.dispose();
  if (nuevoItem == null || !context.mounted) return;

  final error = await context.read<InventarioCubit>().guardar(nuevoItem);
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: context.appColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consumible guardado correctamente.')),
    );
  }
}

Future<void> _mostrarDialogoAjustarStock(
  BuildContext context,
  Consumible item,
) async {
  final stockController = TextEditingController(text: '${item.stockActual}');
  final formKey = GlobalKey<FormState>();
  MotivoAjusteStock? motivo;

  final ajuste = await showDialog<(int, MotivoAjusteStock)>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ajustar stock: ${item.nombre}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nuevo stock actual',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final stock = int.tryParse(v ?? '');
                  if (stock == null) return 'Ingresa un número válido';
                  return stock < 0 ? 'El stock no puede ser negativo' : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MotivoAjusteStock>(
                initialValue: motivo,
                decoration: const InputDecoration(
                  labelText: 'Motivo *',
                  border: OutlineInputBorder(),
                ),
                items: MotivoAjusteStock.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item.etiqueta),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => motivo = value),
                validator: (value) =>
                    value == null ? 'Selecciona un motivo' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogCtx, (
                  int.parse(stockController.text),
                  motivo!,
                ));
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    ),
  );

  stockController.dispose();
  if (ajuste == null || !context.mounted) return;

  final error = await context.read<InventarioCubit>().ajustarStock(
    item.id!,
    ajuste.$1,
    ajuste.$2,
  );

  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: context.appColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

Future<void> _confirmarEliminacion(
  BuildContext context,
  Consumible item,
) async {
  final ac = context.appColors;

  final res = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Dar de baja el consumible',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Text(
        '¿Deseas dar de baja "${item.nombre}"?\n\nDejará de aparecer en el inventario, pero se conservará su historial.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ac.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(dialogCtx, true),
          child: const Text('Dar de baja'),
        ),
      ],
    ),
  );

  if (res == true && context.mounted) {
    final error = await context.read<InventarioCubit>().eliminar(item.id!);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Artículo dado de baja correctamente.'
              : 'No se pudo dar de baja el artículo.',
        ),
        backgroundColor: error == null ? ac.green : ac.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
