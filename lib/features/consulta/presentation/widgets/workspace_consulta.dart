import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/categoria_condicion.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/enums/tipo_condicion.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_state.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/asignar_diagnostico_sheet.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/asignar_tratamiento_sheet.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/contraindicacion_dialog.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/alcance.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/condicion_detectada.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_alertas_clinicas.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_clinica_general.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_condiciones_detectadas.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_insumos.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/seccion_receta.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/widgets/tarjeta_consulta.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/usecases/verificar_contraindicaciones_usecase.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/entities/evaluacion_clinica.dart';
import 'package:salud_dental_clinic_management/features/evaluacion_clinica/domain/repositories/evaluacion_clinica_repository.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/vistas_odontograma.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/entities/item_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/enums/estado_item_plan.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/domain/entities/tratamiento_aplicado.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/plan_tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/seccion_plan_tratamiento.dart';
import 'package:salud_dental_clinic_management/features/receta/presentation/pages/receta_form_dialog.dart';
import 'package:salud_dental_clinic_management/features/condicion/domain/repositories/condicion_repository.dart';
import 'package:salud_dental_clinic_management/features/record/domain/usecases/get_condiciones_paciente.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/repositories/tratamiento_repository.dart';

class WorkspaceConsulta extends StatefulWidget {
  final String? citaId;
  const WorkspaceConsulta({super.key, this.citaId});

  @override
  State<WorkspaceConsulta> createState() => _WorkspaceConsultaState();
}

class _WorkspaceConsultaState extends State<WorkspaceConsulta> {
  final _notasController = TextEditingController();
  String? _consultaNotasHidratada;
  bool _hidratandoNotas = false;

  List<Tratamiento> _catalogo = const [];
  Map<String, String> _nombrePorId = const {};
  bool _cargandoCatalogo = true;
  List<Diagnosis> _catalogoDiagnosticos = const [];
  List<ItemPlanTratamiento> _itemsEjecutables = const [];
  bool _cargandoPlanDelDia = false;
  String? _errorPlanDelDia;
  Map<String, String> _nombrePorDoctorId = const {};
  HistorialPiezas? _historialPiezas;
  String? _evaluacionId;
  String? _consultaConEvaluacion;
  List<Condicion> _condicionesAsync = const [];
  List<Condicion> _catalogoCondiciones = const [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
    _cargarDiagnosticos();
    _cargarCondicionesPaciente();
    _cargarCatalogoCondiciones();
    _cargarDoctores();
    _cargarHistorialPiezas();

    _notasController.addListener(() {
      if (_hidratandoNotas) return;
      context.read<ConsultaCubit>().actualizarObservaciones(
        _notasController.text,
      );
    });
  }

