import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/cubit/condiciones_paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/cubit/condiciones_paciente_state.dart';

/// Tarjeta de gestión de condiciones médicas del paciente en su expediente.
/// Lista las condiciones (puente `record_condicion`), permite agregar desde el
/// catálogo o crear una nueva, y quitar. Solo opera sobre pacientes ya
/// persistidos (id uuid); para pacientes de prueba muestra un aviso.
class CondicionesMedicasCard extends StatelessWidget {
  final String pacienteId;

  const CondicionesMedicasCard({super.key, required this.pacienteId});

  static bool _esUuid(String id) => id.length == 36 && id.contains('-');

  @override
  Widget build(BuildContext context) {
    if (!_esUuid(pacienteId)) {
      return const _CardShell(child: _AvisoPacientePrueba());
    }

    return BlocProvider<CondicionesPacienteCubit>(
      create: (_) => sl<CondicionesPacienteCubit>(param1: pacienteId)..cargar(),
      child: const _CondicionesView(),
    );
  }
}

class _CondicionesView extends StatelessWidget {
  const _CondicionesView();

  Future<void> _onAgregar(BuildContext context) async {
    final cubit = context.read<CondicionesPacienteCubit>();
    final state = cubit.state;
    final yaAsignadas = state is CondicionesPacienteLoaded
        ? state.condiciones.map((c) => c.id).whereType<String>().toSet()
        : <String>{};

    final resultado = await showDialog<_AgregarResult>(
      context: context,
      builder: (_) => _AgregarCondicionDialog(
        catalogo: cubit.catalogo,
        yaAsignadas: yaAsignadas,
      ),
    );

    if (resultado == null) return;
    if (resultado.existenteId != null) {
      await cubit.agregarExistente(resultado.existenteId!);
    } else if (resultado.nueva != null) {
      await cubit.crearYAgregar(resultado.nueva!);
    }
  }

