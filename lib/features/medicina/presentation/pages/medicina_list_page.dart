import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/efecto_adverso.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/delete_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/get_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/cubit/medicinas_cubit.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_form_page.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/providers/medicinas_state.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/widgets/contraindicaciones_card.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/widgets/efectos_secundarios_card.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';

class MedicinaListPage extends StatefulWidget {
  final IMedicinaRepository repository;
  const MedicinaListPage({super.key, required this.repository});

  @override
  State<MedicinaListPage> createState() => _MedicinaListPageState();
}

class _MedicinaListPageState extends State<MedicinaListPage> {
  late final MedicinasCubit _cubit;
  late final DeleteMedicina _deleteMedicina;
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Filtro adicional (en cliente) por efectos adversos de las
  // contraindicaciones — el cubit no lo maneja, así que se aplica aquí
  // sobre la lista ya filtrada por búsqueda/efecto secundario.
  final Set<EfectoAdverso> _efectosAdversosSeleccionados = {};

  @override
  void initState() {
    super.initState();
    _deleteMedicina = DeleteMedicina(widget.repository);
    _cubit = MedicinasCubit(getMedicinas: GetMedicinas(widget.repository))
      ..loadMedicinas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _cubit.updateSearchQuery(_searchController.text);
    });
  }

  Future<void> _openForm({Medicina? medicina}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicinaFormPage(repository: widget.repository, medicina: medicina),
      ),
    );
    _cubit.loadMedicinas();
  }

  List<Medicina> _applyEfectosAdversosFilter(List<Medicina> medicinas) {
    if (_efectosAdversosSeleccionados.isEmpty) return medicinas;
    return medicinas.where((m) {
      return m.contraindicaciones.any(
        (c) => c.efectosAdversos.any(_efectosAdversosSeleccionados.contains),
      );
    }).toList();
  }

  Future<void> _showEfectosAdversosFilterSheet(AppColors ac) async {
    var seleccionActual = Set<EfectoAdverso>.from(
      _efectosAdversosSeleccionados,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: ac.cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ac.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: ac.red.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.filter_alt_outlined,
                          size: 17,
                          color: ac.red,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Filtrar por efecto adverso',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ac.textPrimary,
                          ),
                        ),
                      ),
                      if (seleccionActual.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              setSheetState(() => seleccionActual.clear()),
                          child: const Text('Limpiar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Muestra medicinas cuyas contraindicaciones incluyen '
                    'alguno de estos efectos adversos.',
                    style: TextStyle(fontSize: 12, color: ac.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EfectoAdverso.values.map((efecto) {
                      final selected = seleccionActual.contains(efecto);
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          selected
                              ? seleccionActual.remove(efecto)
                              : seleccionActual.add(efecto);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? ac.red.withValues(alpha: 0.10)
                                : ac.bgPage,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: selected
                                  ? ac.red.withValues(alpha: 0.50)
                                  : ac.divider,
                              width: selected ? 1.0 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected) ...[
                                Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: ac.red,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                efecto.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? ac.red : ac.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _efectosAdversosSeleccionados
                            ..clear()
                            ..addAll(seleccionActual);
                        });
                        Navigator.pop(sheetContext);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        seleccionActual.isEmpty
                            ? 'Mostrar todas'
                            : 'Aplicar filtro (${seleccionActual.length})',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return BlocProvider.value(
      value: _cubit,
      child: ColoredBox(
        color: ac.bgPage,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderAndSearch(ac),
            Expanded(
              child: BlocBuilder<MedicinasCubit, MedicinasState>(
                builder: (context, state) {
                  if (state is MedicinasLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: ac.primaryBlue),
                    );
                  }
                  if (state is MedicinasError) {
                    return _buildErrorWidget(state.message);
                  }
                  if (state is MedicinasLoaded) {
                    return _buildListContent(ac, state);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch(AppColors ac) {
    return BlocBuilder<MedicinasCubit, MedicinasState>(
      builder: (context, state) {
        int totalMedicinas = 0;
        if (state is MedicinasLoaded) {
          totalMedicinas = state.allMedicinas.length;
        }

        return Padding(
          padding: context.pageInsets(top: 28, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A Row would clip the counter badge once the title and the
              // action button no longer fit; wrapping drops the button down.
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Título y contador: con texto ampliado el contador baja de
                  // línea en vez de empujar el título fuera de la cabecera.
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Medicinas',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: ac.textPrimary,
                        ),
                      ),
                      if (totalMedicinas > 0)
                        Container(
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
                                '$totalMedicinas',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: ac.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.medication_outlined,
                                size: 13,
                                color: ac.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Nueva medicina',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryBlue,
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
                'Gestión de medicamentos y protocolos de seguridad.',
                style: TextStyle(fontSize: 13, color: ac.textMuted),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
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
                            _cubit.updateSearchQuery('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: ac.searchFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ac.divider.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: ac.divider.withValues(alpha: 0.2),
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
              ),
              const SizedBox(height: 12),
              if (state is MedicinasLoaded)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildEfectoSecundarioFilterButton(ac, state),
                    _buildEfectosAdversosFilterButton(ac),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEfectosAdversosFilterButton(AppColors ac) {
    final activo = _efectosAdversosSeleccionados.isNotEmpty;
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => _showEfectosAdversosFilterSheet(ac),
        icon: Icon(
          Icons.block_rounded,
          size: 17,
          color: activo ? ac.red : ac.textSecondary,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Efecto adverso'),
            if (activo) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ac.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_efectosAdversosSeleccionados.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: activo ? ac.red : ac.textMuted,
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: activo ? ac.red : ac.textSecondary,
          side: BorderSide(
            color: activo ? ac.red.withValues(alpha: 0.5) : ac.divider,
            width: activo ? 1.0 : 0.5,
          ),
          backgroundColor: activo ? ac.red.withValues(alpha: 0.06) : ac.bgPage,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEfectoSecundarioFilterButton(
    AppColors ac,
    MedicinasLoaded state,
  ) {
    final activo = state.selectedEfectos.isNotEmpty;
    const amber = Color(0xFFB45309);
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () => _showEfectoSecundarioFilterSheet(ac),
        icon: Icon(
          Icons.medication_liquid_outlined,
          size: 17,
          color: activo ? amber : ac.textSecondary,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Efecto secundario'),
            if (activo) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.selectedEfectos.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: activo ? amber : ac.textMuted,
            ),
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: activo ? amber : ac.textSecondary,
          side: BorderSide(
            color: activo ? amber.withValues(alpha: 0.5) : ac.divider,
            width: activo ? 1.0 : 0.5,
          ),
          backgroundColor: activo
              ? const Color(0xFFFEF3C7).withValues(alpha: 0.5)
              : ac.bgPage,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _showEfectoSecundarioFilterSheet(AppColors ac) async {
    const amber = Color(0xFFB45309);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocBuilder<MedicinasCubit, MedicinasState>(
          bloc: _cubit,
          builder: (context, state) {
            final selected = state is MedicinasLoaded
                ? state.selectedEfectos
                : const <EfectoSecundario>{};
            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: ac.cardBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ac.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medication_liquid_outlined,
                          size: 17,
                          color: amber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Filtrar por efecto secundario',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ac.textPrimary,
                          ),
                        ),
                      ),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            for (final e in List.of(selected)) {
                              _cubit.toggleEfectoSecundario(e);
                            }
                          },
                          child: const Text('Limpiar'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Muestra medicinas que reportan alguno de estos efectos '
                    'secundarios comunes.',
                    style: TextStyle(fontSize: 12, color: ac.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EfectoSecundario.values.map((efecto) {
                      final isSelected = selected.contains(efecto);
                      return GestureDetector(
                        onTap: () => _cubit.toggleEfectoSecundario(efecto),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFEF3C7)
                                : ac.bgPage,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD97706)
                                  : ac.divider,
                              width: isSelected ? 1.0 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(
                                  Icons.check_rounded,
                                  size: 12,
                                  color: amber,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                efecto.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? amber : ac.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Listo'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListContent(AppColors ac, MedicinasLoaded state) {
    final medicinasFiltradas = _applyEfectosAdversosFilter(
      state.filteredMedicinas,
    );

    if (medicinasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 56,
              color: ac.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Sin resultados con los criterios aplicados.\nBusca otra combinación.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ac.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (MediaQuery.sizeOf(context).width >= 600) _buildTableHeader(ac),
        Expanded(
          child: ListView.separated(
            padding: context.pageInsets(top: 4, bottom: 24),
            itemCount: medicinasFiltradas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MedicinaRow(
              medicina: medicinasFiltradas[i],
              onEdit: () => _openForm(medicina: medicinasFiltradas[i]),
              onDelete: () => _confirmDelete(medicinasFiltradas[i]),
            ),
          ),
        ),
        _buildFooter(ac, medicinasFiltradas.length, state.allMedicinas.length),
      ],
    );
  }

  Widget _buildTableHeader(AppColors ac) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(68, 8, 28, 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _HeaderLabel(text: 'NOMBRE DEL FÁRMACO', ac: ac),
          ),
          Expanded(
            flex: 3,
            child: _HeaderLabel(text: 'EFECTOS COMUNES', ac: ac),
          ),
          Expanded(
            flex: 3,
            child: _HeaderLabel(text: 'CONTRAINDICACIONES', ac: ac),
          ),
          const SizedBox(width: 72),
        ],
      ),
    );
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
                color: shown == total ? ac.primaryBlue : ac.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                shown == total
                    ? '$total medicinas en total'
                    : '$shown de $total medicinas',
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: context.appColors.red,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 13, color: context.appColors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _cubit.loadMedicinas(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Medicina medicina) async {
    final ac = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ac.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: ac.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: ac.red,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Eliminar medicina',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ac.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '¿Deseas eliminar "${medicina.nombre}"? Esta acción no se puede deshacer.',
                  style: TextStyle(fontSize: 13, color: ac.textSecondary),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ac.textSecondary,
                        side: BorderSide(color: ac.divider),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(ctx, true),
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Eliminar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ac.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final result = await _deleteMedicina(medicina.id!);
    result.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) => _cubit.loadMedicinas(),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  final AppColors ac;
  const _HeaderLabel({required this.text, required this.ac});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: ac.textMuted,
      ),
    );
  }
}

class _MedicinaRow extends StatefulWidget {
  final Medicina medicina;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicinaRow({
    required this.medicina,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_MedicinaRow> createState() => _MedicinaRowState();
}

class _MedicinaRowState extends State<_MedicinaRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final efectos = widget.medicina.efectosSecundarios;
    final contras = widget.medicina.contraindicaciones;

    final fondoTarjeta = _expanded
        ? ac.primaryBlue.withValues(alpha: 0.04)
        : ac.cardBg;
    final colorBorde = _expanded
        ? ac.primaryBlue.withValues(alpha: 0.25)
        : ac.divider.withValues(alpha: 0.4);

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
            color: Colors.black.withValues(alpha: _expanded ? 0.03 : 0.01),
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
                  ? _buildCompactRow(context, ac, efectos, contras)
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
                                  color: ac.primaryBlue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.medication_outlined,
                                  size: 18,
                                  color: ac.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  widget.medicina.nombre,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: ac.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: efectos.isEmpty
                              ? Text(
                                  'Sin efectos registrados',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: ac.textMuted,
                                  ),
                                )
                              : Text(
                                  efectos
                                      .take(3)
                                      .map((e) => e.label)
                                      .join(', '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: ac.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        Expanded(
                          flex: 3,
                          child: contras.isEmpty
                              ? Text(
                                  'Sin contraindicaciones',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: ac.textMuted,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: contras
                                      .take(2)
                                      .map(
                                        (c) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                size: 13,
                                                color: ac.red,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  c.descripcion,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: ac.red,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ActionIcon(
                                icon: Icons.edit_outlined,
                                tooltip: 'Editar',
                                color: ac.textSecondary.withValues(alpha: 0.6),
                                onTap: widget.onEdit,
                              ),
                              const SizedBox(width: 2),
                              _ActionIcon(
                                icon: Icons.delete_outline_rounded,
                                tooltip: 'Eliminar',
                                color: ac.red.withValues(alpha: 0.70),
                                onTap: widget.onDelete,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_expanded) _buildDetail(context, ac),
        ],
      ),
    );
  }

  Widget _buildCompactRow(
    BuildContext context,
    AppColors ac,
    List efectos,
    List contras,
  ) {
    final name = widget.medicina.nombre;
    final effects = efectos.isEmpty
        ? 'Sin efectos registrados'
        : efectos.take(3).map((e) => e.label).join(', ');
    final contraindications = contras.isEmpty
        ? 'Sin contraindicaciones'
        : contras.take(2).map((c) => c.descripcion).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ac.primaryBlue.withValues(alpha: .08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_outlined,
                size: 18,
                color: ac.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ),
            _ActionIcon(
              icon: Icons.edit_outlined,
              tooltip: 'Editar',
              color: ac.textSecondary.withValues(alpha: .6),
              onTap: widget.onEdit,
            ),
            _ActionIcon(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Eliminar',
              color: ac.red.withValues(alpha: .7),
              onTap: widget.onDelete,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _compactField(context, 'Efectos comunes', effects),
        const SizedBox(height: 6),
        _compactField(context, 'Contraindicaciones', contraindications),
      ],
    );
  }

  Widget _compactField(BuildContext context, String label, String value) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: context.appColors.textMuted,
              letterSpacing: .5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: context.appColors.textSecondary,
            ),
          ),
        ],
      );

  Widget _buildDetail(BuildContext context, AppColors ac) {
    final efectos = widget.medicina.efectosSecundarios;
    final contras = widget.medicina.contraindicaciones;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: ac.divider.withValues(alpha: 0.4), height: 1),
          const SizedBox(height: 20),
          Wrap(
            spacing: 40,
            runSpacing: 16,
            children: [
              _DetailItem(
                ac: ac,
                label: 'Efectos secundarios',
                value: efectos.isEmpty
                    ? 'Ninguno'
                    : '${efectos.length} registrado${efectos.length == 1 ? '' : 's'}',
              ),
              _DetailItem(
                ac: ac,
                label: 'Contraindicaciones',
                value: contras.isEmpty
                    ? 'Ninguna'
                    : '${contras.length} registrada${contras.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          EfectosSecundariosCard(efectos: efectos),
          const SizedBox(height: 10),
          ContraindicacionesCard(contraindicaciones: contras),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final AppColors ac;
  final String label;
  final String value;
  const _DetailItem({
    required this.ac,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: ac.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ac.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

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
