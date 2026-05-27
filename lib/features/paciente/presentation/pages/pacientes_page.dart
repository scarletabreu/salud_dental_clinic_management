import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';

class PacientesPage extends StatefulWidget {
  const PacientesPage({super.key});

  @override
  State<PacientesPage> createState() => _PacientesPageState();
}

class _PacientesPageState extends State<PacientesPage> {
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
        context.read<PacienteCubit>().search(_searchController.text);
      }
    });
  }

Future<void> _openForm({Paciente? paciente}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: context.read<PacienteCubit>(),
        child: PacienteFormPage(paciente: paciente),
      ),
    ),
  );

  if (mounted) {
    context.read<PacienteCubit>().load();
  }
}

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surfaceContainerLowest,
      child: BlocBuilder<PacienteCubit, PacienteState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            if (state is PacienteLoaded) _buildStatsBar(context, state),
            Expanded(child: _buildBody(context, state)),
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
                  'Pacientes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Listado completo de pacientes registrados en el sistema.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuevo Paciente'),
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
        onChanged: (_) => _onSearch(),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o cédula...',
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
                  onPressed: () {
                    _searchController.clear();
                    context.read<PacienteCubit>().search('');
                  },
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

  Widget _buildStatsBar(BuildContext context, PacienteLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Text(
            'TOTAL DE PACIENTES',
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
                  '${state.todos.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.people_alt_rounded,
                    color: colorScheme.primary, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, PacienteState state) {
    if (state is PacienteLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is PacienteError) {
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
              state.message,
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.read<PacienteCubit>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is PacienteLoaded) {
      return Column(
        children: [
          _buildTableHeader(context),
          if (state.filtrados.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_alt_outlined,
                      size: 56,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withAlpha(100),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _searchController.text.isEmpty
                          ? 'No hay pacientes registrados.\nPresiona "Nuevo Paciente" para comenzar.'
                          : 'Sin resultados para "${_searchController.text}".',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: state.filtrados.length,
                separatorBuilder: (context2, index2) =>
                    const SizedBox(height: 4),
                itemBuilder: (_, i) => _PacienteRow(
                  paciente: state.filtrados[i],
                  onEdit: () => _openForm(paciente: state.filtrados[i]),
                ),
              ),
            ),
            _buildFooter(context, state),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildTableHeader(BuildContext context) {
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
          Expanded(flex: 3, child: _headerLabel(context, 'NOMBRE COMPLETO')),
          Expanded(flex: 2, child: _headerLabel(context, 'CÉDULA')),
          Expanded(flex: 2, child: _headerLabel(context, 'TELÉFONO')),
          Expanded(flex: 1, child: _headerLabel(context, 'EDAD')),
          const SizedBox(width: 64),
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

  Widget _buildFooter(BuildContext context, PacienteLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final shown = state.filtrados.length;
    final total = state.todos.length;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        'Mostrando $shown de $total paciente${total == 1 ? '' : 's'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PacienteRow extends StatefulWidget {
  final Paciente paciente;
  final VoidCallback onEdit;

  const _PacienteRow({required this.paciente, required this.onEdit});

  @override
  State<_PacienteRow> createState() => _PacienteRowState();
}

class _PacienteRowState extends State<_PacienteRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = widget.paciente;

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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.fullName,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.govID,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.contacto.numeroTelefono.isEmpty
                          ? '—'
                          : p.contacto.numeroTelefono,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${p.age}',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionIcon(
                          icon: _expanded
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          tooltip: _expanded ? 'Ocultar' : 'Ver detalle',
                          color: colorScheme.primary,
                          onTap: () =>
                              setState(() => _expanded = !_expanded),
                        ),
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          tooltip: 'Editar',
                          color: colorScheme.onSurfaceVariant,
                          onTap: widget.onEdit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) _buildDetail(context, p),
        ],
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Paciente p) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outlineVariant, height: 20),
          Wrap(
            spacing: 32,
            runSpacing: 12,
            children: [
              _DetailItem(
                label: 'Género',
                value: _generoLabel(p.genero.name),
              ),
              _DetailItem(
                label: 'Tipo',
                value: _capitalize(p.tipoPaciente.name),
              ),
              _DetailItem(
                label: 'Trabajo',
                value: p.trabajo.isEmpty ? '—' : p.trabajo,
              ),
              _DetailItem(
                label: 'Referencia',
                value: p.referencia.isEmpty ? '—' : p.referencia,
              ),
              _DetailItem(
                label: 'Email',
                value: p.contacto.email.isEmpty ? '—' : p.contacto.email,
              ),
              _DetailItem(
                label: 'Dirección',
                value: p.contacto.direccion.isEmpty
                    ? '—'
                    : p.contacto.direccion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _generoLabel(String name) {
    switch (name) {
      case 'masculino':
        return 'Masculino';
      case 'femenino':
        return 'Femenino';
      case 'otro':
        return 'Otro';
      case 'noPrefiereDecir':
        return 'No prefiere decir';
      default:
        return name;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