  Future<void> _onQuitar(BuildContext context, Condicion c) async {
    final ac = context.appColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitar condición'),
        content: Text(
          '¿Quitar "${c.nombre}" de las condiciones del paciente?',
          style: TextStyle(color: ac.textSecondary, fontSize: 13, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ac.red),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (ok == true && c.id != null && context.mounted) {
      await context.read<CondicionesPacienteCubit>().quitar(c.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocBuilder<CondicionesPacienteCubit, CondicionesPacienteState>(
      builder: (context, state) {
        final procesando =
            state is CondicionesPacienteLoaded && state.procesando;

        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Header(),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: procesando ? null : () => _onAgregar(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(
                      foregroundColor: ac.primaryBlue,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state is CondicionesPacienteLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: ac.primaryBlue,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (state is CondicionesPacienteError)
                Text(
                  state.message,
                  style: TextStyle(fontSize: 13, color: ac.red),
                )
              else if (state is CondicionesPacienteLoaded)
                state.condiciones.isEmpty
                    ? Text(
                        'Sin condiciones registradas',
                        style: TextStyle(
                          fontSize: 13,
                          color: ac.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Column(
                        children: [
                          for (final c in state.condiciones)
                            _CondicionRow(
                              condicion: c,
                              deshabilitado: procesando,
                              onQuitar: () => _onQuitar(context, c),
                            ),
                        ],
                      ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ac.red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.health_and_safety_outlined,
            size: 18,
            color: ac.red,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Condiciones Médicas',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ac.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CondicionRow extends StatelessWidget {
  final Condicion condicion;
  final bool deshabilitado;
  final VoidCallback onQuitar;

  const _CondicionRow({
    required this.condicion,
    required this.deshabilitado,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ac.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ac.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.circle, size: 8, color: _colorTipo(ac, condicion.tipo)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                condicion.nombre,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ac.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _TipoPill(condicion.tipo),
            const SizedBox(width: 4),
            IconButton(
              onPressed: deshabilitado ? null : onQuitar,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: ac.textMuted,
              splashRadius: 18,
              tooltip: 'Quitar',
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _TipoPill extends StatelessWidget {
  final TipoCondicion tipo;

  const _TipoPill(this.tipo);

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final color = _colorTipo(ac, tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        tipo.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

Color _colorTipo(AppColors ac, TipoCondicion tipo) {
  switch (tipo) {
    case TipoCondicion.alergica:
      return ac.red;
    case TipoCondicion.patologica:
      return ac.amber;
    case TipoCondicion.fisiologica:
      return ac.teal;
    case TipoCondicion.quirurgica:
      return ac.indigo;
    case TipoCondicion.genetica:
      return ac.primaryBlue;
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [ac.cardShadow],
        ),
        child: child,
      ),
    );
  }
}

class _AvisoPacientePrueba extends StatelessWidget {
  const _AvisoPacientePrueba();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(),
        const SizedBox(height: 12),
        Text(
          'Las condiciones médicas se gestionan sobre pacientes guardados.',
          style: TextStyle(
            fontSize: 13,
            color: ac.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Diálogo de agregar / crear ────────────────────────────────────────────

class _AgregarResult {
  final String? existenteId;
  final Condicion? nueva;

  const _AgregarResult.existente(String id) : existenteId = id, nueva = null;

  const _AgregarResult.crear(Condicion condicion)
    : existenteId = null,
      nueva = condicion;
}

class _AgregarCondicionDialog extends StatefulWidget {
  final Future<List<Condicion>> Function() catalogo;
  final Set<String> yaAsignadas;

  const _AgregarCondicionDialog({
    required this.catalogo,
    required this.yaAsignadas,
  });

  @override
  State<_AgregarCondicionDialog> createState() =>
      _AgregarCondicionDialogState();
}

class _AgregarCondicionDialogState extends State<_AgregarCondicionDialog> {
  final _busquedaController = TextEditingController();
  late Future<List<Condicion>> _catalogoFuture;

  bool _modoCrear = false;
  TipoCondicion _tipo = TipoCondicion.patologica;
  CategoriaCondicion _categoria = CategoriaCondicion.cronica;

  @override
  void initState() {
    super.initState();
    _catalogoFuture = widget.catalogo();
    _busquedaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _crear() {
    final nombre = _busquedaController.text.trim();
    if (nombre.isEmpty) return;
    Navigator.of(context).pop(
      _AgregarResult.crear(
        Condicion(nombre: nombre, tipo: _tipo, categoria: _categoria),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final query = _busquedaController.text.trim().toLowerCase();

    // The catalogue list has to give way when the keyboard takes the screen.
    final alturaCatalogo =
        ((MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom) *
                0.32)
            .clamp(130.0, 220.0);

    return AppDialog(
      preferredWidth: 380,
      title: Text(_modoCrear ? 'Nueva condición' : 'Agregar condición'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _busquedaController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: _modoCrear
                  ? 'Nombre de la condición'
                  : 'Buscar en el catálogo…',
              prefixIcon: Icon(
                _modoCrear ? Icons.edit_outlined : Icons.search_rounded,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          if (_modoCrear)
            _FormularioCrear(
              tipo: _tipo,
              categoria: _categoria,
              onTipo: (t) => setState(() => _tipo = t),
              onCategoria: (c) => setState(() => _categoria = c),
            )
          else
            SizedBox(
              height: alturaCatalogo,
              child: FutureBuilder<List<Condicion>>(
                future: _catalogoFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: ac.primaryBlue,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'No se pudo cargar el catálogo',
                        style: TextStyle(fontSize: 13, color: ac.red),
                      ),
                    );
                  }
                  final items = (snapshot.data ?? [])
                      .where((c) => !widget.yaAsignadas.contains(c.id))
                      .where(
                        (c) =>
                            query.isEmpty ||
                            c.nombre.toLowerCase().contains(query),
                      )
                      .toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        query.isEmpty
                            ? 'No hay condiciones en el catálogo'
                            : 'Ningún resultado. Usa "Crear nueva".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: ac.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final c = items[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.circle,
                          size: 8,
                          color: _colorTipo(ac, c.tipo),
                        ),
                        title: Text(
                          c.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: _TipoPill(c.tipo),
                        onTap: () => Navigator.of(
                          context,
                        ).pop(_AgregarResult.existente(c.id!)),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _modoCrear = !_modoCrear),
          child: Text(_modoCrear ? 'Volver al catálogo' : 'Crear nueva'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        if (_modoCrear)
          FilledButton(
            onPressed: _busquedaController.text.trim().isEmpty ? null : _crear,
            style: FilledButton.styleFrom(backgroundColor: ac.primaryBlue),
            child: const Text('Crear y agregar'),
          ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    );
  }
}

class _FormularioCrear extends StatelessWidget {
  final TipoCondicion tipo;
  final CategoriaCondicion categoria;
  final ValueChanged<TipoCondicion> onTipo;
  final ValueChanged<CategoriaCondicion> onCategoria;

  const _FormularioCrear({
    required this.tipo,
    required this.categoria,
    required this.onTipo,
    required this.onCategoria,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: ac.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<TipoCondicion>(
          initialValue: tipo,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          items: [
            for (final t in TipoCondicion.values)
              DropdownMenuItem(value: t, child: Text(t.displayName)),
          ],
          onChanged: (v) => v == null ? null : onTipo(v),
        ),
        const SizedBox(height: 12),
        Text(
          'CATEGORÍA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: ac.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<CategoriaCondicion>(
          initialValue: categoria,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          items: [
            for (final c in CategoriaCondicion.values)
              DropdownMenuItem(value: c, child: Text(c.displayName)),
          ],
          onChanged: (v) => v == null ? null : onCategoria(v),
        ),
      ],
    );
  }
}
