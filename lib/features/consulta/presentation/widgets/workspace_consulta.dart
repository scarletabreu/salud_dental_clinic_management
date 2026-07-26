import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/asignar_tratamiento_sheet.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/asignar_diagnostico_sheet.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/contraindicacion_dialog.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/tarjeta_consulta.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/usecases/verificar_contraindicaciones_usecase.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/get_condiciones_paciente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/enums/tipo_atencion_clinica.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/entities/evaluacion_clinica.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/repositories/evaluacion_clinica_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/seccion_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_insumos.dart';

class WorkspaceConsulta extends StatefulWidget {
  final String? citaId;
  final TipoAtencionClinica tipoAtencion;
  const WorkspaceConsulta({super.key, this.citaId, required this.tipoAtencion});

  @override
  State<WorkspaceConsulta> createState() => _WorkspaceConsultaState();
}

class _WorkspaceConsultaState extends State<WorkspaceConsulta> {
  final _notasController = TextEditingController();

  List<Tratamiento> _catalogo = const [];
  Map<String, String> _nombrePorId = const {};
  bool _cargandoCatalogo = true;
  List<Diagnosis> _catalogoDiagnosticos = const [];
  List<ItemPlanTratamiento> _itemsEjecutables = const [];
  bool _cargandoPlanDelDia = false;

  /// Nombre de cada doctor, para que la ficha de una pieza pueda decir quién
  /// anotó cada cosa en vez de mostrar un uuid.
  Map<String, String> _nombrePorDoctorId = const {};

  /// La historia de cada pieza del paciente (SD-144). El doctor que atiende hoy
  /// necesita poder abrir un diente y ver todo lo que se le hizo antes, no solo
  /// la capa tenue que dibuja el odontograma.
  HistorialPiezas? _historialPiezas;

  /// Evaluación de esta consulta (SD-135). Se asegura una sola vez: es el
  /// contenedor al que se cuelgan los hallazgos y del que nace el plan.
  String? _evaluacionId;
  String? _consultaConEvaluacion;

