import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/delete_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/usecases/get_medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/presentation/pages/medicina_form_page.dart';

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
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = await _deleteMedicina(medicina.id);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicinas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar medicina...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _searchController.clear,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Agregar medicina',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'No hay medicinas registradas.\nPresiona + para agregar una.'
              : 'Sin resultados para "${_searchController.text}".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        final medicina = _filtered[index];
        return _MedicinaListTile(
          medicina: medicina,
          onEdit: () => _openForm(medicina: medicina),
          onDelete: () => _confirmDelete(medicina),
        );
      },
    );
  }
}

class _MedicinaListTile extends StatelessWidget {
  final Medicina medicina;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MedicinaListTile({
    required this.medicina,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            medicina.nombre[0].toUpperCase(),
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          medicina.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: _buildSubtitle(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context) {
    final efectos = medicina.efectosSecundarios.length;
    final contra = medicina.contraindicaciones.length;
    if (efectos == 0 && contra == 0) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (efectos > 0)
          Text('$efectos efecto${efectos == 1 ? '' : 's'} secundario${efectos == 1 ? '' : 's'}'),
        if (contra > 0)
          Text('$contra contraindicación${contra == 1 ? '' : 'es'}'),
      ],
    );
  }
}
