import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/asignar_tratamiento_sheet.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/contraindicacion_dialog.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/tarjeta_consulta.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/usecases/verificar_contraindicaciones_usecase.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/get_condiciones_paciente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';

class WorkspaceConsulta extends StatefulWidget {
  final String? citaId;
  const WorkspaceConsulta({super.key, this.citaId});

  @override
  State<WorkspaceConsulta> createState() => _WorkspaceConsultaState();
}

class _WorkspaceConsultaState extends State<WorkspaceConsulta> {
  final _notasController = TextEditingController();

  List<Tratamiento> _catalogo = const [];
  Map<String, String> _nombrePorId = const {};
  bool _cargandoCatalogo = true;

  /// Condiciones estructuradas del paciente cargadas async desde `record_condicion`.
  /// Si están vacías se usan las del record embebido como respaldo.
  List<Condicion> _condicionesAsync = const [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
    _cargarCondicionesPaciente();

    final state = context.read<ConsultaCubit>().state;
    if (state is ConsultaIniciada && state.consulta.notas != null) {
      _notasController.text = state.consulta.notas!;
    } else if (state is ConsultaGuardando && state.consulta?.notas != null) {
      _notasController.text = state.consulta!.notas!;
    }

    _notasController.addListener(() {
      context.read<ConsultaCubit>().actualizarObservaciones(
        _notasController.text,
      );
    });
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final catalogo = await sl<TratamientoRepository>()
          .getCatalogoTratamientos();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _nombrePorId = {
          for (final t in catalogo)
            if (t.id != null) t.id!: t.nombre,
        };
        _cargandoCatalogo = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoCatalogo = false);
    }
  }

  /// Carga las condiciones desde `record_condicion` (tabla puente real).
  /// Si falla, se usa el fallback del record embebido en `_condicionesPaciente`.
  Future<void> _cargarCondicionesPaciente() async {
    final state = context.read<PacienteCubit>().state;
    if (state is! PacienteDetailLoaded) return;
    final pacienteId = state.paciente.id;
    if (pacienteId == null) return;

    try {
      final condiciones = await sl<GetCondicionesPaciente>()(pacienteId);
      if (!mounted) return;
      setState(() => _condicionesAsync = condiciones);
    } catch (_) {
      // Se mantiene vacío: _condicionesPaciente() cae al record embebido.
    }
  }

  List<Condicion> _condicionesPaciente() {
    if (_condicionesAsync.isNotEmpty) return _condicionesAsync;
    final state = context.read<PacienteCubit>().state;
    if (state is PacienteDetailLoaded) {
      return state.paciente.record.condiciones;
    }
    return [];
  }

  Future<void> _onAddTratamiento(
    Diente diente,
    TipoSuperficie? superficie,
  ) async {
    if (_cargandoCatalogo) return;
    final consultaCubit = context.read<ConsultaCubit>();
    final tratamiento = await seleccionarTratamiento(context, _catalogo);
    if (tratamiento == null || !mounted) return;

    final conflictos = VerificarContraindicacionesUseCase().call(
      condicionesPaciente: _condicionesPaciente(),
      tratamiento: tratamiento,
    );

    if (conflictos.isNotEmpty) {
      final justificacion = await mostrarContraindicacionDialog(
        context,
        tratamiento.nombre,
        conflictos,
      );
      if (justificacion == null) return;

      consultaCubit.aplicarTratamiento(
        diente,
        superficie,
        tratamiento,
        justificacionClinica: justificacion,
      );
    } else {
      consultaCubit.aplicarTratamiento(diente, superficie, tratamiento);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${tratamiento.nombre}" asignado al diente ${diente.fdiCode}.',
        ),
        backgroundColor: context.appColors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onToggleAusente(Diente diente, bool ausente) {
    context.read<ConsultaCubit>().toggleDienteAusente(diente, ausente);
  }

  String _nombreTratamiento(String tratamientoId) =>
      _nombrePorId[tratamientoId] ?? 'Tratamiento';

  void _onToggleTerminado(Diente diente, int index, bool terminado) {
    context.read<ConsultaCubit>().marcarTratamientoTerminado(
      diente,
      index,
      terminado,
    );
  }

  Future<void> _onQuitarTratamiento(Diente diente, int index) async {
    final ac = context.appColors;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitar tratamiento'),
        content: Text(
          '¿Quitar este tratamiento del diente ${diente.fdiCode}?',
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
    if (confirmado != true || !mounted) return;
    context.read<ConsultaCubit>().quitarTratamiento(diente, index);
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return BlocBuilder<ConsultaCubit, ConsultaState>(
      buildWhen: (previous, current) =>
          current is ConsultaIniciada ||
          current is ConsultaGuardando ||
          current is ConsultaError,
      builder: (context, state) {
        if (state is! ConsultaIniciada && state is! ConsultaGuardando) {
          return Center(
            child: CircularProgressIndicator(color: ac.primaryBlue),
          );
        }

        final consulta = state is ConsultaIniciada
            ? state.consulta
            : (state as ConsultaGuardando).consulta;

        if (consulta == null) {
          return Center(
            child: CircularProgressIndicator(color: ac.primaryBlue),
          );
        }

        if (consulta.odontograma == null) {
          // La consulta se crea con sus 32 piezas, así que llegar aquí
          // significa que la carga falló: hay que decirlo, no dejar una
          // pantalla en blanco que parezca «este paciente no tiene nada».
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 32,
                    color: ac.textDisabled,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No se pudo cargar el odontograma de esta consulta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ac.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Vuelve a abrir la consulta; si persiste, revisa la '
                    'conexión con el servidor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: ac.textMuted),
                  ),
                ],
              ),
            ),
          );
        }

        final odontograma = consulta.odontograma!;
        final totalTratamientos = odontograma.dientes.fold(
          0,
          (sum, d) => sum + d.tratamientos.length,
        );
        final cargando = state is ConsultaGuardando;
        final guardado = state is ConsultaIniciada
            ? state.guardado
            : EstadoGuardado.guardando;

        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ac.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '02',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consulta en curso',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ac.textPrimary,
                          letterSpacing: -0.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Registra tratamientos en el odontograma y añade tus notas',
                        style: TextStyle(
                          fontSize: 12,
                          color: ac.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _IndicadorGuardado(estado: guardado),
                if (totalTratamientos > 0) const SizedBox(width: 8),
                if (totalTratamientos > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ac.teal.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ac.teal.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.healing_rounded, size: 12, color: ac.teal),
                        const SizedBox(width: 5),
                        Text(
                          '$totalTratamientos tratamiento${totalTratamientos > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ac.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            TarjetaConsulta(
              icon: Icons.assignment_outlined,
              iconColor: ac.indigo,
              titulo: 'Odontograma',
              subtitulo:
                  'Anota hallazgos en el formulario o asigna tratamientos en '
                  'la arcada: es la misma boca en dos vistas',
              child: VistasOdontograma(
                odontograma: odontograma,
                editable: true,
                onEvaluacionChanged: context
                    .read<ConsultaCubit>()
                    .actualizarEvaluacionOdontologica,
                onAddTratamiento: _onAddTratamiento,
                onToggleAusente: _onToggleAusente,
                onQuitarTratamiento: _onQuitarTratamiento,
                onToggleTratamientoTerminado: _onToggleTerminado,
                nombreTratamiento: _nombreTratamiento,
                accion: _cargandoCatalogo
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ac.teal,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            TarjetaConsulta(
              icon: Icons.edit_note_rounded,
              iconColor: ac.indigo,
              titulo: 'Notas clínicas',
              subtitulo: 'Observaciones para el expediente',
              // La consulta ya se guarda sola; el botón solo adelanta la
              // escritura para quien prefiere confirmarlo a mano.
              accion: TextButton.icon(
                onPressed: cargando || guardado == EstadoGuardado.guardando
                    ? null
                    : () => context.read<ConsultaCubit>().guardarParcial(),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Guardar ahora'),
              ),
              child: TextField(
                controller: _notasController,
                minLines: 4,
                maxLines: 7,
                style: TextStyle(
                  fontSize: 14,
                  color: ac.textPrimary,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Observaciones, hallazgos adicionales, indicaciones…',
                  hintStyle: TextStyle(
                    color: ac.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  filled: true,
                  fillColor: ac.bgPage,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ac.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ac.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ac.indigo, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SeccionReceta(
              condicionesPaciente: _condicionesPaciente(),
              recetas: consulta.recetas,
            ),
            const SizedBox(height: 28),

            _TerminarButton(
              cargando: cargando,
              onTap: cargando
                  ? null
                  : () => context.read<ConsultaCubit>().terminarConsulta(),
              ac: ac,
            ),
          ],
        );
      },
    );
  }
}

class _TerminarButton extends StatelessWidget {
  const _TerminarButton({
    required this.cargando,
    required this.onTap,
    required this.ac,
  });
  final bool cargando;
  final VoidCallback? onTap;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: ac.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        icon: cargando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(cargando ? 'Finalizando…' : 'Terminar consulta'),
      ),
    );
  }
}

