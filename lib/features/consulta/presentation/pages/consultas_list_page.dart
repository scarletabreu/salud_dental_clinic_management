import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/core/util/fecha_es.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/helpers/consulta_helper.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/consulta_detalle_page.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/efectuar_consulta_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';

class ConsultasListPage extends StatefulWidget {
  const ConsultasListPage({super.key});

  @override
  State<ConsultasListPage> createState() => _ConsultasListPageState();
}

class _ConsultasListPageState extends State<ConsultasListPage> {
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
      if (mounted) {
        context.read<ConsultasListCubit>().buscarPaciente(
          _searchController.text,
        );
      }
    });
  }

  Future<void> _seleccionarRango(DateTimeRange? actual) async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 5),
      lastDate: DateTime(ahora.year + 1, 12, 31),
      initialDateRange: actual,
      helpText: 'Selecciona un rango de fechas',
      saveText: 'Aplicar',
    );
    if (rango != null && mounted) {
      context.read<ConsultasListCubit>().filtrarPorRango(rango);
    }
  }

  void _abrirDetalle(Consulta consulta, ConsultasLoaded state) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultaDetallePage(
          consulta: consulta,
          nombrePaciente: state.nombrePaciente(consulta.pacienteId),
          nombreDoctor: state.nombreDoctor(consulta.doctorId),
        ),
      ),
    );
    if (resultado == true && mounted) {
      context.read<ConsultasListCubit>().recargar();
    }
  }

  void _abrirModalFiltrosAvanzados(
    BuildContext context,
    ConsultasLoaded state,
  ) {
    final cubit = context.read<ConsultasListCubit>();
    final ac = context.appColors;
    bool? finalizada = state.finalizada;
    bool? tieneNotas = state.tieneNotas;
    bool? tieneOdontograma = state.tieneOdontograma;
    bool? tieneRecetas = state.tieneRecetas;
    bool? tieneTratamientos = state.tieneTratamientos;
    bool? soloEmergencias = state.soloEmergencias;

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
                  Icon(Icons.tune_rounded, color: ac.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros Combinables de Consultas',
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

              SwitchListTile(
                title: const Text(
                  'Completadas (Finalizadas)',
                  style: TextStyle(fontSize: 13),
                ),
                value: finalizada == true,
                activeThumbColor: ac.primaryBlue,
                onChanged: (v) =>
                    setModalState(() => finalizada = v ? true : null),
              ),
              SwitchListTile(
                title: const Text(
                  'Con notas / observaciones clínicas',
                  style: TextStyle(fontSize: 13),
                ),
                value: tieneNotas == true,
                activeThumbColor: ac.primaryBlue,
                onChanged: (v) =>
                    setModalState(() => tieneNotas = v ? true : null),
              ),
              SwitchListTile(
                title: const Text(
                  'Con odontograma registrado',
                  style: TextStyle(fontSize: 13),
                ),
                value: tieneOdontograma == true,
                activeThumbColor: ac.primaryBlue,
                onChanged: (v) =>
                    setModalState(() => tieneOdontograma = v ? true : null),
              ),
              SwitchListTile(
                title: const Text(
                  'Con recetas prescritas',
                  style: TextStyle(fontSize: 13),
                ),
                value: tieneRecetas == true,
                activeThumbColor: ac.primaryBlue,
                onChanged: (v) =>
                    setModalState(() => tieneRecetas = v ? true : null),
              ),
              SwitchListTile(
                title: const Text(
                  'Con tratamientos aplicados',
                  style: TextStyle(fontSize: 13),
                ),
                value: tieneTratamientos == true,
                activeThumbColor: ac.primaryBlue,
                onChanged: (v) =>
                    setModalState(() => tieneTratamientos = v ? true : null),
              ),
              SwitchListTile(
                title: const Text(
                  'Atención de emergencia',
                  style: TextStyle(fontSize: 13),
                ),
                value: soloEmergencias == true,
                activeThumbColor: ac.red,
                onChanged: (v) =>
                    setModalState(() => soloEmergencias = v ? true : null),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      cubit.aplicarFiltrosAvanzados(
                        finalizada: finalizada,
                        tieneNotas: tieneNotas,
                        tieneOdontograma: tieneOdontograma,
                        tieneRecetas: tieneRecetas,
                        tieneTratamientos: tieneTratamientos,
                        soloEmergencias: soloEmergencias,
                      );
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Aplicar Filtros'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: BlocBuilder<ConsultasListCubit, ConsultasListState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderYFiltros(context, state),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderYFiltros(BuildContext context, ConsultasListState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = state is ConsultasLoaded ? state.todas.length : 0;

    return Padding(
      padding: context.pageInsets(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Consultas',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              if (state is ConsultasLoaded) ...[
                const SizedBox(width: 14),
                _CountBadge(count: total),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar listado',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () =>
                      context.read<ConsultasListCubit>().recargar(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Historial de consultas registradas, filtrables dinámicamente.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchBar(context),
          if (state is ConsultasLoaded) ...[
            const SizedBox(height: 14),
            _buildFiltros(context, state),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;
    return TextField(
      controller: _searchController,
      onChanged: (_) => _onSearch(),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre de paciente...',
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
                  context.read<ConsultasListCubit>().buscarPaciente('');
                },
              )
            : null,
        filled: true,
        fillColor: ac.searchFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ac.primaryBlue, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context, ConsultasLoaded state) {
    final cubit = context.read<ConsultasListCubit>();
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    final doctorChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DoctorChip(
            label: 'Todos los doctores',
            selected: state.doctorIdFiltro == null,
            onTap: () => cubit.filtrarPorDoctor(null),
          ),
          for (final doctor in state.doctores)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _DoctorChip(
                label: 'Dr. ${doctor.fullName}',
                selected: state.doctorIdFiltro == doctor.id,
                onTap: () => cubit.filtrarPorDoctor(doctor.id),
              ),
            ),
        ],
      ),
    );

    final rangeButton = OutlinedButton.icon(
      onPressed: () => _seleccionarRango(state.rangoFechas),
      icon: Icon(Icons.date_range_rounded, size: 18, color: ac.primaryBlue),
      label: Text(
        state.rangoFechas == null
            ? 'Rango de fechas'
            : '${fechaNumericaEs(state.rangoFechas!.start)} – ${fechaNumericaEs(state.rangoFechas!.end)}',
        style: TextStyle(
          color: state.rangoFechas == null
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: state.rangoFechas == null
            ? ac.searchFill
            : ac.primaryBlue.withValues(alpha: 0.08),
        side: BorderSide(
          color: state.rangoFechas == null
              ? colorScheme.outlineVariant.withValues(alpha: 0.3)
              : ac.primaryBlue.withValues(alpha: 0.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final btnFiltrosAvanzados = FilledButton.icon(
      onPressed: () => _abrirModalFiltrosAvanzados(context, state),
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: const Text('Filtros'),
      style: FilledButton.styleFrom(
        backgroundColor: state.hayFiltrosActivos
            ? ac.primaryBlue
            : ac.searchFill,
        foregroundColor: state.hayFiltrosActivos
            ? Colors.white
            : ac.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (state.puedeFiltrarPorDoctor)
          SizedBox(width: 300, child: doctorChips),
        rangeButton,
        btnFiltrosAvanzados,
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
    );
  }

  Widget _buildBody(BuildContext context, ConsultasListState state) {
    if (state is ConsultasLoading || state is ConsultasInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ConsultasError) {
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
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.read<ConsultasListCubit>().cargar(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is ConsultasLoaded) {
      if (state.filtradas.isEmpty) {
        return _buildEmpty(context, state);
      }
      return Column(
        children: [
          const _IndicadoresConsultasLeyenda(),
          Expanded(
            child: ListView.separated(
              padding: context.pageInsets(top: 4, bottom: 24),
              itemCount: state.filtradas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final consulta = state.filtradas[i];
                return ConsultaListCard(
                  consulta: consulta,
                  nombrePaciente: state.nombrePaciente(consulta.pacienteId),
                  nombreDoctor: state.nombreDoctor(consulta.doctorId),
                  tieneTratamientos: consulta.tieneTratamientosAplicados,
                  onTap: () => _abrirDetalle(consulta, state),
                );
              },
            ),
          ),
          _buildFooter(context, state),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmpty(BuildContext context, ConsultasLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 56,
            color: colorScheme.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 12),
          Text(
            state.hayFiltrosActivos
                ? 'No hay consultas que coincidan con los filtros.'
                : 'Aún no hay consultas registradas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (state.hayFiltrosActivos) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                context.read<ConsultasListCubit>().limpiarFiltros();
              },
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ConsultasLoaded state) {
    final ac = context.appColors;
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
                color: shown == total ? ac.primaryBlue : ac.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                shown == total
                    ? '$total consulta${total == 1 ? '' : 's'} en total'
                    : '$shown de $total consulta${total == 1 ? '' : 's'}',
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

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ac.primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ac.primaryBlue,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.medical_information_rounded,
            color: ac.primaryBlue,
            size: 13,
          ),
        ],
      ),
    );
  }
}

class _DoctorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DoctorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? ac.primaryBlue : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      backgroundColor: ac.searchFill,
      selectedColor: ac.primaryBlue.withValues(alpha: 0.1),
      side: BorderSide(
        color: selected
            ? ac.primaryBlue.withValues(alpha: 0.4)
            : colorScheme.outlineVariant.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// La fila de una consulta conserva el orden de sus controles para que la
/// acción final forme una columna visual estable en toda la lista.
class ConsultaListCard extends StatelessWidget {
  final Consulta consulta;
  final String nombrePaciente;
  final String nombreDoctor;
  final bool tieneTratamientos;
  final VoidCallback onTap;

  const ConsultaListCard({
    super.key,
    required this.consulta,
    required this.nombrePaciente,
    required this.nombreDoctor,
    required this.tieneTratamientos,
    required this.onTap,
  });

  void _mostrarDialogoEliminar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: const Text('Eliminar Consulta'),
        preferredWidth: 480,
        actionsPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta consulta será eliminada junto con su odontograma, dientes, superficies y diagnósticos aplicados.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 20,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aviso Legal',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solo se permite para consultas creadas por error hoy, sin tratamientos aplicados ni pre-factura (Ley 172-13).',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.error),
                        ),
                      ],
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
              context.read<ConsultasListCubit>().eliminarConsulta(consulta);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;
    final esEliminable = esConsultaEliminable(consulta);
    final layout = context.appLayout;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          hoverColor: ac.primaryBlue.withValues(alpha: 0.02),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _DateBadge(fecha: consulta.fecha),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombrePaciente,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (!context.isCompactLayout) ...[
                            Icon(
                              Icons.medical_services_outlined,
                              size: 13,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              nombreDoctor,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // No es Flexible: el bloque de datos cede primero y esta
                // gramática conserva su ancho, anclando su acción final.
                _AccionesConsulta(
                  consulta: consulta,
                  tieneTratamientos: tieneTratamientos,
                  esEliminable: esEliminable,
                  layout: layout,
                  onEliminar: () => _mostrarDialogoEliminar(context),
                  onContinuar: () async {
                    final resultado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (_) =>
                                  sl<PacienteCubit>()
                                    ..loadParaConsulta(consulta.pacienteId),
                            ),
                            BlocProvider(create: (_) => sl<ConsultaCubit>()),
                          ],
                          child: EfectuarConsultaPage(
                            citaId: consulta.citaId ?? '',
                            pacienteId: consulta.pacienteId,
                            doctorId: consulta.doctorId,
                            consultaId: consulta.id,
                          ),
                        ),
                      ),
                    );
                    if (resultado == true && context.mounted) {
                      context.read<ConsultasListCubit>().recargar();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IndicadoresConsultasLeyenda extends StatelessWidget {
  const _IndicadoresConsultasLeyenda();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final textoVisible = MediaQuery.textScalerOf(context).scale(1) <= 1.3;
    return Padding(
      padding: context.pageInsets(top: 0, bottom: 8),
      child: Semantics(
        container: true,
        label: 'Leyenda de indicadores de consultas',
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _LeyendaIndicador(
              icon: Icons.healing_rounded,
              color: ac.teal,
              label: 'Tratamientos aplicados',
              textoVisible: textoVisible,
            ),
            _LeyendaIndicador(
              icon: Icons.receipt_long_rounded,
              color: ac.primaryBlue,
              label: 'Tiene receta',
              textoVisible: textoVisible,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeyendaIndicador extends StatelessWidget {
  const _LeyendaIndicador({
    required this.icon,
    required this.color,
    required this.label,
    required this.textoVisible,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool textoVisible;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          if (textoVisible) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

enum _AccionMenuConsulta { eliminar }

class _AccionesConsulta extends StatelessWidget {
  const _AccionesConsulta({
    required this.consulta,
    required this.tieneTratamientos,
    required this.esEliminable,
    required this.layout,
    required this.onEliminar,
    required this.onContinuar,
  });

  final Consulta consulta;
  final bool tieneTratamientos;
  final bool esEliminable;
  final AppLayout layout;
  final VoidCallback onEliminar;
  final Future<void> Function() onContinuar;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    final textoVisible = layout.isDesktop;
    final razonEliminar = razonNoEliminable(consulta);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _EstadoConsulta(
          finalizada: consulta.finalizada,
          textoVisible: textoVisible,
        ),
        const SizedBox(width: 4),
        // Dos ranuras fijas: la ausencia de un indicador no mueve el menú ni
        // la acción principal.
        _IndicadorConsulta(
          presente: tieneTratamientos,
          icon: Icons.healing_rounded,
          color: ac.teal,
          label: 'Tratamientos aplicados',
          textoVisible: textoVisible,
        ),
        const SizedBox(width: 2),
        _IndicadorConsulta(
          presente: consulta.tieneRecetas,
          icon: Icons.receipt_long_rounded,
          color: ac.primaryBlue,
          label: 'Tiene receta',
          textoVisible: textoVisible,
        ),
        SizedBox(
          width: textoVisible ? 48 : 32,
          height: textoVisible ? 48 : 32,
          child: PopupMenuButton<_AccionMenuConsulta>(
            tooltip: 'Más acciones',
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            padding: EdgeInsets.zero,
            onSelected: (accion) {
              if (accion == _AccionMenuConsulta.eliminar) onEliminar();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _AccionMenuConsulta.eliminar,
                enabled: esEliminable,
                child: Semantics(
                  label: esEliminable
                      ? 'Eliminar consulta'
                      : 'Eliminar consulta no disponible. $razonEliminar',
                  child: ExcludeSemantics(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: esEliminable
                                ? colorScheme.error
                                : colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Eliminar consulta'),
                                if (razonEliminar != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    razonEliminar,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _AccionPrincipalConsulta(
          consulta: consulta,
          textoVisible: textoVisible,
          onContinuar: onContinuar,
        ),
      ],
    );
  }
}

class _EstadoConsulta extends StatelessWidget {
  const _EstadoConsulta({required this.finalizada, required this.textoVisible});

  final bool finalizada;
  final bool textoVisible;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = finalizada
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : ac.amber;
    final label = finalizada ? 'Finalizada' : 'En curso';
    return Semantics(
      label: 'Estado: $label',
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(minWidth: textoVisible ? 82 : 28),
          padding: EdgeInsets.symmetric(
            horizontal: textoVisible ? 8 : 6,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                finalizada
                    ? Icons.check_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                size: 14,
                color: color,
              ),
              if (textoVisible) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicadorConsulta extends StatelessWidget {
  const _IndicadorConsulta({
    required this.presente,
    required this.icon,
    required this.color,
    required this.label,
    required this.textoVisible,
  });

  final bool presente;
  final IconData icon;
  final Color color;
  final String label;
  final bool textoVisible;

  @override
  Widget build(BuildContext context) {
    final width = textoVisible ? 126.0 : 28.0;
    return SizedBox(
      width: width,
      child: presente
          ? Semantics(
              label: label,
              child: ExcludeSemantics(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: textoVisible ? 7 : 6,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      if (textoVisible) ...[
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            label == 'Tratamientos aplicados'
                                ? 'Tratamientos'
                                : 'Receta',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _AccionPrincipalConsulta extends StatelessWidget {
  const _AccionPrincipalConsulta({
    required this.consulta,
    required this.textoVisible,
    required this.onContinuar,
  });

  final Consulta consulta;
  final bool textoVisible;
  final Future<void> Function() onContinuar;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final clave = ValueKey('consulta-accion-principal-${consulta.id}');
    if (consulta.finalizada) {
      return Semantics(
        key: clave,
        label: 'Ver detalle de consulta finalizada',
        child: SizedBox(
          width: textoVisible ? 36 : 32,
          height: textoVisible ? 36 : 32,
          child: Center(
            child: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }
    if (!textoVisible) {
      return Semantics(
        key: clave,
        button: true,
        label: 'Continuar consulta',
        child: IconButton(
          onPressed: onContinuar,
          icon: const Icon(Icons.navigate_next_rounded, size: 18),
          color: ac.primaryBlue,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        ),
      );
    }
    return Semantics(
      key: clave,
      button: true,
      label: 'Continuar consulta',
      child: TextButton.icon(
        onPressed: onContinuar,
        icon: const Icon(Icons.navigate_next_rounded, size: 16),
        label: const Text('Continuar'),
        style: TextButton.styleFrom(
          foregroundColor: ac.primaryBlue,
          minimumSize: const Size(36, 36),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime fecha;
  const _DateBadge({required this.fecha});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: ac.primaryBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${fecha.day}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ac.primaryBlue,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${mesAbrevEs(fecha)} ${fecha.year}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ac.primaryBlue.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ac.primaryBlue.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
