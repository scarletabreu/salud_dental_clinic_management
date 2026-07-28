import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/enums/estado_cita.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit_state.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/core/di/service_locator.dart';
import 'package:salud_dental_clinic_management/core/presentation/responsive_widgets.dart';

class CitaEditPage extends StatefulWidget {
  final Cita cita;
  const CitaEditPage({super.key, required this.cita});

  @override
  State<CitaEditPage> createState() => _CitaEditPageState();
}

class _CitaEditPageState extends State<CitaEditPage> {
  final _formKey = GlobalKey<FormState>();

  List<Doctor> _doctores = [];
  bool _cargandoDoctores = false;
  bool _intentandoGuardar = false;

  Doctor? _doctorSeleccionado;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  bool _esEmergencia = false;
  int _duracionMinutos = 30;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.cita.date.toLocal();
    _horaSeleccionada = TimeOfDay.fromDateTime(widget.cita.date.toLocal());
    _esEmergencia = widget.cita.esEmergencia;
    _duracionMinutos = widget.cita.duracionMinutos;
    _cargarDoctores();
  }

  Future<void> _cargarDoctores() async {
    setState(() => _cargandoDoctores = true);
    try {
      final lista = await sl<DoctorRepository>().getDoctores();
      setState(() {
        _doctores = lista;
        _doctorSeleccionado = lista.firstWhere(
          (d) => d.id == widget.cita.doctor.id,
          orElse: () => lista.isNotEmpty ? lista.first : widget.cita.doctor,
        );
      });
    } catch (_) {
      setState(() => _doctorSeleccionado = widget.cita.doctor);
    } finally {
      setState(() => _cargandoDoctores = false);
    }
  }

  Future<void> _seleccionarFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (_fechaSeleccionada ?? hoy).isBefore(hoy)
          ? hoy
          : (_fechaSeleccionada ?? hoy),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fechaSeleccionada = picked);
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _horaSeleccionada = picked);
  }

  void _guardarCita() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_fechaSeleccionada == null || _horaSeleccionada == null) return;

    final fechaHoraFinal = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );

    if (fechaHoraFinal.isBefore(DateTime.now())) {
      _snackError('No se puede reprogramar a una fecha u hora pasada.');
      return;
    }
    if (_doctorSeleccionado == null) {
      _snackError('Por favor, asigne un odontólogo operativo.');
      return;
    }

    setState(() => _intentandoGuardar = true);
    context.read<CitaCubit>().actualizarCita(
      widget.cita.copyWith(
        doctor: _doctorSeleccionado,
        date: fechaHoraFinal.toUtc(),
        duracionMinutos: _duracionMinutos,
        esEmergencia: _esEmergencia,
      ),
    );
  }

  void _cancelarCita() {
    setState(() => _intentandoGuardar = true);

    context.read<CitaCubit>().actualizarCita(
      widget.cita.copyWith(estado: EstadoCita.cancelada),
    );
  }

  void _snackError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Scaffold(
      backgroundColor: ac.bgPage,
      appBar: AppBar(
        backgroundColor: ac.cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: ac.textPrimary,
        title: Text(
          'Reprogramar cita',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ac.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocListener<CitaCubit, CitaCubitState>(
        listenWhen: (prev, curr) {
          if (prev is CitaCubitLoaded && curr is CitaCubitLoaded) {
            return prev.isSubmitting != curr.isSubmitting ||
                prev.errorMessage != curr.errorMessage;
          }
          return true;
        },
        listener: (listenerContext, state) {
          if (state is CitaCubitLoaded) {
            if (state.errorMessage != null) {
              _snackError(state.errorMessage!);
              setState(() => _intentandoGuardar = false);
            } else if (!state.isSubmitting && _intentandoGuardar) {
              _intentandoGuardar = false;

              if (!mounted) return;

              Navigator.of(listenerContext).pop();

              ScaffoldMessenger.of(listenerContext).showSnackBar(
                SnackBar(
                  content: const Text('Cita actualizada con éxito.'),
                  backgroundColor: listenerContext.appColors.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: BlocBuilder<CitaCubit, CitaCubitState>(
          builder: (context, state) {
            final isSubmitting = state is CitaCubitLoaded && state.isSubmitting;
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPacienteCard(ac),
                    const SizedBox(height: 16),
                    _buildDoctorCard(ac, isSubmitting),
                    const SizedBox(height: 16),
                    _buildFechaHoraCard(ac, isSubmitting),
                    const SizedBox(height: 16),
                    _buildParametrosCard(ac, isSubmitting),
                    const SizedBox(height: 16),
                    _buildEmergenciaCard(ac, isSubmitting),
                    const SizedBox(height: 24),
                    _buildBotones(ac, isSubmitting),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPacienteCard(AppColors ac) {
    final initials = widget.cita.persona.fullName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [ac.cardShadow],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ac.primaryGreen.withOpacity(0.10),
            child: Text(
              initials,
              style: TextStyle(
                color: ac.primaryGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cita.persona.fullName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${widget.cita.id ?? "N/A"}',
                  style: TextStyle(
                    fontSize: 11,
                    color: ac.textMuted,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          _StatusPill(estado: widget.cita.estado, ac: ac),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(AppColors ac, bool isSubmitting) {
    return _EditCard(
      ac: ac,
      iconColor: ac.teal,
      icon: Icons.medical_services_outlined,
      title: 'Odontólogo asignado',
      child: _cargandoDoctores
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  color: ac.primaryGreen,
                  strokeWidth: 2,
                ),
              ),
            )
          : _FieldGroup(
              ac: ac,
              icon: Icons.person_search_rounded,
              label: 'Doctor',
              child: DropdownButtonFormField<Doctor>(
                initialValue: _doctores.contains(_doctorSeleccionado)
                    ? _doctorSeleccionado
                    : null,
                decoration: _dropDecoration(ac),
                items: _doctores
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text('Dr. ${d.nombre} ${d.apellido}'),
                      ),
                    )
                    .toList(),
                onChanged: isSubmitting
                    ? null
                    : (v) => setState(() => _doctorSeleccionado = v),
                validator: (v) => v == null ? 'Seleccione un odontólogo' : null,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ac.textPrimary,
                ),
              ),
            ),
    );
  }

  Widget _buildFechaHoraCard(AppColors ac, bool isSubmitting) {
    final fechaLabel = _fechaSeleccionada == null
        ? 'Seleccionar'
        : '${_fechaSeleccionada!.day.toString().padLeft(2, '0')}/'
              '${_fechaSeleccionada!.month.toString().padLeft(2, '0')}/'
              '${_fechaSeleccionada!.year}';

    final horaLabel = _horaSeleccionada == null
        ? 'Seleccionar'
        : _horaSeleccionada!.format(context);

    return _EditCard(
      ac: ac,
      iconColor: ac.primaryGreen,
      icon: Icons.calendar_today_outlined,
      title: 'Fecha y hora',
      child: AppFormRow(
        children: [
          _FieldGroup(
            ac: ac,
            icon: Icons.calendar_month_outlined,
            label: 'Fecha',
            child: _TapField(
              ac: ac,
              icon: Icons.calendar_month_rounded,
              label: fechaLabel,
              hasValue: _fechaSeleccionada != null,
              onTap: isSubmitting ? null : _seleccionarFecha,
            ),
          ),
          _FieldGroup(
            ac: ac,
            icon: Icons.access_time_rounded,
            label: 'Hora',
            child: _TapField(
              ac: ac,
              icon: Icons.access_time_filled_rounded,
              label: horaLabel,
              hasValue: _horaSeleccionada != null,
              onTap: isSubmitting ? null : _seleccionarHora,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametrosCard(AppColors ac, bool isSubmitting) {
    return _EditCard(
      ac: ac,
      iconColor: ac.teal,
      icon: Icons.tune_rounded,
      title: 'Parámetros',
      child: Column(
        children: [
          _FieldGroup(
            ac: ac,
            icon: Icons.hourglass_bottom_rounded,
            label: 'Duración estimada',
            child: DropdownButtonFormField<int>(
              initialValue: _duracionMinutos,
              decoration: _dropDecoration(ac),
              items: const [
                DropdownMenuItem(value: 15, child: Text('15 minutos')),
                DropdownMenuItem(value: 30, child: Text('30 minutos')),
                DropdownMenuItem(value: 45, child: Text('45 minutos')),
                DropdownMenuItem(value: 60, child: Text('1 hora')),
              ],
              onChanged: isSubmitting
                  ? null
                  : (v) => setState(() => _duracionMinutos = v ?? 30),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: ac.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildEmergenciaCard(AppColors ac, bool isSubmitting) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _esEmergencia ? ac.red.withOpacity(0.06) : ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _esEmergencia ? ac.red.withOpacity(0.30) : ac.divider,
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ac.red.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.warning_amber_rounded, size: 18, color: ac.red),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergencia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _esEmergencia ? ac.red : ac.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prioridad máxima en la agenda clínica',
                  style: TextStyle(
                    fontSize: 11,
                    color: ac.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: _esEmergencia,
            onChanged: isSubmitting
                ? null
                : (v) => setState(() => _esEmergencia = v),
            activeThumbColor: ac.red,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCancelarCita() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar cita'),
          content: const Text(
            '¿Está seguro de que desea cancelar esta cita? '
            'Esta acción no debería realizarse accidentalmente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Cancelar cita'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      _cancelarCita();
    }
  }

  Widget _buildBotones(AppColors ac, bool isSubmitting) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSubmitting ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: ac.textSecondary,
              side: BorderSide(color: ac.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Cerrar'),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : _confirmarCancelarCita,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text(
              'Cancelar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ac.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: isSubmitting ? null : _guardarCita,
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text(
              'Guardar cambios',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: ac.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropDecoration(AppColors ac) => InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: ac.divider),
    ),
    filled: true,
    fillColor: ac.bgPage,
  );
}

class _EditCard extends StatelessWidget {
  final AppColors ac;
  final Color iconColor;
  final IconData icon;
  final String title;
  final Widget child;

  const _EditCard({
    required this.ac,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ac.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  final AppColors ac;
  final IconData icon;
  final String label;
  final Widget child;

  const _FieldGroup({
    required this.ac,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: ac.primaryGreen),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: ac.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _TapField extends StatelessWidget {
  final AppColors ac;
  final IconData icon;
  final String label;
  final bool hasValue;
  final VoidCallback? onTap;

  const _TapField({
    required this.ac,
    required this.icon,
    required this.label,
    required this.hasValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: ac.bgPage,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ac.divider),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: hasValue ? ac.primaryGreen : ac.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: hasValue ? ac.primaryGreen : ac.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final EstadoCita estado;
  final AppColors ac;

  const _StatusPill({required this.estado, required this.ac});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: estado.color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: estado.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            estado.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: estado.color,
            ),
          ),
        ],
      ),
    );
  }
}
