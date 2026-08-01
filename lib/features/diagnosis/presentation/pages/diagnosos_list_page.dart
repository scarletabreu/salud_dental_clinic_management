import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/categoria_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/enums/severidad_diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/presentation/pages/diagnosis_form_page.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/widgets/solo_si_puede.dart';

class DiagnosisListPage extends StatefulWidget {
  final DiagnosisRepository repository;

  const DiagnosisListPage({super.key, required this.repository});

  @override
  State<DiagnosisListPage> createState() => _DiagnosisListPageState();
}

class _DiagnosisListPageState extends State<DiagnosisListPage> {
  List<Diagnosis> _allDiagnosis = [];
  List<Diagnosis> _filteredDiagnosis = [];
  bool _isLoading = true;
  String _searchQuery = '';
  CategoriaDiagnosis? _selectedCategoria;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.repository.getCatalogoCompleto();
      if (!mounted) return;
      setState(() {
        _allDiagnosis = list;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar diagnósticos: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredDiagnosis = _allDiagnosis.where((d) {
        final matchesQuery =
            _searchQuery.isEmpty ||
            d.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());

        final matchesCategoria =
            _selectedCategoria == null || d.categoria == _selectedCategoria;

        return matchesQuery && matchesCategoria;
      }).toList();
    });
  }

  Future<void> _openForm({Diagnosis? diagnosis}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DiagnosisFormPage(
          repository: widget.repository,
          diagnosis: diagnosis,
        ),
      ),
    );

    if (result == true) {
      _loadCatalog();
    }
  }

  Future<void> _deleteDiagnosis(Diagnosis diagnosis) async {
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
            'Eliminar diagnóstico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ac.textPrimary,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar "${diagnosis.nombre}" del catálogo?',
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

    if (confirmed == true && diagnosis.id != null) {
      try {
        await widget.repository.eliminarDiagnosisDelCatalogo(diagnosis.id!);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) {
                      _searchQuery = val.trim();
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar diagnóstico...',
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
            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _selectedCategoria == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategoria = null;
                          _applyFilters();
                        });
                      }
                    },
                    selectedColor: ac.primaryGreen.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: _selectedCategoria == null
                          ? ac.primaryGreen
                          : ac.textSecondary,
                      fontWeight: _selectedCategoria == null
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ...CategoriaDiagnosis.values.map((cat) {
                    final isSelected = _selectedCategoria == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat.nombre),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoria = selected ? cat : null;
                            _applyFilters();
                          });
                        },
                        selectedColor: ac.primaryGreen.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? ac.primaryGreen
                              : ac.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredDiagnosis.isEmpty
                  ? _buildEmptyState(ac)
                  : ListView.separated(
                      itemCount: _filteredDiagnosis.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final diag = _filteredDiagnosis[index];
                        return _buildDiagnosisCard(ac, diag);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors ac) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 42,
            color: ac.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No se encontraron diagnósticos',
            style: TextStyle(
              fontSize: 14,
              color: ac.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(AppColors ac, Diagnosis diagnosis) {
    Color severidadColor;
    switch (diagnosis.severidadDefault) {
      case SeveridadDiagnosis.leve:
        severidadColor = ac.primaryGreen;
        break;
      case SeveridadDiagnosis.moderada:
        severidadColor = const Color(0xFFD97706);
        break;
      case SeveridadDiagnosis.grave:
        severidadColor = ac.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.divider, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ac.primaryGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 18,
              color: ac.primaryGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        diagnosis.nombre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ac.textPrimary,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: ac.bgPage,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ac.divider),
                      ),
                      child: Text(
                        diagnosis.categoria.nombre,
                        style: TextStyle(fontSize: 10, color: ac.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: severidadColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        diagnosis.severidadDefault.etiqueta,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: severidadColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  diagnosis.descripcion,
                  style: TextStyle(fontSize: 12, color: ac.textSecondary),
                ),
                if (diagnosis.claveOdontograma != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.style_outlined, size: 12, color: ac.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Odontograma: ${diagnosis.claveOdontograma}',
                        style: TextStyle(fontSize: 11, color: ac.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SoloSiPuede.editarCatalogos(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: ac.textMuted),
                  onPressed: () => _openForm(diagnosis: diagnosis),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: ac.red.withValues(alpha: 0.7),
                  ),
                  onPressed: () => _deleteDiagnosis(diagnosis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
