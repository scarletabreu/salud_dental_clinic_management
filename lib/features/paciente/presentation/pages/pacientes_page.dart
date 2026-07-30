import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_detail_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/paciente_avatar.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/record/domain/enums/tipo_sangre.dart';

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
      if (mounted) context.read<PacienteCubit>().search(_searchController.text);
    });
  }

  Future<void> _openNuevoPaciente() async {
    final cubit = context.read<PacienteCubit>();

    final nuevoPaciente = Paciente(
      nombre: '',
      apellido: '',
      birthDate: DateTime.now(),
      govID: '',
      contactos: const [],
      estatus: EstatusPersona.activo,
      genero: Genero.masculino,
      record: Record(
        pacienteId: '',
        tipoSangre: TipoSangre.oPositivo,
        condiciones: const [],
        cirugiasPrevias: const [],
        historialFamiliar: '',
        cantHijos: 0,
      ),
      trabajo: '',
      referencia: '',
      citas: const [],
      tipoPaciente: TipoPaciente.emergencia,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PacienteFormPage(paciente: nuevoPaciente),
        ),
      ),
    );
    if (mounted) cubit.load();
  }

  Future<void> _openForm(Paciente paciente) async {
    final cubit = context.read<PacienteCubit>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PacienteFormPage(paciente: paciente),
        ),
      ),
    );
    if (mounted) cubit.load();
  }

  Future<void> _openDetalle(Paciente paciente) async {
    final pacienteId = paciente.id;
    if (pacienteId == null || pacienteId.isEmpty) return;

    final cubit = context.read<PacienteCubit>();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PacienteDetailPage(pacienteId: pacienteId),
        ),
      ),
    );

    if (context.mounted) {
      cubit.load();
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
            _buildHeaderAndSearch(context, state),
            Expanded(child: _buildBody(context, state)),
          ],
        ),
      ),
    );
  }

  Widget _botonNuevoPaciente(BuildContext context) {
    final ac = context.appColors;

    return FilledButton.icon(
      onPressed: _openNuevoPaciente,
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
      label: const Text('Nuevo Paciente'),
      style: FilledButton.styleFrom(
        backgroundColor: ac.primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildHeaderAndSearch(BuildContext context, PacienteState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    final authState = context.watch<AuthCubit>().state;
    final puedeCrear = authState.puedeGestionarAgendaCompleta;
    // A 320 px el botón no cabe al lado del título: se baja a una fila propia
    // en vez de desbordar la cabecera.
    final accionEnLineaAparte = context.isCompactLayout;

    return Padding(
      padding: context.pageInsets(top: 28, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 14,
                      runSpacing: 4,
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
                        if (state is PacienteLoaded)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ac.primaryGreen.withValues(alpha: 0.07),
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
                                        color: ac.primaryGreen,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.people_alt_rounded,
                                  color: ac.primaryGreen,
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Listado completo de pacientes registrados en el sistema.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (puedeCrear && !accionEnLineaAparte) ...[
                const SizedBox(width: 12),
                _botonNuevoPaciente(context),
              ],
            ],
          ),
          if (puedeCrear && accionEnLineaAparte) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _botonNuevoPaciente(context),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (_) => _onSearch(),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o cédula...',
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
                        context.read<PacienteCubit>().search('');
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
      final compact = MediaQuery.sizeOf(context).width < 600;

      final authState = context.watch<AuthCubit>().state;
      final verContacto = authState.puedeVerDatosDeContactoPaciente;

      return Column(
        children: [
          if (!compact) _buildTableHeader(context, verContacto: verContacto),
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
                padding: context.pageInsets(top: 4, bottom: 24),
                itemCount: state.filtrados.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _PacienteRow(
                  paciente: state.filtrados[i],
                  onEdit: () => _openForm(state.filtrados[i]),
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

  Widget _buildTableHeader(BuildContext context, {required bool verContacto}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 8, 48, 12),
      child: Row(
        children: [
          const Expanded(flex: 3, child: _HeaderLabel(text: 'NOMBRE COMPLETO')),
          if (verContacto) ...[
            const Expanded(flex: 2, child: _HeaderLabel(text: 'CÉDULA')),
            const Expanded(flex: 2, child: _HeaderLabel(text: 'TELÉFONO')),
          ],
          const Expanded(flex: 1, child: _HeaderLabel(text: 'EDAD')),
          const SizedBox(width: 108),
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
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 10,
      ),
    );
  }
}

Widget _buildFooter(BuildContext context, PacienteLoaded state) {
  final ac = context.appColors;
  final shown = state.filtrados.length;
  final total = state.todos.length;

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
          Flexible(
            child: Text(
              shown == total
                  ? '$total paciente${total == 1 ? '' : 's'} en total'
                  : '$shown de $total paciente${total == 1 ? '' : 's'}',
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

  dynamic get _contacto => widget.paciente.contactos.firstOrNull;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final p = widget.paciente;
    final ac = context.appColors;

    // Por capacidad, no por rol: el administrador ejerce clínica, así que ve
    // el expediente, y además gestiona la ficha administrativa del paciente.
    final authState = context.watch<AuthCubit>().state;
    final puedeVerExpediente = authState.puedeVerExpedientes;
    final puedeGestionar = authState.puedeGestionarAgendaCompleta;
    final puedeVerContacto = authState.puedeVerDatosDeContactoPaciente;

    final fondoTarjeta = _expanded
        ? ac.primaryGreen.withValues(alpha: 0.04)
        : ac.cardBg;
    final colorBorde = _expanded
        ? ac.primaryGreen.withValues(alpha: 0.25)
        : colorScheme.outlineVariant.withValues(alpha: 0.4);

    final compact = MediaQuery.sizeOf(context).width < 600;
    final permiteExpandir = puedeVerContacto;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: fondoTarjeta,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: _expanded ? 0.03 : 0.01,
            ),
            blurRadius: _expanded ? 10 : 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: permiteExpandir
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(14),
            hoverColor: ac.primaryGreen.withValues(alpha: 0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: compact
                  ? _buildCompactRow(
                      context,
                      p,
                      ac,
                      puedeVerExpediente: puedeVerExpediente,
                      puedeGestionar: puedeGestionar,
                      puedeVerContacto: puedeVerContacto,
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Row(
                            children: [
                              PacienteAvatar(
                                paciente: p,
                                size: 36,
                                backgroundColor: ac.primaryGreen,
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
                        if (puedeVerContacto) ...[
                          Expanded(
                            flex: 2,
                            child: Text(
                              p.govID,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _contacto?.numeroTelefono.isNotEmpty == true
                                  ? _contacto!.numeroTelefono
                                  : '—',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.8),
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ],
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${p.age} años',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        SizedBox(
                          width: 108,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (puedeVerExpediente)
                                _ActionIcon(
                                  icon: Icons.visibility_outlined,
                                  tooltip: 'Ver expediente',
                                  color: ac.primaryGreen,
                                  onTap: widget.onVerDetalle,
                                ),
                              if (puedeGestionar) ...[
                                const SizedBox(width: 6),
                                _ActionIcon(
                                  icon: Icons.edit_outlined,
                                  tooltip: 'Editar',
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                  onTap: widget.onEdit,
                                ),
                                const SizedBox(width: 6),
                                _ActionIcon(
                                  icon: Icons.delete_outline_rounded,
                                  tooltip: 'Eliminar',
                                  color: colorScheme.error.withValues(
                                    alpha: 0.7,
                                  ),
                                  onTap: () => _showDeleteConfirmation(
                                    context,
                                    widget.paciente,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_expanded && puedeVerContacto) _buildDetail(context, p),
        ],
      ),
    );
  }

  Widget _buildCompactRow(
    BuildContext context,
    Paciente p,
    AppColors ac, {
    required bool puedeVerExpediente,
    required bool puedeGestionar,
    required bool puedeVerContacto,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PacienteAvatar(
              paciente: p,
              size: 36,
              backgroundColor: ac.primaryGreen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                p.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (puedeVerExpediente)
              _ActionIcon(
                icon: Icons.visibility_outlined,
                tooltip: 'Ver expediente',
                color: ac.primaryGreen,
                onTap: widget.onVerDetalle,
              ),
            if (puedeGestionar)
              _ActionIcon(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                onTap: widget.onEdit,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            if (puedeVerContacto) ...[
              _compactField('Cédula', p.govID),
              _compactField(
                'Teléfono',
                _contacto?.numeroTelefono.isNotEmpty == true
                    ? _contacto!.numeroTelefono
                    : '—',
              ),
            ],
            _compactField('Edad', '${p.age} años'),
          ],
        ),
      ],
    );
  }

  Widget _compactField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: .5,
        ),
      ),
      Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _buildDetail(BuildContext context, Paciente p) {
    final colorScheme = Theme.of(context).colorScheme;
    final telefono = _contacto?.numeroTelefono ?? '';
    final email = _contacto?.email ?? '';
    final direccion = _contacto?.direccion ?? '';

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.cardBg.withValues(alpha: 0.2),
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
            color: colorScheme.outlineVariant.withValues(alpha: 0.25),
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
                label: 'Teléfono',
                value: telefono.isEmpty ? '—' : telefono,
              ),
              _DetailItem(label: 'Email', value: email.isEmpty ? '—' : email),
              _DetailItem(
                label: 'Dirección Residencia',
                value: direccion.isEmpty ? '—' : direccion,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _generoLabel(String name) => switch (name) {
    'masculino' => 'Masculino',
    'femenino' => 'Femenino',
    'otro' => 'Otro',
    'noPrefiereDecir' => 'No prefiere decir',
    _ => name,
  };

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _showDeleteConfirmation(BuildContext context, Paciente paciente) {
    final colorScheme = Theme.of(context).colorScheme;
    final pacienteId = paciente.id;
    if (pacienteId == null || pacienteId.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Paciente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Está seguro de que deseas eliminar a ${paciente.fullName}?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción eliminará el registro del paciente de forma lógica.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                      ),
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
              context.read<PacienteCubit>().deletePaciente(pacienteId);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Eliminar'),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
          ),
        ],
      ),
    );
  }
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
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
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
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

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
