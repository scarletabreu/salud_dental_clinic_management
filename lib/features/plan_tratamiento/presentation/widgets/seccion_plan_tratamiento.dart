import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/core/util/moneda.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/dialogo_consentimiento_plan.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/estado_plan_estilos.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

/// Un hallazgo de la evaluación que todavía nadie decidió tratar.
class HallazgoSinPlanificar {
  final String? diagnosticoAplicadoId;
  final String? dienteId;
  final int fdiCode;
  final TipoSuperficie? superficie;
  final String nombre;

  const HallazgoSinPlanificar({
    this.diagnosticoAplicadoId,
    this.dienteId,
    required this.fdiCode,
    this.superficie,
    required this.nombre,
  });

  String get descripcion => superficie == null
      ? '$nombre · pieza $fdiCode'
      : '$nombre · $fdiCode ${superficie!.name}';
}

/// Sección del workspace de consulta donde el plan toma forma: a la vista quedan
/// los hallazgos que nadie decidió tratar y, debajo, las actividades ya
/// propuestas con su decisión.
///
/// Es la mitad de SD-135 que ocurre delante del paciente. Nada de lo que se hace
/// aquí genera un cargo: la pre-factura solo lee lo ejecutado.
class SeccionPlanTratamiento extends StatelessWidget {
  final List<Diente> dientes;
  final String pacienteId;
  final String doctorId;
  final String consultaId;
  final String? evaluacionId;

  /// Abre el selector del catálogo. Se inyecta para reutilizar el mismo sheet
  /// que ya usa el odontograma en vez de duplicarlo.
  final Future<Tratamiento?> Function() onElegirTratamiento;

  const SeccionPlanTratamiento({
    super.key,
    required this.dientes,
    required this.pacienteId,
    required this.doctorId,
    required this.consultaId,
    required this.onElegirTratamiento,
    this.evaluacionId,
  });

  /// Hallazgos de la evaluación que ninguna actividad del plan atiende todavía.
  ///
  /// Un hallazgo sin `id` es uno que aún no llegó a la base (la consulta guarda
  /// sola, así que dura poco). Se muestra igual, pero al llevarlo al plan la
  /// actividad queda sin el vínculo al hallazgo.
  List<HallazgoSinPlanificar> _sinPlanificar(PlanTratamiento? plan) {
    final atendidos = {
      for (final item in plan?.items ?? const <ItemPlanTratamiento>[])
        if (item.diagnosticoAplicadoId != null) item.diagnosticoAplicadoId!,
    };

    return [
      for (final diente in dientes)
        for (final hallazgo in diente.diagnosis)
          if (hallazgo.id == null || !atendidos.contains(hallazgo.id))
            HallazgoSinPlanificar(
              diagnosticoAplicadoId: hallazgo.id,
              dienteId: diente.id ?? hallazgo.dienteId,
              fdiCode: diente.fdiCode,
              superficie: hallazgo.superficie,
              nombre: hallazgo.nombreDiagnostico ?? 'Hallazgo',
            ),
    ];
  }

  Future<void> _llevarAlPlan(
    BuildContext context,
    HallazgoSinPlanificar hallazgo,
  ) async {
    final cubit = context.read<PlanTratamientoCubit>();
    final tratamiento = await onElegirTratamiento();
    if (tratamiento == null) return;

    await cubit.proponerActividades(
      pacienteId: pacienteId,
      doctorId: doctorId,
      consultaId: consultaId,
      evaluacionId: evaluacionId,
      actividades: [
        ItemPlanTratamiento(
          planId: '',
          tratamientoId: tratamiento.id ?? '',
          diagnosticoAplicadoId: hallazgo.diagnosticoAplicadoId,
          dienteId: hallazgo.dienteId,
          // El catálogo manda sobre la cara, igual que al aplicar: una corona
          // es de la pieza entera aunque el hallazgo fuera de una cara.
          superficie: tratamiento.alcance == Alcance.puntual
              ? hallazgo.superficie
              : null,
          precioEstimado: tratamiento.costo,
          notas: 'Por ${hallazgo.descripcion}',
          doctorProponeId: doctorId,
          fechaPropuesta: DateTime.now(),
          nombreTratamiento: tratamiento.nombre,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocConsumer<PlanTratamientoCubit, PlanTratamientoState>(
      listenWhen: (previo, actual) =>
          actual is PlanTratamientoCargado && actual.aviso != null,
      listener: (context, state) {
        final aviso = (state as PlanTratamientoCargado).aviso!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(aviso),
            backgroundColor: ac.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        context.read<PlanTratamientoCubit>().limpiarAviso();
      },
      builder: (context, state) {
        if (state is PlanTratamientoCargando ||
            state is PlanTratamientoInitial) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ac.primaryGreen,
                ),
              ),
            ),
          );
        }

        if (state is PlanTratamientoError) {
          return _Aviso(
            icono: Icons.error_outline_rounded,
            texto: state.mensaje,
            color: ac.red,
          );
        }

        final cargado = state as PlanTratamientoCargado;
        final plan = cargado.plan;
        final pendientes = _sinPlanificar(plan);
        final items = plan?.items ?? const <ItemPlanTratamiento>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pendientes.isNotEmpty) ...[
              _Subtitulo(
                texto: 'Hallazgos sin decidir',
                conteo: pendientes.length,
                color: ac.amber,
              ),
              const SizedBox(height: 8),
              for (final hallazgo in pendientes)
                _FilaHallazgo(
                  hallazgo: hallazgo,
                  habilitado: !cargado.guardando,
                  onLlevar: () => _llevarAlPlan(context, hallazgo),
                ),
              const SizedBox(height: 16),
            ],