  void _hidratarNotasDeConsulta(Consulta consulta) {
    final consultaId = consulta.id;
    if (consultaId == null || _consultaNotasHidratada == consultaId) return;
    _consultaNotasHidratada = consultaId;
    final notas = consulta.notas ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notasController.text == notas) return;
      _hidratandoNotas = true;
      _notasController.value = TextEditingValue(
        text: notas,
        selection: TextSelection.collapsed(offset: notas.length),
      );
      _hidratandoNotas = false;
    });
  }

  Future<void> _cargarDiagnosticos() async {
    try {
      final catalogo = await sl<DiagnosisRepository>().getCatalogoCompleto();
      if (mounted) setState(() => _catalogoDiagnosticos = catalogo);
    } catch (_) {}
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
    } catch (_) {}
  }

  String _nombreDoctor(String doctorId) => _nombrePorDoctorId[doctorId] ?? '';

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
    } catch (_) {}
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
      _catalogoDiagnosticosDePieza,
    );
    if (!mounted || seleccionado == null) return;
    if (seleccionado.diagnostico.alcance == Alcance.puntual &&
        superficie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${seleccionado.diagnostico.nombre}" se registra sobre una cara '
            'concreta. Selecciona la superficie en la pieza ${diente.fdiCode}.',
          ),
          backgroundColor: context.appColors.amber,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    context.read<ConsultaCubit>().aplicarDiagnostico(
      diente,
      superficie,
      seleccionado.diagnostico,
      severidad: seleccionado.severidad,
      origen: seleccionado.origen,
      notas: seleccionado.notas,
      evaluacionId: _evaluacionId,
    );
  }

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

  void _onNotasPieza(Diente diente, String notas) {
    context.read<ConsultaCubit>().actualizarNotasPieza(diente, notas);
  }

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

  Future<void> _cargarCondicionesPaciente() async {
    final state = context.read<PacienteCubit>().state;
    if (state is! PacienteDetailLoaded) return;
    final pacienteId = state.paciente.id;
    if (pacienteId == null) return;

    try {
      final condiciones = await sl<GetCondicionesPaciente>()(pacienteId);
      if (!mounted) return;
      setState(() => _condicionesAsync = condiciones);
    } catch (_) {}
  }

  Future<void> _cargarCatalogoCondiciones() async {
    try {
      final catalogo = await sl<CondicionRepository>().getCondiciones();
      if (!mounted) return;
      setState(() => _catalogoCondiciones = catalogo);
    } catch (_) {}
  }

  Future<void> _prepararPlan(Consulta consulta) async {
    final consultaId = consulta.id;
    if (consultaId == null || _consultaConEvaluacion == consultaId) return;
    _consultaConEvaluacion = consultaId;

    final planCubit = context.read<PlanTratamientoCubit>();
    unawaited(planCubit.cargarDeConsulta(consultaId));
    await _cargarItemsEjecutables(consulta.pacienteId);

    await _registrarEvaluacion(consulta, consultaId);
  }

  /// Los tratamientos aceptados pendientes del plan. Se leía una sola vez por
  /// consulta y lo que el asistente aceptaba o agendaba durante ella no
  /// existía del lado del doctor (MU-5): ahora se puede releer a demanda
  /// desde la propia tarjeta, sin recargar el resto del workspace.
  Future<void> _cargarItemsEjecutables(String pacienteId) async {
    setState(() {
      _cargandoPlanDelDia = true;
      _errorPlanDelDia = null;
    });
    try {
      final items = await sl<PlanTratamientoRepository>().getItemsEjecutables(
        pacienteId,
      );
      if (mounted) setState(() => _itemsEjecutables = items);
    } catch (_) {
      if (mounted) {
        setState(() {
          _itemsEjecutables = const [];
          _errorPlanDelDia =
              'No se pudo cargar el plan del paciente. Puedes continuar con '
              'el catálogo, pero los tratamientos no se vincularán al plan.';
        });
      }
    } finally {
      if (mounted) setState(() => _cargandoPlanDelDia = false);
    }
  }

  Future<void> _registrarEvaluacion(Consulta consulta, String consultaId) async {
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
    } catch (_) {}
  }

  /// Lo que debe pesar en cualquier contraindicación: el expediente más lo
  /// descubierto hoy. Una condición registrada en esta consulta cuenta desde
  /// que se registra, no desde que se cierra (HFX-CLIN-003).
  List<Condicion> _condicionesPaciente() {
    final delExpediente = _condicionesAsync.isNotEmpty
        ? _condicionesAsync
        : switch (context.read<PacienteCubit>().state) {
            PacienteDetailLoaded(:final paciente) => paciente.record.condiciones,
            _ => const <Condicion>[],
          };

    final detectadas = _condicionesDetectadas();
    if (detectadas.isEmpty) return delExpediente;

    final ids = {
      for (final c in delExpediente)
        if (c.id != null) c.id!,
    };
    return [
      ...delExpediente,
      for (final detectada in detectadas)
        if (!ids.contains(detectada.condicionId))
          detectada.condicion ??
              _catalogoCondiciones.cast<Condicion?>().firstWhere(
                    (c) => c?.id == detectada.condicionId,
                    orElse: () => null,
                  ) ??
              Condicion(
                id: detectada.condicionId,
                nombre: detectada.nombre,
                tipo: TipoCondicion.patologica,
                categoria: CategoriaCondicion.temporal,
              ),
    ];
  }

  List<CondicionDetectada> _condicionesDetectadas() {
    final state = context.read<ConsultaCubit>().state;
    return switch (state) {
      ConsultaIniciada(:final consulta) => consulta.condicionesDetectadas,
      ConsultaGuardando(:final consulta?) => consulta.condicionesDetectadas,
      _ => const <CondicionDetectada>[],
    };
  }

  /// El contexto manda: en una pieza solo se ofrece lo que se aplica a una
  /// pieza o a una de sus caras. Lo global vive en su propia sección, y la
  /// base rechaza la combinación equivocada aunque llegue por REST.
  List<Tratamiento> get _catalogoDePieza => [
    for (final t in _catalogo)
      if (t.alcance == Alcance.diente || t.alcance == Alcance.puntual) t,
  ];

  List<Diagnosis> get _catalogoDiagnosticosDePieza => [
    for (final d in _catalogoDiagnosticos)
      if (d.alcance == Alcance.diente || d.alcance == Alcance.puntual) d,
  ];

  Future<void> _onAddTratamiento(
    Diente diente,
    TipoSuperficie? superficie,
  ) async {
    if (_cargandoCatalogo) return;
    final tratamiento = await seleccionarTratamiento(context, _catalogoDePieza);
    if (tratamiento == null || !mounted) return;

    // Un tratamiento puntual sin cara es un dato incompleto: la base lo
    // rechaza y aquí se dice antes, nombrando lo que falta.
    if (tratamiento.alcance == Alcance.puntual && superficie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${tratamiento.nombre}" se aplica sobre una cara concreta. '
            'Selecciona la superficie en la pieza ${diente.fdiCode}.',
          ),
          backgroundColor: context.appColors.amber,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final candidatas = _itemsEjecutables
        .where((item) => item.fdiDiente == diente.fdiCode)
        .where(
          (item) =>
              superficie == null ||
              item.superficie == null ||
              item.superficie == superficie,
        )
        .where((item) => item.tratamientoId == tratamiento.id)
        .toList();
    final itemPlan = candidatas.firstOrNull;
    await _aplicarTratamiento(
      diente,
      superficie,
      tratamiento,
      itemPlan: itemPlan,
    );
  }

  Future<void> _registrarItemPlan(
    Diente diente,
    ItemPlanTratamiento itemPlan,
  ) async {
    final tratamiento = _catalogo.cast<Tratamiento?>().firstWhere(
      (item) => item?.id == itemPlan.tratamientoId,
      orElse: () => null,
    );
    if (tratamiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El tratamiento del plan ya no está disponible en el catálogo.',
          ),
        ),
      );
      return;
    }
    await _aplicarTratamiento(
      diente,
      itemPlan.superficie,
      tratamiento,
      itemPlan: itemPlan,
    );
  }

  /// Registra la ejecución de una actividad del plan **dentro** de la consulta.
  ///
  /// La sección del plan pedía la cantidad y las notas y después insertaba
  /// directo en `tratamientos_aplicados`. Nadie avisaba al `ConsultaCubit`, así
  /// que la fila no viajaba en el siguiente payload y el servidor la anulaba
  /// —el contrato es «lo que la clave declara es el conjunto completo»—: el
  /// procedimiento desaparecía del expediente y la pre-factura salía en cero
  /// (F1-01, reproducido en vivo: RD$12,000 → RD$0).
  ///
  /// Ahora la ejecución entra por el mismo sitio que cualquier otra anotación
  /// de la consulta y el estado del plan se mueve después.
  Future<void> _ejecutarActividadPlan(
    ItemPlanTratamiento item,
    EstadoItemPlan destino,
    double cantidadRealizada,
    String? notas,
  ) async {
    final consultaCubit = context.read<ConsultaCubit>();
    final planCubit = context.read<PlanTratamientoCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final tratamiento = _catalogo.cast<Tratamiento?>().firstWhere(
      (candidato) => candidato?.id == item.tratamientoId,
      orElse: () => null,
    );
    if (tratamiento == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'El tratamiento del plan ya no está disponible en el catálogo.',
          ),
        ),
      );
      return;
    }

    final estado = destino == EstadoItemPlan.completado
        ? EstadoTratamientoAplicado.completado
        : EstadoTratamientoAplicado.enProceso;

    final estadoConsulta = consultaCubit.state;
    final dientes = estadoConsulta is ConsultaIniciada
        ? estadoConsulta.consulta.odontograma?.dientes ?? const <Diente>[]
        : const <Diente>[];

    final diente = item.dienteId == null
        ? null
        : dientes.cast<Diente?>().firstWhere(
            (candidato) => candidato?.id == item.dienteId,
            orElse: () => null,
          );

    if (item.dienteId != null && diente == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se encontró la pieza de la actividad en este odontograma.',
          ),
        ),
      );
      return;
    }

    if (diente == null) {
      consultaCubit.aplicarTratamientoGeneral(
        tratamiento,
        justificacionClinica: notas,
        itemPlanId: item.id,
        cantidadRealizada: cantidadRealizada,
        estado: estado,
      );
    } else {
      consultaCubit.aplicarTratamiento(
        diente,
        item.superficie,
        tratamiento,
        justificacionClinica: notas,
        itemPlanId: item.id,
        cantidadRealizada: cantidadRealizada,
        estado: estado,
      );
    }

    // El estado del plan se mueve después de que la ejecución ya está en el
    // estado de la consulta: si esto falla, el trabajo clínico no se pierde.
    await planCubit.cambiarEstadoActividad(item, destino);

    if (!mounted) return;
    setState(() => _itemsEjecutables.removeWhere((i) => i.id == item.id));
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${tratamiento.nombre}" registrado en la consulta.'),
        backgroundColor: context.appColors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _aplicarTratamiento(
    Diente diente,
    TipoSuperficie? superficie,
    Tratamiento tratamiento, {
    ItemPlanTratamiento? itemPlan,
  }) async {
    final consultaCubit = context.read<ConsultaCubit>();
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
      );
    } else {
      consultaCubit.aplicarTratamiento(
        diente,
        superficie,
        tratamiento,
        itemPlanId: itemPlan?.id,
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
              ? '"${tratamiento.nombre}" agregado a la consulta.'
              : '"${tratamiento.nombre}" vinculado al plan de tratamiento.',
        ),
        backgroundColor: context.appColors.teal,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _onAgregarTratamientoGeneral() async {
    final generales = SeccionClinicaGeneral.tratamientosGenerales(_catalogo);
    if (generales.isEmpty) return;
    final tratamiento = await seleccionarTratamiento(context, generales);
    if (tratamiento == null || !mounted) return;

    final conflictos = VerificarContraindicacionesUseCase().call(
      condicionesPaciente: _condicionesPaciente(),
      tratamiento: tratamiento,
    );
    String? justificacion;
    if (conflictos.isNotEmpty) {
      justificacion = await mostrarContraindicacionDialog(
        context,
        tratamiento.nombre,
        conflictos,
      );
      if (justificacion == null || !mounted) return;
    }

    context.read<ConsultaCubit>().aplicarTratamientoGeneral(
      tratamiento,
      justificacionClinica: justificacion,
    );
  }

  Future<void> _onAgregarDiagnosticoGeneral() async {
    final generales = SeccionClinicaGeneral.diagnosticosGenerales(
      _catalogoDiagnosticos,
    );
    if (generales.isEmpty) return;
    final seleccionado = await seleccionarDiagnostico(context, generales);
    if (seleccionado == null || !mounted) return;
    context.read<ConsultaCubit>().aplicarDiagnosticoGeneral(
      seleccionado.diagnostico,
      severidad: seleccionado.severidad,
      origen: seleccionado.origen,
      notas: seleccionado.notas,
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

  Future<void> _abrirFormularioFormalReceta(Consulta consulta) async {
    final pacienteState = context.read<PacienteCubit>().state;
    if (pacienteState is! PacienteDetailLoaded) return;

    final recetaOriginal = consulta.recetas.firstOrNull;

    final recetaFormal = await RecetaFormDialog.mostrar(
      context,
      paciente: pacienteState.paciente,
      consultaId: consulta.id ?? '',
      recetaParaEditar: recetaOriginal,
    );

    if (recetaFormal != null && mounted) {
      final cubit = context.read<ConsultaCubit>();
      cubit.limpiarRecetas();
      for (final item in recetaFormal.items) {
        cubit.agregarItemReceta(itemReceta: item);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Formulario formal de receta cargado a la consulta.',
          ),
          backgroundColor: context.appColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
            child: CircularProgressIndicator(color: ac.primaryGreen),
          );
        }

        final consulta = state is ConsultaIniciada
            ? state.consulta
            : (state as ConsultaGuardando).consulta;

        if (consulta == null) {
          return Center(
            child: CircularProgressIndicator(color: ac.primaryGreen),
          );
        }

        _hidratarNotasDeConsulta(consulta);

        if (consulta.odontograma == null) {
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        'Diagnostica, planifica y registra lo realizado',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: ac.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Los distintivos van en un `Wrap` flexible: juntos miden más
                // que la cabecera entera cuando el panel se estrecha —al
                // arrastrar el borde de la ventana, por ejemplo—, y como fila
                // rígida desbordaban en vez de reacomodarse.
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _IndicadorGuardado(estado: guardado),
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
                              Icon(
                                Icons.healing_rounded,
                                size: 12,
                                color: ac.teal,
                              ),
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
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (state is ConsultaIniciada)
              _AvisoPersistencia(
                estado: state.guardado,
                detalle: state.detalleFallo,
                onReintentar: () =>
                    context.read<ConsultaCubit>().guardarParcial(),
                onRecargar: consulta.id == null
                    ? null
                    : () => context.read<ConsultaCubit>().reanudarConsulta(
                        consultaId: consulta.id!,
                      ),
              ),

            SeccionAlertasClinicas(alertas: consulta.alertas),

            TarjetaConsulta(
              icon: Icons.assignment_outlined,
              iconColor: ac.indigo,
              titulo: 'Odontograma',
              subtitulo:
                  'Anota hallazgos, diagnósticos y tratamientos sobre la pieza',
              child: BlocBuilder<PlanTratamientoCubit, PlanTratamientoState>(
                builder: (context, planState) => VistasOdontograma(
                  odontograma: odontograma,
                  editable: true,
                  itemsPlan: _itemsPlanPorFdi(odontograma, planState),
                  historialPiezas: _historialPiezas,
                  onEvaluacionChanged: _onEvaluacionChanged,
                  onNotasPiezaChanged: _onNotasPieza,
                  onAddDiagnosis: _onAddDiagnosis,
                  onAddTratamiento: _onAddTratamiento,
                  onToggleAusente: _onToggleAusente,
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

            TarjetaConsulta(
              icon: Icons.medical_information_outlined,
              iconColor: ac.amber,
              titulo: 'Condiciones detectadas hoy',
              subtitulo:
                  'Cuentan de inmediato en contraindicaciones y alertas',
              child: SeccionCondicionesDetectadas(
                detectadas: consulta.condicionesDetectadas,
                catalogo: _catalogoCondiciones,
              ),
            ),
            const SizedBox(height: 16),

            TarjetaConsulta(
              icon: Icons.public_rounded,
              iconColor: ac.teal,
              titulo: 'Hallazgos y tratamientos generales',
              subtitulo: 'Lo que no corresponde a una pieza concreta',
              child: SeccionClinicaGeneral(
                tratamientos: consulta.tratamientosGenerales,
                diagnosticos: consulta.diagnosticosGenerales,
                nombreTratamiento: _nombreTratamiento,
                nombreDiagnostico: (id) => id,
                onAgregarTratamiento: _onAgregarTratamientoGeneral,
                onAgregarDiagnostico: _onAgregarDiagnosticoGeneral,
                onQuitarTratamiento: (i) =>
                    context.read<ConsultaCubit>().quitarTratamientoGeneral(i),
                onQuitarDiagnostico: (i) =>
                    context.read<ConsultaCubit>().quitarDiagnosticoGeneral(i),
                hayCatalogoGeneral:
                    SeccionClinicaGeneral.tratamientosGenerales(
                      _catalogo,
                    ).isNotEmpty ||
                    SeccionClinicaGeneral.diagnosticosGenerales(
                      _catalogoDiagnosticos,
                    ).isNotEmpty,
              ),
            ),
            const SizedBox(height: 16),

            TarjetaConsulta(
              icon: Icons.fact_check_outlined,
              iconColor: ac.primaryGreen,
              titulo: 'Plan de tratamiento',
              subtitulo:
                  'Planifica desde los diagnósticos sin salir de la consulta',
              child: SeccionPlanTratamiento(
                dientes: odontograma.dientes,
                pacienteId: consulta.pacienteId,
                doctorId: consulta.doctorId,
                consultaId: consulta.id ?? '',
                evaluacionId: _evaluacionId,
                onElegirTratamiento: () =>
                    seleccionarTratamiento(context, _catalogo),
                onEjecutarActividad: _ejecutarActividadPlan,
              ),
            ),
            TarjetaConsulta(
              icon: Icons.event_available_outlined,
              iconColor: ac.teal,
              titulo: 'Tratamientos pendientes del plan',
              subtitulo:
                  'Puedes registrarlos aquí o agregar cualquier tratamiento '
                  'directamente desde una pieza',
              accion: IconButton(
                tooltip: 'Actualizar con lo aceptado o agendado ahora mismo',
                onPressed: _cargandoPlanDelDia
                    ? null
                    : () => _cargarItemsEjecutables(consulta.pacienteId),
                icon: Icon(Icons.refresh_rounded, color: ac.teal, size: 20),
              ),
              child: _cargandoPlanDelDia
                  ? const LinearProgressIndicator()
                  : _errorPlanDelDia != null
                  ? Text(
                      _errorPlanDelDia!,
                      style: TextStyle(color: ac.red, height: 1.4),
                    )
                  : _itemsEjecutables.isEmpty
                  ? Text(
                      'No hay tratamientos aceptados pendientes.',
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
                                            (d) => d.fdiCode == item.fdiDiente,
                                          );
                                      _registrarItemPlan(diente, item);
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _abrirFormularioFormalReceta(consulta),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text(
                  'Abrir Formulario Formal / Vista Previa Receta',
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(height: 16),
            SeccionInsumos(insumos: consulta.insumosUtilizados),

            _TerminarButton(
              cargando: cargando,
              label: 'Terminar consulta',
              // El servidor rechaza el cierre con alertas sin resolver; aquí se
              // dice antes y se explica cuántas faltan.
              bloqueo: consulta.alertasBloqueantes.isEmpty
                  ? null
                  : 'Resuelve ${consulta.alertasBloqueantes.length} alerta(s) '
                        'clínica(s) antes de cerrar la consulta.',
              onTap: cargando || consulta.alertasBloqueantes.isNotEmpty
                  ? null
                  : () => context.read<ConsultaCubit>().terminarAtencion(),
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
    this.bloqueo,
  });
  final bool cargando;
  final VoidCallback? onTap;
  final AppColors ac;
  final String label;

  /// Por qué no se puede cerrar todavía. Un botón apagado sin explicación es
  /// lo que obliga a adivinar.
  final String? bloqueo;

  @override
  Widget build(BuildContext context) {
    if (bloqueo case final motivo?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: ac.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ac.red.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 17, color: ac.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    motivo,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: ac.red,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _boton(),
        ],
      );
    }
    return _boton();
  }

  Widget _boton() {
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

/// Aviso que no se va solo.
///
/// El chip del encabezado dice en qué punto está el guardado, pero cabe en dos
/// palabras y vive lejos de donde se escribe. Cuando el servidor rechaza el
/// trabajo clínico, el motivo se queda aquí —con la acción que lo resuelve—
/// hasta que el guardado vuelva a confirmarse. Un snackbar de tres segundos
/// para un diagnóstico que no se guardó es como no avisar.
class _AvisoPersistencia extends StatelessWidget {
  const _AvisoPersistencia({
    required this.estado,
    required this.detalle,
    required this.onReintentar,
    required this.onRecargar,
  });

  final EstadoGuardado estado;
  final String? detalle;
  final VoidCallback onReintentar;
  final VoidCallback? onRecargar;

  static const claveFallo = ValueKey('aviso-persistencia');

  @override
  Widget build(BuildContext context) {
    if (estado != EstadoGuardado.fallido && estado != EstadoGuardado.conflicto) {
      return const SizedBox.shrink();
    }

    final ac = context.appColors;
    final esConflicto = estado == EstadoGuardado.conflicto;
    final titulo = esConflicto
        ? 'Otra sesión guardó esta consulta primero'
        : 'No se pudo guardar el trabajo de esta consulta';
    final cuerpo =
        detalle ??
        (esConflicto
            ? 'Recarga para ver lo confirmado antes de volver a guardar. Lo '
                  'que escribiste sigue en pantalla.'
            : 'Los cambios siguen en pantalla. No cierres la consulta hasta '
                  'que el guardado se confirme.');

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: claveFallo,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ac.red.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ac.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono además del color: el rojo por sí solo no comunica.
                Icon(
                  esConflicto
                      ? Icons.sync_problem_rounded
                      : Icons.cloud_off_rounded,
                  size: 18,
                  color: ac.red,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ac.red,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                cuerpo,
                style: TextStyle(
                  fontSize: 12.5,
                  color: ac.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Wrap(
                spacing: 8,
                children: [
                  if (esConflicto && onRecargar != null)
                    TextButton.icon(
                      onPressed: onRecargar,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Recargar lo confirmado'),
                    ),
                  TextButton.icon(
                    onPressed: onReintentar,
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Reintentar ahora'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      EstadoGuardado.conflicto => (
        ac.red,
        Icons.sync_problem_rounded,
        'Cambió en otra sesión',
      ),
    };

    return Tooltip(
      message: switch (estado) {
        EstadoGuardado.alDia =>
          'Todo el trabajo de esta consulta está en el servidor.',
        EstadoGuardado.pendiente =>
          'Hay cambios que se guardarán solos en unos segundos.',
        EstadoGuardado.guardando => 'Escribiendo los cambios en el servidor.',
        EstadoGuardado.fallido =>
          'Los cambios siguen aquí y se reintentará solo. No cierres la consulta.',
        EstadoGuardado.conflicto =>
          'Otra sesión guardó esta consulta primero. Recárgala para ver lo '
              'confirmado antes de volver a guardar; tus cambios siguen aquí.',
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
