import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_detail_page.dart';
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
      MaterialPageRoute(builder: (_) => PacienteFormPage(paciente: paciente)),
    );
    if (mounted) context.read<PacienteCubit>().load();
  }

  Future<void> _openDetalle(Paciente paciente) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<PacienteCubit>(),
          child: PacienteDetailPage(pacienteId: paciente.id!),
        ),
      ),
    );
    if (mounted) context.read<PacienteCubit>().load();
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
            _buildHeaderAndSearch(context, state),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch(BuildContext context, PacienteState state) {
    final colorScheme = Theme.of(context).colorScheme;
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
                      'Pacientes',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.6,
                          ),
                    ),
                    if (state is PacienteLoaded) ...[
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3385FF).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${state.todos.length}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3385FF),
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.people_alt_rounded,
                              color: const Color(0xFF3385FF),
                              size: 13,
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
                  'Nuevo Paciente',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3385FF),
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
            'Listado completo de pacientes registrados en el sistema.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _searchController,
            onChanged: (_) => _onSearch(),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o cédula...',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.45),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
                        context.read<PacienteCubit>().search('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFEEF2F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF0066FF),
                  width: 1.2,
                ),
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
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => context.read<PacienteCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(100),
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
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                itemCount: state.filtrados.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PacienteRow(
                  paciente: state.filtrados[i],
                  onEdit: () => _openForm(paciente: state.filtrados[i]),
                  onVerDetalle: () => _openDetalle(state.filtrados[i]),
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
    return const Padding(
      padding: EdgeInsets.fromLTRB(48, 8, 48, 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: _HeaderLabel(text: 'NOMBRE COMPLETO')),
          Expanded(flex: 2, child: _HeaderLabel(text: 'CÉDULA')),
          Expanded(flex: 2, child: _HeaderLabel(text: 'TELÉFONO')),
          Expanded(flex: 1, child: _HeaderLabel(text: 'EDAD')),
          SizedBox(width: 72),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  final String text;
  const _HeaderLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.65),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 10,
      ),
    );
  }
}

Widget _buildFooter(BuildContext context, PacienteLoaded state) {
  final colorScheme = Theme.of(context).colorScheme;
  final shown = state.filtrados.length;
  final total = state.todos.length;
  return Container(
    color: colorScheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mostrando $shown de $total paciente${total == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _PacienteRow extends StatefulWidget {
  final Paciente paciente;
  final VoidCallback onEdit;
  final VoidCallback onVerDetalle;

  const _PacienteRow({
    required this.paciente,
    required this.onEdit,
    required this.onVerDetalle,
  });

  @override
  State<_PacienteRow> createState() => _PacienteRowState();
}

class _PacienteRowState extends State<_PacienteRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = widget.paciente;

    final Color fondoTarjeta = _expanded
        ? const Color(0xFF3385FF).withOpacity(0.04)
        : colorScheme.surface;

    final Color colorBorde = _expanded
        ? const Color(0xFF3385FF).withOpacity(0.25)
        : colorScheme.outlineVariant.withOpacity(0.4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(_expanded ? 0.03 : 0.01),
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
            hoverColor: const Color(0xFF3385FF).withOpacity(0.02),
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
                            color: colorScheme.onSurface.withOpacity(0.04),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            p.fullName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                  fontSize: 15,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.govID,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.contactos.firstOrNull!.numeroTelefono.isEmpty //TODO
                          ? '—'
                          : p.contactos.firstOrNull!.numeroTelefono, //TODO
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${p.age} años',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Acciones Planas Estilizadas
                  SizedBox(
                    width: 72,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionIcon(
                          icon: Icons.visibility_outlined,
                          tooltip: 'Ver expediente',
                          color: const Color(0xFF3385FF).withOpacity(0.85),
                          onTap: widget.onVerDetalle,
                        ),
                        const SizedBox(width: 6),
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          tooltip: 'Editar',
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
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
        color: colorScheme.surface.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            color: colorScheme.outlineVariant.withOpacity(0.25),
            height: 1,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 40,
            runSpacing: 16,
            children: [
              _DetailItem(label: 'Género', value: _generoLabel(p.genero.name)),
              _DetailItem(
                label: 'Tipo de Paciente',
                value: _capitalize(p.tipoPaciente.name),
              ),
              _DetailItem(
                label: 'Ocupación',
                value: p.trabajo.isEmpty ? '—' : p.trabajo,
              ),
              _DetailItem(
                label: 'Referencia',
                value: p.referencia.isEmpty ? '—' : p.referencia,
              ),
              _DetailItem(
                label: 'Email',
                value: p.contactos.firstOrNull!.email.isEmpty ? '—' : p.contactos.firstOrNull!.email, //TODO
              ),
              _DetailItem(
                label: 'Dirección Residencia',
                value: p.contactos.firstOrNull!.direccion.isEmpty //TODO
                    ? '—'
                    : p.contactos.firstOrNull!.direccion, //TODO
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
            letterSpacing: 0.8,
            fontWeight: FontWeight.bold,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
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