            if (items.isEmpty)
              _Aviso(
                icono: Icons.playlist_add_rounded,
                color: ac.textMuted,
                texto: pendientes.isEmpty
                    ? 'La evaluación aún no registra hallazgos. Anótalos en el '
                          'odontograma y decide aquí cuáles se van a tratar.'
                    : 'Ningún hallazgo se ha llevado al plan todavía. Evaluar '
                          'no compromete a tratar.',
              )
            else ...[
              _Subtitulo(
                texto: 'Actividades del plan',
                conteo: items.length,
                color: ac.primaryGreen,
              ),
              const SizedBox(height: 8),
              for (final item in items)
                _FilaActividad(
                  item: item,
                  habilitado: !cargado.guardando,
                  fdiCode: _fdiDe(item.dienteId),
                  consultaId: consultaId,
                  doctorId: doctorId,
                ),
              const SizedBox(height: 14),
              _ResumenPlan(plan: plan!, habilitado: !cargado.guardando),
            ],
          ],
        );
      },
    );
  }

  int? _fdiDe(String? dienteId) {
    if (dienteId == null) return null;
    for (final diente in dientes) {
      if (diente.id == dienteId) return diente.fdiCode;
    }
    return null;
  }
}

class _Subtitulo extends StatelessWidget {
  final String texto;
  final int conteo;
  final Color color;

