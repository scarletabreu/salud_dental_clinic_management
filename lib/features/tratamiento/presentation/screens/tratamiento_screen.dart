import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/cubit/tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/cubit/tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_form_dialog.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_card.dart';

class TratamientosScreen extends StatelessWidget {
  const TratamientosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TratamientoCubit>()..loadTratamientos(),
      child: const _TratamientosView(),
    );
  }
}

class _TratamientosView extends StatefulWidget {
  const _TratamientosView();

  @override
  State<_TratamientosView> createState() => _TratamientosViewState();
}

class _TratamientosViewState extends State<_TratamientosView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.toLowerCase().trim());
    });
  }

  List<Tratamiento> _applyFilter(List<Tratamiento> all) {
    if (_query.isEmpty) return all;
    return all.where((t) => t.nombre.toLowerCase().contains(_query)).toList();
  }

  void _abrirFormulario([Tratamiento? tratamiento]) {
    final cubit = context.read<TratamientoCubit>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: TratamientoFormDialog(tratamiento: tratamiento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TratamientoCubit, TratamientoState>(
      listener: (context, state) {
        if (state is TratamientoError) {
          final ac = context.appColors;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: ac.red),
          );
        }
      },
      child: BlocBuilder<TratamientoCubit, TratamientoState>(
        builder: (context, state) {
          final ac = context.appColors;
          return ColoredBox(
            color: ac.bgPage,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderAndSearch(ac, state),
                Expanded(child: _buildBody(context, ac, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderAndSearch(AppColors ac, TratamientoState state) {
    final total = state is TratamientoLoaded ? state.tratamientos.length : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
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
                    'Tratamientos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      color: ac.textPrimary,
                    ),
                  ),
                  if (total > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ac.primaryGreen.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ac.primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.medical_services_outlined,
                            size: 13,
                            color: ac.primaryGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              FilledButton.icon(
                onPressed: () => _abrirFormulario(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Nuevo servicio',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: ac.primaryGreen,
                  foregroundColor: Colors.white,
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
            'Catálogo de servicios y procedimientos dentales disponibles.',
            style: TextStyle(fontSize: 13, color: ac.textMuted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onSearch,
            style: TextStyle(fontSize: 14, color: ac.textPrimary),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre…',
              hintStyle: TextStyle(fontSize: 14, color: ac.textMuted),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: ac.textMuted,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: ac.textMuted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: ac.searchFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ac.divider.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ac.divider.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ac.primaryGreen, width: 1.2),
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
    AppColors ac,
    TratamientoState state,
  ) {
    if (state is TratamientoLoading) {
      return Center(child: CircularProgressIndicator(color: ac.primaryGreen));
    }

    if (state is TratamientoError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: ac.red),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(fontSize: 13, color: ac.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  context.read<TratamientoCubit>().loadTratamientos(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is TratamientoLoaded) {
      final filtered = _applyFilter(state.tratamientos);

      if (filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medical_services_outlined,
                size: 56,
                color: ac.textMuted.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                _query.isEmpty
                    ? 'No hay tratamientos configurados.\nPresiona "Nuevo servicio" para comenzar.'
                    : 'Sin resultados para "$_query".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: ac.textSecondary),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => TratamientoCard(
                tratamiento: filtered[i],
                onEdit: () => _abrirFormulario(filtered[i]),
              ),
            ),
          ),
          _buildFooter(ac, filtered.length, state.tratamientos.length),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildFooter(AppColors ac, int shown, int total) {
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
            Text(
              shown == total
                  ? '$total tratamiento${total == 1 ? '' : 's'} en total'
                  : '$shown de $total tratamiento${total == 1 ? '' : 's'}',
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
