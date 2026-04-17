import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/delete_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/get_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_form_page.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/widgets/contraindicaciones_card.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/widgets/efectos_secundarios_card.dart';

class MedicinaListPage extends StatefulWidget {
  final IMedicinaRepository repository;

  const MedicinaListPage({super.key, required this.repository});

  @override
  State<MedicinaListPage> createState() => _MedicinaListPageState();
}

class _MedicinaListPageState extends State<MedicinaListPage> {
  late final GetMedicinas _getMedicinas;
  late final DeleteMedicina _deleteMedicina;

  List<Medicina> _medicinas = [];
  List<Medicina> _filtered = [];
  final _searchController = TextEditingController();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getMedicinas = GetMedicinas(widget.repository);
    _deleteMedicina = DeleteMedicina(widget.repository);
    _searchController.addListener(_onSearch);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _getMedicinas();
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (list) => setState(() {
        _loading = false;
        _medicinas = list;
        _applyFilter();
      }),
    );
  }

  void _onSearch() => setState(() => _applyFilter());

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    _filtered = query.isEmpty
        ? List.from(_medicinas)
        : _medicinas
              .where((m) => m.nombre.toLowerCase().contains(query))
              .toList();
  }

  Future<void> _confirmDelete(Medicina medicina) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar medicina'),
        content: Text('¿Deseas eliminar "${medicina.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await _deleteMedicina(medicina.id);
    result.fold(
      (f) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(f.message))),
      (_) => _load(),
    );
  }

  Future<void> _openForm({Medicina? medicina}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicinaFormPage(repository: widget.repository, medicina: medicina),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            _buildStatsBar(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medicinas',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gestión de base de datos de medicamentos y protocolos de seguridad.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar Medicina'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar medicina por nombre...',
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  onPressed: _searchController.clear,
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Text(
            'TOTAL DE MEDICINAS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_medicinas.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.check_circle, color: colorScheme.primary, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay medicinas registradas.\nPresiona "Agregar Medicina" para comenzar.'
                  : 'Sin resultados para "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: _filtered.length,
            separatorBuilder: (context2, index2) => const SizedBox(height: 4),
            itemBuilder: (_, index) => _MedicinaRow(
              medicina: _filtered[index],
              onEdit: () => _openForm(medicina: _filtered[index]),
              onDelete: () => _confirmDelete(_filtered[index]),
            ),
          ),
        ),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildTableHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerLabel(context, 'NOMBRE DEL FÁRMACO')),
          Expanded(flex: 3, child: _headerLabel(context, 'EFECTOS COMUNES')),
          Expanded(
            flex: 3,
            child: _headerLabel(context, 'CONTRAINDICACIONES CRÍTICAS'),
          ),
          const SizedBox(width: 90),
        ],
      ),
    );
  }

  Widget _headerLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shown = _filtered.length;
    final total = _medicinas.length;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        'Mostrando $shown–$shown de $total medicina${total == 1 ? '' : 's'}',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

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
    final colorScheme = Theme.of(context).colorScheme;
    final efectos = widget.medicina.efectosSecundarios;
    final contras = widget.medicina.contraindicaciones;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _expanded
              ? colorScheme.primary.withAlpha(80)
              : colorScheme.outlineVariant,
        ),
        boxShadow: _expanded
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Expanded(
                    flex: 3,
                    child: Text(
                      widget.medicina.nombre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Efectos comunes
                  Expanded(
                    flex: 3,
                    child: efectos.isEmpty
                        ? Text(
                            'Sin efectos registrados',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                          )
                        : Text(
                            efectos.take(3).map((e) => e.label).join(', '),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                  ),
                  // Contraindicaciones críticas
                  Expanded(
                    flex: 3,
                    child: contras.isEmpty
                        ? Text(
                            'Sin contraindicaciones críticas',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: contras.take(2).map((c) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 14,
                                      color: colorScheme.error,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        c.descripcion,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colorScheme.error,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                  // Acciones
                  SizedBox(
                    width: 90,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionIcon(
                          icon: _expanded
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          tooltip: _expanded
                              ? 'Ocultar detalle'
                              : 'Ver detalle',
                          color: colorScheme.primary,
                          onTap: () => setState(() => _expanded = !_expanded),
                        ),
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          tooltip: 'Editar',
                          color: colorScheme.onSurfaceVariant,
                          onTap: widget.onEdit,
                        ),
                        _ActionIcon(
                          icon: Icons.delete_outline,
                          tooltip: 'Eliminar',
                          color: colorScheme.error,
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: colorScheme.outlineVariant, height: 20),
                  EfectosSecundariosCard(
                    efectos: widget.medicina.efectosSecundarios,
                  ),
                  const SizedBox(height: 8),
                  ContraindicacionesCard(
                    contraindicaciones: widget.medicina.contraindicaciones,
                  ),
                ],
              ),
            ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