  const _Subtitulo({
    required this.texto,
    required this.conteo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Text(
          texto,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ac.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$conteo',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaHallazgo extends StatelessWidget {
  final HallazgoSinPlanificar hallazgo;
  final bool habilitado;
  final VoidCallback onLlevar;

  const _FilaHallazgo({
    required this.hallazgo,
    required this.habilitado,
    required this.onLlevar,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.circle_outlined, size: 13, color: ac.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hallazgo.descripcion,
              style: TextStyle(fontSize: 12, color: ac.textSecondary),
            ),
          ),
          TextButton.icon(
            onPressed: habilitado ? onLlevar : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text('Llevar al plan'),
            style: TextButton.styleFrom(
              foregroundColor: ac.primaryGreen,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaActividad extends StatelessWidget {
  final ItemPlanTratamiento item;
  final bool habilitado;
  final int? fdiCode;
  final String consultaId;
  final String doctorId;

  const _FilaActividad({
    required this.item,
    required this.habilitado,
    this.fdiCode,
    required this.consultaId,
    required this.doctorId,
  });

  String get _descripcion {
    final nombre = item.nombreTratamiento ?? 'Tratamiento';
    final pieza = fdiCode == null ? null : '$fdiCode';
    final cara = item.superficie?.name;
    final detalle = [?pieza, ?cara].join(' ');
    return detalle.isEmpty ? nombre : '$nombre · $detalle';
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final estilo = estiloItemPlan(item.estado, ac);
    final siguientes = item.estado.transicionesPermitidas;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(estilo.icono, size: 14, color: estilo.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _descripcion,
                  style: TextStyle(fontSize: 12, color: ac.textSecondary),
                ),
                if (item.motivoRechazo case final motivo?)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      motivo,
                      style: TextStyle(fontSize: 10, color: ac.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatMoneda(item.precioEstimado),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ac.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          ChipEstado(
            texto: item.estado.etiqueta,
            color: estilo.color,
            icono: estilo.icono,
          ),
          if (siguientes.isNotEmpty) ...[
            const SizedBox(width: 4),
            PopupMenuButton<EstadoItemPlan>(
              enabled: habilitado,
              tooltip: 'Cambiar estado',
              icon: Icon(
                Icons.more_horiz_rounded,
                size: 16,
                color: ac.textMuted,
              ),
              padding: EdgeInsets.zero,
              splashRadius: 16,
              onSelected: (destino) => _cambiar(context, destino),
              itemBuilder: (_) => [
                for (final destino in siguientes)
                  PopupMenuItem(
                    value: destino,
                    height: 38,
                    child: Text(
                      destino.etiqueta,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cambiar(BuildContext context, EstadoItemPlan destino) async {
    final cubit = context.read<PlanTratamientoCubit>();
    String? motivo;

    if (destino == EstadoItemPlan.rechazado) {
      motivo = await _pedirMotivo(context);
      if (motivo == null) return;
    }

    // Ejecutar (no solo etiquetar) es lo que genera el cargo real (SD-135 /
    // ticket de sesiones): se pide cantidad y notas antes de tocar el estado.
    if (destino == EstadoItemPlan.enProceso ||
        destino == EstadoItemPlan.completado) {
      final datos = await _pedirDatosEjecucion(context);
      if (datos == null) return;
      await cubit.registrarEjecucion(
        item,
        destinoEstado: destino,
        cantidadRealizada: datos.cantidad,
        consultaId: consultaId,
        doctorId: doctorId,
        notas: datos.notas,
      );
      return;
    }

    await cubit.cambiarEstadoActividad(item, destino, motivoRechazo: motivo);
  }

  Future<_DatosEjecucion?> _pedirDatosEjecucion(BuildContext context) {
    return showDialog<_DatosEjecucion>(
      context: context,
      builder: (ctx) => _DialogoRegistrarEjecucion(item: item),
    );
  }

  Future<String?> _pedirMotivo(BuildContext context) {
    final controlador = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        final ac = ctx.appColors;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Motivo del rechazo'),
          content: TextField(
            controller: controlador,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Por qué el paciente no acepta esta actividad',
              hintStyle: TextStyle(fontSize: 13, color: ac.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controlador.text.trim()),
              style: FilledButton.styleFrom(backgroundColor: ac.red),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
  }
}

class _ResumenPlan extends StatelessWidget {
  final PlanTratamiento plan;
  final bool habilitado;

  const _ResumenPlan({required this.plan, this.habilitado = true});

  /// Un plan solo se decide una vez por versión: mientras esté aceptado o
  /// rechazado no se vuelve a preguntar, y si cambia de contenido sube su
  /// versión y la decisión anterior deja de valer.
  bool get _admiteDecision =>
      plan.estado != EstadoPlanTratamiento.aceptado &&
      plan.estado != EstadoPlanTratamiento.rechazado &&
      plan.items.isNotEmpty;

  Future<void> _decidir(BuildContext context, {required bool aceptar}) async {
    final cubit = context.read<PlanTratamientoCubit>();
    final decision = await mostrarDialogoConsentimiento(
      context,
      plan: plan,
      aceptar: aceptar,
    );
    if (decision == null) return;
    await cubit.registrarConsentimiento(
      aceptado: decision.aceptado,
      persona: decision.persona,
      metodo: decision.metodo,
      relacion: decision.relacion,
      motivoRechazo: decision.motivoRechazo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Total(
                  etiqueta: 'Estimado del plan',
                  monto: plan.totalEstimado,
                  color: ac.textSecondary,
                ),
              ),
              Expanded(
                child: _Total(
                  etiqueta: 'Aceptado',
                  monto: plan.totalAceptado,
                  color: ac.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Estos montos son una estimación para el paciente. Nada se cobra '
            'hasta que la actividad se ejecuta y queda registrada en la '
            'consulta.',
            style: TextStyle(fontSize: 10, color: ac.textMuted, height: 1.4),
          ),
          if (_admiteDecision) ...[
            const SizedBox(height: 12),
            Text(
              'Decisión del paciente sobre la versión ${plan.version} del plan',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: ac.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: habilitado
                        ? () => _decidir(context, aceptar: false)
                        : null,
                    icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                    label: const Text('Registrar rechazo'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: habilitado
                        ? () => _decidir(context, aceptar: true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryGreen,
                    ),
                    icon: const Icon(Icons.how_to_reg_rounded, size: 17),
                    label: const Text('Registrar aceptación'),
                  ),
                ),
              ],
            ),
          ] else if (plan.estado == EstadoPlanTratamiento.aceptado ||
              plan.estado == EstadoPlanTratamiento.rechazado) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: ac.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Consentimiento registrado sobre la versión '
                    '${plan.version} del plan.',
                    style: TextStyle(fontSize: 11, color: ac.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String etiqueta;
  final double monto;
  final Color color;

  const _Total({
    required this.etiqueta,
    required this.monto,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 10, color: ac.textMuted)),
        const SizedBox(height: 2),
        Text(
          formatMoneda(monto),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color color;

  const _Aviso({required this.icono, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(fontSize: 12, color: ac.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
class _DatosEjecucion {
  final double cantidad;
  final String? notas;
  const _DatosEjecucion({required this.cantidad, this.notas});
}

class _DialogoRegistrarEjecucion extends StatefulWidget {
  const _DialogoRegistrarEjecucion({required this.item});
  final ItemPlanTratamiento item;

  @override
  State<_DialogoRegistrarEjecucion> createState() =>
      _DialogoRegistrarEjecucionState();
}

class _DialogoRegistrarEjecucionState
    extends State<_DialogoRegistrarEjecucion> {
  final _cantidadController = TextEditingController(text: '1');
  final _notasController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cantidadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Registrar ejecución',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _cantidadController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Cantidad realizada *',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Ingresa una cantidad válida';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notasController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notas de la ejecución',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ac.primaryGreen),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                _DatosEjecucion(
                  cantidad: double.parse(
                    _cantidadController.text.replaceAll(',', '.'),
                  ),
                  notas: _notasController.text.trim().isEmpty
                      ? null
                      : _notasController.text.trim(),
                ),
              );
            }
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}