/// Estado del autoguardado, siempre visible en la cabecera de la consulta.
///
/// El doctor tiene que poder saber de un vistazo si lo que acaba de anotar ya
/// está a salvo, sin abrir nada ni acordarse de pulsar un botón.
class _IndicadorGuardado extends StatelessWidget {
  final EstadoGuardado estado;

  const _IndicadorGuardado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final (color, icono, texto) = switch (estado) {
      EstadoGuardado.alDia => (ac.green, Icons.cloud_done_outlined, 'Guardado'),
      EstadoGuardado.pendiente => (
        ac.textMuted,
        Icons.cloud_queue_rounded,
        'Sin guardar',
      ),
      EstadoGuardado.guardando => (
        ac.textMuted,
        Icons.cloud_sync_outlined,
        'Guardando…',
      ),
      EstadoGuardado.fallido => (
        ac.red,
        Icons.cloud_off_rounded,
        'No se pudo guardar',
      ),
    };

    return Tooltip(
      message: switch (estado) {
        EstadoGuardado.alDia => 'Todo el trabajo de esta consulta está en el '
            'servidor.',
        EstadoGuardado.pendiente => 'Hay cambios que se guardarán solos en unos '
            'segundos.',
        EstadoGuardado.guardando => 'Escribiendo los cambios en el servidor.',
        EstadoGuardado.fallido => 'Los cambios siguen aquí y se reintentará '
            'solo. No cierres la consulta.',
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              texto,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
