import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
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
  Timer? _debounce;
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
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _getMedicinas();
    result.fold(
      (f) => setState(() {
        _loading = false;
        _error = f.message;
      }),
      (list) => setState(() {
        _loading = false;
        _medicinas = list;
        _applyFilter();
      }),
    );
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(_applyFilter);
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase().trim();
    _filtered = q.isEmpty
        ? List.from(_medicinas)
        : _medicinas.where((m) => m.nombre.toLowerCase().contains(q)).toList();
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
                        color: ac.red.withOpacity(0.10),
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
    final ac = context.appColors;
    return ColoredBox(
      color: ac.bgPage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderAndSearch(ac),
          Expanded(child: _buildBody(ac)),
        ],
      ),
    );
  }

  Widget _buildHeaderAndSearch(AppColors ac) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    if (_medicinas.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ac.primaryBlue.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_medicinas.length}',
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
                  ],
                ),
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
                        setState(_applyFilter);
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
                borderSide: BorderSide(color: ac.primaryBlue, width: 1.2),
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

  Widget _buildBody(AppColors ac) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: ac.primaryBlue));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: ac.red),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 13, color: ac.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
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
              color: ac.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isEmpty
                  ? 'No hay medicinas registradas.\nPresiona "Nueva medicina" para comenzar.'
                  : 'Sin resultados para "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ac.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(ac),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
            itemCount: _filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MedicinaRow(
              medicina: _filtered[i],
              onEdit: () => _openForm(medicina: _filtered[i]),
              onDelete: () => _confirmDelete(_filtered[i]),
            ),
          ),
        ),
        _buildFooter(ac),
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

  Widget _buildFooter(AppColors ac) {
    final shown = _filtered.length;
    final total = _medicinas.length;

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
                  ? '$total medicina${total == 1 ? '' : 's'} en total'
                  : '$shown de $total medicina${total == 1 ? '' : 's'}',
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
        ? ac.primaryBlue.withOpacity(0.04)
        : ac.cardBg;
    final colorBorde = _expanded
        ? ac.primaryBlue.withOpacity(0.25)
        : ac.divider.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_expanded ? 0.03 : 0.01),
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
            hoverColor: ac.primaryBlue.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
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
                            color: ac.primaryBlue.withOpacity(0.08),
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
                            efectos.take(3).map((e) => e.label).join(', '),
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
                                    padding: const EdgeInsets.only(bottom: 4),
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
                                            overflow: TextOverflow.ellipsis,
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
                          color: ac.textSecondary.withOpacity(0.6),
                          onTap: widget.onEdit,
                        ),
                        const SizedBox(width: 2),
                        _ActionIcon(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Eliminar',
                          color: ac.red.withOpacity(0.70),
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

  Widget _buildDetail(BuildContext context, AppColors ac) {
    final efectos = widget.medicina.efectosSecundarios;
    final contras = widget.medicina.contraindicaciones;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardBg.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: ac.divider.withOpacity(0.4), height: 1),
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