  /// Condiciones estructuradas del paciente cargadas async desde `record_condicion`.
  /// Si están vacías se usan las del record embebido como respaldo.
  List<Condicion> _condicionesAsync = const [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
    _cargarDiagnosticos();
    _cargarCondicionesPaciente();
    _cargarDoctores();
    _cargarHistorialPiezas();

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

  Future<void> _cargarDiagnosticos() async {
    try {
      final catalogo = await sl<DiagnosisRepository>().getCatalogoCompleto();
      if (mounted) setState(() => _catalogoDiagnosticos = catalogo);
    } catch (_) {
      // La pantalla queda operable para tratamientos; el botón de diagnóstico
      // comunica la indisponibilidad en lugar de abrir un selector vacío.
    }
  }

  Future<void> _cargarDoctores() async {
    try {
      final doctores = await sl<DoctorRepository>().getDoctores();
      if (!mounted) return;
      setState(() {
        _nombrePorDoctorId = {
          for (final doctor in doctores)
            if (doctor.id != null)
              doctor.id!: 'Dr. ${doctor.nombre} ${doctor.apellido}'.trim(),
        };
      });
    } catch (_) {
      // La ficha de la pieza omite la autoría en vez de mostrar un uuid; todo
      // lo demás de la consulta sigue funcionando igual.
    }
  }

  /// El nombre del doctor, o cadena vacía si aún no se cargó el personal: la
  /// ficha prefiere no decir nada a mostrar un identificador.
  String _nombreDoctor(String doctorId) => _nombrePorDoctorId[doctorId] ?? '';

  /// Trae la historia por pieza del paciente de esta consulta. Es contexto: si
  /// falla, la ficha se queda con lo de hoy y la consulta sigue operable.
  Future<void> _cargarHistorialPiezas() async {
    final state = context.read<PacienteCubit>().state;
    if (state is! PacienteDetailLoaded) return;
    final pacienteId = state.paciente.id;
    if (pacienteId == null) return;

    try {
      final historial = await sl<ConsultaRepository>().getHistorialPiezas(
        pacienteId,
      );
      if (!mounted) return;
      setState(() => _historialPiezas = historial);
    } catch (_) {
      // Sin historial la ficha sigue mostrando lo evaluado, planificado y
      // ejecutado de esta consulta.
    }
  }

  Future<void> _onAddDiagnosis(
    Diente diente,
    TipoSuperficie? superficie,
  ) async {
    if (_catalogoDiagnosticos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el catálogo de diagnósticos.'),
        ),
      );
      return;
    }
    final seleccionado = await seleccionarDiagnostico(
      context,
      _catalogoDiagnosticos,
    );
    if (!mounted || seleccionado == null) return;
    context.read<ConsultaCubit>().aplicarDiagnostico(
      diente,
      superficie,
      seleccionado.diagnostico,
      severidad: seleccionado.severidad,
      origen: seleccionado.origen,
      notas: seleccionado.notas,
      // El hallazgo cuelga del acto de evaluación de esta consulta: de ahí sale
      // el doctor que lo anotó cuando el expediente lo vuelva a leer.
      evaluacionId: _evaluacionId,
    );
  }

  /// Las actividades del plan repartidas por pieza.
  ///
  /// El plan referencia el diente por su id y el odontograma se dibuja por
  /// código FDI, así que hace falta traducir. Una consulta recién creada aún no
  /// conoce los ids de sus piezas: en ese momento no hay plan que mostrar
  /// todavía, y el mapa sale vacío sin romper nada.
  Map<int, List<ItemPlanTratamiento>> _itemsPlanPorFdi(
    Odontograma odontograma,
    PlanTratamientoState estado,
  ) {
    if (estado is! PlanTratamientoCargado) return const {};
    final items = estado.plan?.items ?? const <ItemPlanTratamiento>[];
    if (items.isEmpty) return const {};

    final fdiPorDienteId = {
      for (final diente in odontograma.dientes)
        if (diente.id != null) diente.id!: diente.fdiCode,
    };

    final porFdi = <int, List<ItemPlanTratamiento>>{};
    for (final item in items) {
      final dienteId = item.dienteId;
      if (dienteId == null) continue;
      final fdi = fdiPorDienteId[dienteId];
      if (fdi == null) continue;
      porFdi.putIfAbsent(fdi, () => []).add(item);
    }
    return porFdi;
  }

  /// La observación queda pegada al diente, no al párrafo de la visita.
  void _onNotasPieza(Diente diente, String notas) {
    context.read<ConsultaCubit>().actualizarNotasPieza(diente, notas);
  }

  /// El odontodiagrama ya solo emite tejidos blandos: las claves dentales se
  /// anotan como diagnósticos y tratamientos desde el panel de la pieza, igual
  /// que en la arcada.
  void _onEvaluacionChanged(EvaluacionOdontologica evaluacion) {
    context.read<ConsultaCubit>().actualizarEvaluacionOdontologica(evaluacion);
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

  /// Deja registrada la evaluación de la consulta y carga su plan. Idempotente
  /// en la base, y aquí se llama una sola vez por consulta.
  Future<void> _prepararPlan(Consulta consulta) async {
    final consultaId = consulta.id;
    if (consultaId == null || _consultaConEvaluacion == consultaId) return;
    _consultaConEvaluacion = consultaId;

    final planCubit = context.read<PlanTratamientoCubit>();
    unawaited(planCubit.cargarDeConsulta(consultaId));
    if (widget.tipoAtencion == TipoAtencionClinica.consulta) {
      setState(() => _cargandoPlanDelDia = true);
      try {
        final items = await sl<PlanTratamientoRepository>().getItemsEjecutables(
          consulta.pacienteId,
        );
        if (mounted) setState(() => _itemsEjecutables = items);
      } catch (_) {
        // La consulta puede continuar como no planificada, pero cada actividad
        // seguirá requiriendo una justificación explícita.
        if (mounted) setState(() => _itemsEjecutables = const []);
      } finally {
        if (mounted) setState(() => _cargandoPlanDelDia = false);
      }
    }

    try {
      final id = await sl<EvaluacionClinicaRepository>()
          .registrarEvaluacionDeConsulta(
            EvaluacionClinica(
              pacienteId: consulta.pacienteId,
              consultaId: consultaId,
              doctorId: consulta.doctorId,
              fecha: consulta.fecha,
              motivo: consulta.motivoConsulta,
            ),
          );
      if (mounted) setState(() => _evaluacionId = id);
    } catch (_) {
      // El plan sigue siendo utilizable sin el vínculo a la evaluación; se
      // recupera en el siguiente guardado en vez de bloquear la consulta.
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
    final candidatas = _itemsEjecutables
        .where((item) => item.fdiDiente == diente.fdiCode)
        .where(
          (item) =>
              superficie == null ||
              item.superficie == null ||
              item.superficie == superficie,
        )
        .toList();
    final procedencia = await _elegirActividad(candidatas);
    if (!mounted || procedencia == null) return;

    final ItemPlanTratamiento? itemPlan = procedencia is ItemPlanTratamiento
        ? procedencia
        : null;
    final tratamiento = itemPlan == null
        ? await seleccionarTratamiento(context, _catalogo)
        : _catalogo.cast<Tratamiento?>().firstWhere(
            (item) => item?.id == itemPlan.tratamientoId,
            orElse: () => null,
          );
    if (tratamiento == null || !mounted) return;

    String? justificacionNoPlanificada;
    if (itemPlan == null) {
      justificacionNoPlanificada = await _pedirJustificacionNoPlanificada();
      if (!mounted || justificacionNoPlanificada == null) return;
    }

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
        itemPlanId: itemPlan?.id,
        justificacionNoPlanificada: justificacionNoPlanificada,
      );
    } else {
      consultaCubit.aplicarTratamiento(
        diente,
        superficie,
        tratamiento,
        itemPlanId: itemPlan?.id,
        justificacionNoPlanificada: justificacionNoPlanificada,
      );
    }

    if (!mounted) return;
    if (itemPlan != null) {
      setState(() => _itemsEjecutables.remove(itemPlan));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          itemPlan == null
              ? '"${tratamiento.nombre}" registrado como actividad no planificada.'
              : '"${tratamiento.nombre}" vinculado al plan de tratamiento.',
        ),
        backgroundColor: context.appColors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<Object?> _elegirActividad(List<ItemPlanTratamiento> candidatas) {
    final ac = context.appColors;
    return showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Qué se realizó hoy?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ac.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                candidatas.isEmpty
                    ? 'No hay actividades planificadas para esta pieza.'
                    : 'Selecciona una actividad aceptada del plan.',
                style: TextStyle(color: ac.textMuted),
              ),
              const SizedBox(height: 16),
              for (final item in candidatas)
                ListTile(
                  leading: Icon(Icons.event_available_outlined, color: ac.teal),
                  title: Text(item.nombreTratamiento ?? 'Tratamiento'),
                  subtitle: Text(
                    '${item.estado.etiqueta}'
                    '${item.superficie == null ? '' : ' · ${item.superficie!.name}'}',
                  ),
                  onTap: () => Navigator.pop(sheetContext, item),
                ),
              const Divider(),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(sheetContext, 'no_planificada'),
                icon: const Icon(Icons.add_alert_outlined),
                label: const Text('Registrar actividad no planificada'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _pedirJustificacionNoPlanificada() async {
    final formKey = GlobalKey<FormState>();
    var justificacion = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Justificar actividad no planificada'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => justificacion = value,
            decoration: const InputDecoration(
              labelText: 'Justificación clínica',
              hintText: 'Explica por qué fue necesario realizarla hoy',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'La justificación es obligatoria'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, justificacion.trim());
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  /// La ausencia se guarda en la pieza; la proyección la dibuja como «Pérdida»
  /// en el formulario, así que las dos vistas siguen contando lo mismo.
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
          // La consulta se crea con sus 52 piezas, así que llegar aquí
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

        // La evaluación y el plan se preparan cuando la consulta ya tiene id;
        // fuera del build para no tocar el cubit durante la construcción.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _prepararPlan(consulta);
        });

        final odontograma = consulta.odontograma!;
        final totalTratamientos = odontograma.dientes.fold(
          0,
          (sum, d) => sum + d.tratamientos.length,
        );
        final cargando = state is ConsultaGuardando;
        final guardado = state is ConsultaIniciada
            ? state.guardado
            : EstadoGuardado.guardando;
        final esEvaluacion =
            widget.tipoAtencion == TipoAtencionClinica.evaluacion;

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
                        esEvaluacion
                            ? 'Evaluación en curso'
                            : 'Consulta en curso',
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
                        esEvaluacion
                            ? 'Documenta lo encontrado antes de decidir qué tratar'
                            : 'Registra únicamente lo realizado durante esta sesión',
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
              subtitulo: esEvaluacion
                  ? 'Anota hallazgos, diagnósticos y tejidos blandos'
                  : 'Consulta lo evaluado y registra la ejecución sobre la pieza',
              // El plan se escucha aquí porque la ficha de cada pieza tiene que
              // mostrar lo planificado junto a lo evaluado y lo ejecutado: son
              // los tres ejes de SD-135 sobre el mismo diente.
              child: BlocBuilder<PlanTratamientoCubit, PlanTratamientoState>(
                builder: (context, planState) => VistasOdontograma(
                  odontograma: odontograma,
                  editable: true,
                  itemsPlan: _itemsPlanPorFdi(odontograma, planState),
                  historialPiezas: _historialPiezas,
                  onEvaluacionChanged: esEvaluacion
                      ? _onEvaluacionChanged
                      : null,
                  onNotasPiezaChanged: esEvaluacion ? _onNotasPieza : null,
                  onAddDiagnosis: esEvaluacion ? _onAddDiagnosis : null,
                  onAddTratamiento: esEvaluacion ? null : _onAddTratamiento,
                  onToggleAusente: esEvaluacion ? _onToggleAusente : null,
                  onQuitarTratamiento: _onQuitarTratamiento,
                  onToggleTratamientoTerminado: _onToggleTerminado,
                  nombreTratamiento: _nombreTratamiento,
                  nombreDoctor: _nombreDoctor,
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
            ),
            const SizedBox(height: 16),

            if (esEvaluacion)
              TarjetaConsulta(
                icon: Icons.fact_check_outlined,
                iconColor: ac.primaryBlue,
                titulo: 'Seleccionar para el plan',
                subtitulo:
                    'Elige cuáles hallazgos ameritan tratamiento; los demás '
                    'permanecen solo como hallazgos clínicos',
                child: SeccionPlanTratamiento(
                  dientes: odontograma.dientes,
                  pacienteId: consulta.pacienteId,
                  doctorId: consulta.doctorId,
                  consultaId: consulta.id ?? '',
                  evaluacionId: _evaluacionId,
                  onElegirTratamiento: () =>
                      seleccionarTratamiento(context, _catalogo),
                ),
              ),
            if (!esEvaluacion)
              TarjetaConsulta(
                icon: Icons.event_available_outlined,
                iconColor: ac.teal,
                titulo: 'Actividades planificadas',
                subtitulo:
                    'Al registrar en una pieza podrás vincular una actividad '
                    'aceptada o justificar una intervención imprevista',
                child: _cargandoPlanDelDia
                    ? const LinearProgressIndicator()
                    : _itemsEjecutables.isEmpty
                    ? Text(
                        'No quedan actividades aceptadas pendientes. Si surge '
                        'una necesidad clínica, regístrala como no planificada '
                        'y explica el motivo.',
                        style: TextStyle(color: ac.textSecondary, height: 1.4),
                      )
                    : Column(
                        children: [
                          for (final item in _itemsEjecutables)
                            ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.radio_button_unchecked_rounded,
                                color: ac.teal,
                              ),
                              title: Text(
                                item.nombreTratamiento ?? 'Tratamiento',
                              ),
                              subtitle: Text(
                                '${item.estado.etiqueta}'
                                '${item.fdiDiente == null ? '' : ' · Pieza ${item.fdiDiente}'}',
                              ),
                              trailing: item.fdiDiente == null
                                  ? const Text('Actividad general')
                                  : TextButton(
                                      onPressed: () {
                                        final diente = odontograma.dientes
                                            .firstWhere(
                                              (d) =>
                                                  d.fdiCode == item.fdiDiente,
                                            );
                                        _onAddTratamiento(
                                          diente,
                                          item.superficie,
                                        );
                                      },
                                      child: const Text('Registrar'),
                                    ),
                            ),
                        ],
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

            if (!esEvaluacion) ...[
              SeccionReceta(
                condicionesPaciente: _condicionesPaciente(),
                recetas: consulta.recetas,
              ),
              const SizedBox(height: 28),
              const SizedBox(height: 16),
              SeccionInsumos(insumos: consulta.insumosUtilizados),
            ],

            _TerminarButton(
              cargando: cargando,
              label: esEvaluacion
                  ? 'Finalizar evaluación'
                  : 'Terminar consulta',
              onTap: cargando
                  ? null
                  : () => esEvaluacion
                        ? context.read<ConsultaCubit>().terminarEvaluacion()
                        : context.read<ConsultaCubit>().terminarConsulta(),
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
    required this.label,
  });
  final bool cargando;
  final VoidCallback? onTap;
  final AppColors ac;
  final String label;

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
        label: Text(cargando ? 'Finalizando…' : label),
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
        EstadoGuardado.alDia =>
          'Todo el trabajo de esta consulta está en el '
              'servidor.',
        EstadoGuardado.pendiente =>
          'Hay cambios que se guardarán solos en unos '
              'segundos.',
        EstadoGuardado.guardando => 'Escribiendo los cambios en el servidor.',
        EstadoGuardado.fallido =>
          'Los cambios siguen aquí y se reintentará '
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
