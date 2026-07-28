import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/enums/estado_cuenta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_state.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/widgets/cuenta_card.dart';

class CuentasPorCobrarPage extends StatefulWidget {
  const CuentasPorCobrarPage({super.key});

  @override
  State<CuentasPorCobrarPage> createState() => _CuentasPorCobrarPageState();
}

class _CuentasPorCobrarPageState extends State<CuentasPorCobrarPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<CuentasPorCobrarCubit>().cargarCuentas();
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
        context.read<CuentasPorCobrarCubit>().aplicarFiltros(query: query);
      }
    });
  }

  void _abrirModalFiltrosAvanzados(
    BuildContext context,
    CuentasPorCobrarLoaded state,
  ) {
    final cubit = context.read<CuentasPorCobrarCubit>();
    final ac = context.appColors;
    OrdenCuenta orden = state.orden;
    DateTimeRange? rangoCreacion = state.rangoCreacion;

    showModalBottomSheet(
      context: context,
      backgroundColor: ac.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, color: ac.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros y Ordenamiento de Cuentas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ac.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: ac.divider),

              Text(
                'ORDENAR POR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: ac.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<OrdenCuenta>(
                value: orden,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: OrdenCuenta.mayorBalance,
                    child: Text('Mayor Balance Pendiente'),
                  ),
                  DropdownMenuItem(
                    value: OrdenCuenta.deudaMasAntigua,
                    child: Text('Deuda más Antigua'),
                  ),
                  DropdownMenuItem(
                    value: OrdenCuenta.actualizacionReciente,
                    child: Text('Actualización Reciente'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => orden = val);
                },
              ),

              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: rangoCreacion,
                  );
                  if (picked != null) {
                    setModalState(() => rangoCreacion = picked);
                  }
                },
                icon: const Icon(Icons.date_range_rounded, size: 16),
                label: Text(
                  rangoCreacion == null
                      ? 'Filtrar por Rango de Fechas'
                      : 'Rango: ${rangoCreacion!.start.day}/${rangoCreacion!.start.month} - ${rangoCreacion!.end.day}/${rangoCreacion!.end.month}',
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      cubit.aplicarFiltros(
                        orden: orden,
                        rangoCreacion: () => rangoCreacion,
                      );
                      Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryGreen,
                    ),
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(String id, String etiqueta) async {
    final ac = context.appColors;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar cuenta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '¿Eliminar la cuenta de "$etiqueta"?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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

    final ok = await context.read<CuentasPorCobrarCubit>().eliminarCuenta(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Cuenta eliminada correctamente.'
              : 'No se pudo eliminar la cuenta.',
        ),
        backgroundColor: ok ? context.appColors.green : context.appColors.red,
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
      body: SafeArea(
        child: BlocBuilder<CuentasPorCobrarCubit, CuentasPorCobrarState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state, colorScheme, ac),
                if (state is CuentasPorCobrarLoaded)
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
    CuentasPorCobrarState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    final currFmt = NumberFormat.currency(symbol: 'RD\$', decimalDigits: 2);

    return Padding(
      padding: context.pageInsets(top: 24, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuentas por Cobrar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Resumen financiero dinámico del catálogo de consultas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          if (state is CuentasPorCobrarLoaded) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Por cobrar (filtrado)',
                    value: currFmt.format(state.totalPorCobrar),
                    color: ac.red,
                    icon: Icons.pending_actions_rounded,
                    ac: ac,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    label: 'Cobrado (filtrado)',
                    value: currFmt.format(state.totalCobrado),
                    color: ac.green,
                    icon: Icons.check_circle_outline_rounded,
                    ac: ac,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar por paciente, teléfono, cuenta o notas...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.45,
                      ),
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
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
                              context
                                  .read<CuentasPorCobrarCubit>()
                                  .aplicarFiltros(query: '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              if (state is CuentasPorCobrarLoaded) ...[
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _abrirModalFiltrosAvanzados(context, state),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Filtros'),
                  style: FilledButton.styleFrom(
                    backgroundColor: state.hayFiltrosActivos
                        ? ac.primaryGreen
                        : ac.searchFill,
                    foregroundColor: state.hayFiltrosActivos
                        ? Colors.white
                        : ac.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    CuentasPorCobrarLoaded state,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<CuentasPorCobrarCubit>();
    final filtros = [
      (label: 'Todas', valor: null),
      (label: 'Sin pago', valor: EstadoCuenta.abierta),
      (label: 'Pendientes', valor: EstadoCuenta.pendiente),
      (label: 'Saldadas', valor: EstadoCuenta.saldada),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: context.pageInsets(top: 4, bottom: 8),
      child: Row(
        children: [
          for (final f in filtros)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f.label),
                selected: state.filtroEstado == f.valor,
                onSelected: (_) {
                  cubit.aplicarFiltros(estado: () => f.valor);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                selectedColor: colorScheme.secondaryContainer,
                showCheckmark: false,
              ),
            ),
          if (state.hayFiltrosActivos)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                cubit.limpiarFiltros();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
              label: const Text('Limpiar todos'),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CuentasPorCobrarState state,
    ColorScheme colorScheme,
    AppColors ac,
  ) {
    if (state is CuentasPorCobrarLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CuentasPorCobrarError) {
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
                    context.read<CuentasPorCobrarCubit>().cargarCuentas(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is CuentasPorCobrarLoaded) {
      if (state.filtradas.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 12),
              Text(
                state.hayFiltrosActivos
                    ? 'Sin resultados para los criterios aplicados'
                    : 'No hay cuentas registradas',
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
          if (state is CuentasPorCobrarOperating)
            LinearProgressIndicator(
              backgroundColor: ac.primaryGreen.withValues(alpha: 0.1),
              color: ac.primaryGreen,
              minHeight: 2,
            ),
          Expanded(
            child: ListView.separated(
              padding: context.pageInsets(top: 8, bottom: 24),
              itemCount: state.filtradas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cuenta = state.filtradas[index];
                return CuentaCard(
                  cuenta: cuenta,
                  onEliminar: cuenta.id != null
                      ? () => _confirmarEliminacion(
                          cuenta.id!,
                          'Consulta #${cuenta.consultaId.length > 8 ? cuenta.consultaId.substring(0, 8) : cuenta.consultaId}',
                        )
                      : null,
                );
              },
            ),
          ),
          _buildFooter(state, ac),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFooter(CuentasPorCobrarLoaded state, AppColors ac) {
    final shown = state.filtradas.length;
    final total = state.todas.length;

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
                color: shown == total ? ac.primaryGreen : ac.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                shown == total
                    ? '$total cuenta${total == 1 ? '' : 's'} en total'
                    : '$shown de $total cuenta${total == 1 ? '' : 's'}',
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
                    fontSize: 13,
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
