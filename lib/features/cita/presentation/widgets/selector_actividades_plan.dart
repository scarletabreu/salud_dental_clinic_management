import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/actividad_planificada.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';

/// Elige qué actividades del plan de tratamiento va a atender la cita (SD-146).
///
/// Sustituye el hábito de escribir el plan a mano en el motivo: se marcan las
/// actividades ya propuestas y la cita guarda la referencia, no una copia.
class SelectorActividadesPlan extends StatefulWidget {
  const SelectorActividadesPlan({
    super.key,
    required this.pacienteId,
    required this.repository,
    required this.seleccionadas,
    required this.onChanged,
    this.habilitado = true,
  });

  /// Paciente de la cita. `null` cuando todavía no existe en la base (un
  /// paciente que se está registrando en este mismo formulario): sin id no hay
  /// plan que consultar.
  final String? pacienteId;

  final CitaRepository repository;
  final List<ActividadPlanificada> seleccionadas;
  final ValueChanged<List<ActividadPlanificada>> onChanged;
  final bool habilitado;

  @override
  State<SelectorActividadesPlan> createState() =>
      _SelectorActividadesPlanState();
}

class _SelectorActividadesPlanState extends State<SelectorActividadesPlan> {
  List<ActividadPlanificada>? _disponibles;
  String? _error;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant SelectorActividadesPlan anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.pacienteId != widget.pacienteId) _cargar();
  }

  Future<void> _cargar() async {
    final pacienteId = widget.pacienteId;
    if (pacienteId == null) {
      setState(() {
        _disponibles = const [];
        _error = null;
        _cargando = false;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await widget.repository.getActividadesAgendables(
        pacienteId,
      );
      if (!mounted) return;
      setState(() {
        _disponibles = lista;
        _cargando = false;
      });
      // Una actividad que ya no se puede agendar (se rechazó o se completó
      // entre medio) deja de estar seleccionada: guardarla la rechazaría el
      // trigger de la base.
      final vivas = {for (final a in lista) a.itemPlanId};
      final conservadas = widget.seleccionadas
          .where((a) => vivas.contains(a.itemPlanId))
          .toList();
      if (conservadas.length != widget.seleccionadas.length) {
        widget.onChanged(conservadas);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  void _alternar(ActividadPlanificada actividad, bool marcada) {
    final actuales = [...widget.seleccionadas];
    actuales.removeWhere((a) => a.itemPlanId == actividad.itemPlanId);
    if (marcada) actuales.add(actividad);
    widget.onChanged(actuales);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    if (_cargando) {
      return _Marco(
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            // Acotado: en 320 px el texto suelto desbordaba la fila.
            Expanded(
              child: Text(
                'Buscando actividades del plan...',
                style: TextStyle(fontSize: 12, color: ac.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _Marco(
        borde: ac.red,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 15, color: ac.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No se pudo cargar el plan de tratamiento.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ac.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              style: TextStyle(fontSize: 11, color: ac.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: ac.primaryGreen,
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final disponibles = _disponibles ?? const <ActividadPlanificada>[];
    if (disponibles.isEmpty) {
      return _Marco(
        child: Row(
          children: [
            Icon(Icons.assignment_outlined, size: 15, color: ac.textDisabled),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.pacienteId == null
                    ? 'El plan se vincula después: este paciente aún no existe '
                          'en el sistema.'
                    : 'Este paciente no tiene actividades pendientes en su '
                          'plan de tratamiento.',
                style: TextStyle(fontSize: 12, color: ac.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    final marcadas = {for (final a in widget.seleccionadas) a.itemPlanId};

    return _Marco(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final actividad in disponibles)
            CheckboxListTile(
              value: marcadas.contains(actividad.itemPlanId),
              onChanged: widget.habilitado
                  ? (valor) => _alternar(actividad, valor ?? false)
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: ac.primaryGreen,
              title: Text(
                actividad.descripcion,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ac.textPrimary,
                ),
              ),
              subtitle: Text(
                actividad.estado.etiqueta,
                style: TextStyle(fontSize: 11, color: ac.textMuted),
              ),
            ),
          const SizedBox(height: 2),
          Text(
            marcadas.isEmpty
                ? 'Sin actividades seleccionadas. La cita se agenda igual.'
                : '${marcadas.length} actividad(es) seleccionada(s).',
            style: TextStyle(fontSize: 11, color: ac.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Marco extends StatelessWidget {
  const _Marco({required this.child, this.borde});

  final Widget child;
  final Color? borde;

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    // El fondo lo pone el Material y no un Container: pintarlo por encima tapa
    // el destello del toque de las casillas —Flutter lo afirma en depuración— y
    // dejaría la fila sin decir que se pulsó.
    return Material(
      color: ac.bgPage,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borde ?? ac.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
