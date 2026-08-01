import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/entities/procedimiento.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/presentarion/pages/procedimiento_form_page.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/widgets/solo_si_puede.dart';

class ProcedimientoListPage extends StatefulWidget {
  final ProcedimientoRepository repository;

  const ProcedimientoListPage({super.key, required this.repository});

  @override
  State<ProcedimientoListPage> createState() => _ProcedimientoListPageState();
}

class _ProcedimientoListPageState extends State<ProcedimientoListPage> {
  List<Procedimiento> _allProcedimientos = [];
  List<Procedimiento> _filteredProcedimientos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.repository.getCatalogoProcedimientos();
      if (!mounted) return;
      setState(() {
        _allProcedimientos = list;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar procedimientos: $e')),
      );
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredProcedimientos = _allProcedimientos.where((p) {
        return _searchQuery.isEmpty ||
            p.nombre.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  Future<void> _openForm({Procedimiento? procedimiento}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProcedimientoFormPage(
          repository: widget.repository,
          procedimiento: procedimiento,
        ),
      ),
    );

    if (result == true) {
      _loadCatalog();
    }
  }

  Future<void> _deleteProcedimiento(Procedimiento procedimiento) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ac = ctx.appColors;
        return AlertDialog(
          backgroundColor: ac.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Eliminar procedimiento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ac.textPrimary,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${procedimiento.nombre}"?',
            style: TextStyle(fontSize: 13, color: ac.textSecondary),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: ac.textSecondary,
                side: BorderSide(color: ac.divider),
              ),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: ac.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && procedimiento.id != null) {
      try {
        await widget.repository.eliminarProcedimiento(procedimiento.id!);
        _loadCatalog();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: ac.bgPage,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val.trim();
                      _applyFilter();
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar procedimiento...',
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: ac.textMuted,
                      ),
                      hintStyle: TextStyle(fontSize: 13, color: ac.textMuted),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: ac.cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ac.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ac.divider, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ac.primaryGreen),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SoloSiPuede.editarCatalogos(
                  child: FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Nuevo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProcedimientos.isEmpty
                  ? Center(
                      child: Text(
                        'No hay procedimientos registrados',
                        style: TextStyle(fontSize: 14, color: ac.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredProcedimientos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final proc = _filteredProcedimientos[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ac.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: ac.divider, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: ac.primaryGreen.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.healing_outlined,
                                  size: 18,
                                  color: ac.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  proc.nombre,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ac.textPrimary,
                                  ),
                                ),
                              ),
                              SoloSiPuede.editarCatalogos(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: ac.textMuted,
                                      ),
                                      onPressed: () =>
                                          _openForm(procedimiento: proc),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: ac.red.withValues(alpha: 0.7),
                                      ),
                                      onPressed: () =>
                                          _deleteProcedimiento(proc),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
