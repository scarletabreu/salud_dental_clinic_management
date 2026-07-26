import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/historial_pieza.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_arch_widget.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/widgets/planes_tratamiento_card.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/widgets/condiciones_medicas_card.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/pages/resumen_financiero_paciente.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/pages/pre_factura_page.dart';
import 'package:salud_dental_clinic_management/features/record/presentation/widgets/generar_expediente_modal.dart';

enum _VistaConsultas { cronologica, lista }

class PacienteDetailPage extends StatefulWidget {
  final String pacienteId;

  const PacienteDetailPage({super.key, required this.pacienteId});

  @override
  State<PacienteDetailPage> createState() => _PacienteDetailPageState();
}

class _PacienteDetailPageState extends State<PacienteDetailPage> {
  _VistaConsultas _modoVista = _VistaConsultas.cronologica;
  bool _ordenDescendente = true;

  @override
  void initState() {
    super.initState();
    context.read<PacienteCubit>().loadById(widget.pacienteId);
  }

  String _ageFormatted(DateTime birth) {
    final now = DateTime.now();
    int years = now.year - birth.year;
    int months = now.month - birth.month;

    if (now.day < birth.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years == 0) return '$months meses';
    if (months == 0) return '$years años';
    return '$years a., $months m.';
  }

  String _monthAbbr(int m) {
    return const [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ][m - 1];
  }

  String? _getDoctorNombre(Consulta c) {
    try {
      final dynamic obj = c;
      final d = obj.doctor;
      if (d != null) {
        final nombre = d.nombre ?? '';
        final apellido = d.apellido ?? '';
        return 'Dr. $nombre $apellido'.trim();
      }
    } catch (_) {}

    try {
      final dynamic obj = c;
      final name = obj.doctorNombre ?? obj.nombreDoctor;
      if (name != null && name.toString().isNotEmpty) {
        final nameStr = name.toString().trim();
        return nameStr.startsWith('Dr.') ? nameStr : 'Dr. $nameStr';
      }
    } catch (_) {}

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return BlocBuilder<PacienteCubit, PacienteState>(
      builder: (context, state) {
        final paciente = (state is PacienteDetailLoaded)
            ? state.paciente
            : null;

        final historialPiezas = (state is PacienteDetailLoaded)
            ? state.historialPiezas
            : null;

        return Scaffold(
          backgroundColor: ac.bgPage,
          appBar: AppBar(
            backgroundColor: ac.cardBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: ac.textPrimary,
            title: Text(
              'Expediente Clínico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ac.textPrimary,
              ),
            ),
            centerTitle: false,
            actions: [
              if (paciente != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    tooltip: 'Exportar / Imprimir Expediente',
                    icon: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: ac.primaryBlue,
                    ),
                    onPressed: () {
                      final consultasConOdontograma = paciente.record.consultas
                          .where((c) => c.odontograma != null)
                          .toList();

                      final odontogramaActual =
                          consultasConOdontograma.isNotEmpty
                          ? consultasConOdontograma.first.odontograma
                          : null;

                      GenerarExpedienteModal.mostrar(
                        context,
                        paciente: paciente,
                        odontogramaActual: odontogramaActual,
                        consultasConOdontograma: consultasConOdontograma,
                        historialPiezas: historialPiezas,
                      );
                    },
                  ),
                ),
            ],
          ),
          body: _buildBody(state, ac),
        );
      },
    );
  }

  Widget _buildBody(PacienteState state, AppColors ac) {
    if (state is PacienteDetailLoading) {
      return Center(
        child: CircularProgressIndicator(color: ac.primaryBlue, strokeWidth: 2),
      );
    }

    if (state is PacienteError) {
      return _ErrorView(message: state.message);
    }

    if (state is PacienteDetailLoaded) {
      return _buildContent(
        state.paciente,
        historialNoDisponible: state.historialNoDisponible,
        historialPiezas: state.historialPiezas,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildContent(
    Paciente p, {
    bool historialNoDisponible = false,
    HistorialPiezas historialPiezas = HistorialPiezas.vacio,
  }) {
    final sortedConsultas = [...p.record.consultas]
      ..sort(
        (a, b) => _ordenDescendente
            ? b.fecha.compareTo(a.fecha)
            : a.fecha.compareTo(b.fecha),
      );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIdentityCard(p),
          const SizedBox(height: 16),
          _buildAlertasMedicas(p.record),
          ResumenFinancieroPaciente(
            pacienteId: p.id ?? widget.pacienteId,
            onVerDetalle: (cuenta) {
              if (cuenta.id == null) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PreFacturaPage(cuentaId: cuenta.id!),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          CondicionesMedicasCard(pacienteId: p.id ?? widget.pacienteId),
          LayoutBuilder(
            builder: (context, constraints) {
              final contacto = _buildContactoCard(p);
              final clinica = _buildInfoClinicaCard(p);
              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [contacto, const SizedBox(height: 16), clinica],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: contacto),
                    const SizedBox(width: 16),
                    Expanded(child: clinica),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          PlanesTratamientoCard(pacienteId: p.id ?? widget.pacienteId),
          OdontogramArchWidget(
            consultas: sortedConsultas,
            historialNoDisponible: historialNoDisponible,
            historialPiezas: historialPiezas,
          ),
          const SizedBox(height: 16),
          _buildTimelineCard(sortedConsultas),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(Paciente p) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [_TipoPill(p.tipoPaciente), _GenderChip(p.genero)],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final pacienteCubit = context.read<PacienteCubit>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: pacienteCubit,
                            child: PacienteFormPage(paciente: p),
                          ),
                        ),
                      ).then((_) {
                        if (!mounted) return;
                        pacienteCubit.loadById(p.id!);
                      });
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ac.textSecondary,
                      side: BorderSide(color: ac.divider),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Para crear una cita utiliza el menú lateral "Mis Citas del Día"',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('Nueva Cita'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p.fullName,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaItem(icon: Icons.badge_outlined, text: 'Cédula: ${p.govID}'),
              _MetaItem(
                icon: Icons.cake_outlined,
                text: _ageFormatted(p.birthDate),
              ),
              if (p.trabajo.isNotEmpty)
                _MetaItem(icon: Icons.work_outline_rounded, text: p.trabajo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasMedicas(Record record) {
    final hasCondiciones = record.condiciones.isNotEmpty;
    final hasCirugias = record.cirugiasPrevias.isNotEmpty;

    if (!hasCondiciones && !hasCirugias) {
      return const SizedBox.shrink();
    }

    final ac = context.appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          boxShadow: [ac.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: ac.red.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 18,
                              color: ac.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Alertas Médicas',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ac.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (hasCondiciones) ...[
                        const SizedBox(height: 16),
                        Text(
                          'CONDICIONES / ALERGIAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: ac.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ac.red.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            record.condiciones.map((c) => c.nombre).join(', '),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: ac.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                      if (hasCirugias) ...[
                        const SizedBox(height: 16),
                        Text(
                          'CIRUGÍAS PREVIAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: ac.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: record.cirugiasPrevias
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ac.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_hospital_outlined,
                                        size: 12,
                                        color: ac.red.withValues(alpha: 0.70),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          c,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: ac.red.withValues(
                                              alpha: 0.80,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactoCard(Paciente p) {
    final ac = context.appColors;
    final contactos = p.contactos;

    if (contactos.isEmpty) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(
              icon: Icons.contacts_outlined,
              title: 'Contacto',
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'No hay contactos registrados',
                style: TextStyle(
                  fontSize: 13,
                  color: ac.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  icon: Icons.contacts_outlined,
                  title: 'Contactos',
                ),
              ),
              _CountChip(contactos.length),
            ],
          ),
          const SizedBox(height: 20),
          ...List.generate(contactos.length, (index) {
            final contacto = contactos[index];
            final phone = contacto.numeroTelefono.isEmpty
                ? '—'
                : contacto.numeroTelefono;
            final email = contacto.email.isEmpty ? '—' : contacto.email;
            final hasAddress = contacto.direccion.isNotEmpty;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == contactos.length - 1 ? 0 : 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ac.bgPage,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ac.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ac.teal.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            contacto.esEmergencia
                                ? Icons.contact_emergency_outlined
                                : Icons.person_outline_rounded,
                            size: 16,
                            color: contacto.esEmergencia ? ac.red : ac.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            contacto.esEmergencia
                                ? 'Contacto de Emergencia ${index + 1}'
                                : 'Contacto ${index + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: contacto.esEmergencia
                                  ? ac.red
                                  : ac.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCell(
                            icon: Icons.phone_outlined,
                            label: 'TELÉFONO',
                            value: phone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoCell(
                            icon: Icons.email_outlined,
                            label: 'CORREO',
                            value: email,
                          ),
                        ),
                      ],
                    ),
                    if (hasAddress) ...[
                      const SizedBox(height: 16),
                      Divider(height: 1, color: ac.divider),
                      const SizedBox(height: 16),
                      _InfoCell(
                        icon: Icons.location_on_outlined,
                        label: 'DIRECCIÓN',
                        value: contacto.direccion,
                        fullWidth: true,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoClinicaCard(Paciente p) {
    final ac = context.appColors;
    final record = p.record;
    final hasHistorial = record.historialFamiliar.trim().isNotEmpty;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon: Icons.medical_information_outlined,
            title: 'Información Clínica',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.bloodtype_outlined,
                  iconColor: ac.red,
                  label: 'TIPO DE SANGRE',
                  value: record.tipoSangre.name.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.child_care_outlined,
                  iconColor: ac.indigo,
                  label: 'HIJOS',
                  value: '${record.cantHijos}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: ac.teal,
                  label: 'PESO',
                  value: p.peso != null ? '${p.peso} kg' : '—',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.height_rounded,
                  iconColor: ac.primaryBlue,
                  label: 'ALTURA',
                  value: p.altura != null ? '${p.altura} cm' : '—',
                ),
              ),
            ],
          ),
          if (hasHistorial) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: ac.divider),
            const SizedBox(height: 16),
            Text(
              'HISTORIAL FAMILIAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: ac.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              record.historialFamiliar,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: ac.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineCard(List<Consulta> sorted) {
    final ac = context.appColors;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  icon: Icons.history_edu_outlined,
                  title: 'Historia Clínica Longitudinal',
                ),
              ),
              if (sorted.isNotEmpty) _CountChip(sorted.length),
            ],
          ),
          const SizedBox(height: 16),

          // Wrap y no Row: el conmutador de vista con sus dos etiquetas y el
          // botón de orden no caben en una línea de 320 px, y comprimirlos
          // dejaría los objetivos táctiles por debajo del mínimo (SD-130).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              SegmentedButton<_VistaConsultas>(
                segments: const [
                  ButtonSegment(
                    value: _VistaConsultas.cronologica,
                    icon: Icon(Icons.timeline_rounded, size: 16),
                    label: Text('Línea de Tiempo'),
                  ),
                  ButtonSegment(
                    value: _VistaConsultas.lista,
                    icon: Icon(Icons.format_list_bulleted_rounded, size: 16),
                    label: Text('Lista'),
                  ),
                ],
                selected: {_modoVista},
                onSelectionChanged: (val) =>
                    setState(() => _modoVista = val.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              IconButton(
                tooltip: _ordenDescendente
                    ? 'Ordenar: Más antigua primero'
                    : 'Ordenar: Más reciente primero',
                icon: Icon(
                  _ordenDescendente
                      ? Icons.sort_by_alpha_rounded
                      : Icons.history_rounded,
                  size: 20,
                  color: ac.primaryBlue,
                ),
                onPressed: () =>
                    setState(() => _ordenDescendente = !_ordenDescendente),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (sorted.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 36,
                    color: ac.textDisabled,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin consultas ni intervenciones registradas.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ac.textDisabled,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ] else if (_modoVista == _VistaConsultas.cronologica) ...[
            for (int i = 0; i < sorted.length; i++)
              _buildTimelineItem(sorted[i], i == sorted.length - 1),
          ] else ...[
            for (int i = 0; i < sorted.length; i++) _buildListItem(sorted[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Consulta c, bool isLast) {
    final ac = context.appColors;
    final notas = c.notas?.trim() ?? '';
    final hasNotas = notas.isNotEmpty;
    final docNombre = _getDoctorNombre(c);

    Widget itemCard = InkWell(
      onTap: () => _abrirDetalleConsulta(c),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ac.bgPage,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ac.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.motivoConsulta?.isNotEmpty == true
                        ? c.motivoConsulta!
                        : 'Consulta médica general',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ac.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: ac.textMuted,
                ),
              ],
            ),
            if (docNombre != null) ...[
              const SizedBox(height: 4),
              Text(
                docNombre,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ac.primaryBlue,
                ),
              ),
            ],
            if (hasNotas) ...[
              const SizedBox(height: 6),
              Text(
                notas,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: ac.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (c.recetas.isNotEmpty)
                  _MiniChip(
                    label: '${c.recetas.length} receta(s)',
                    icon: Icons.medication_outlined,
                    color: ac.indigo,
                  ),
                if (c.documentosClinicos.isNotEmpty)
                  _MiniChip(
                    label: '${c.documentosClinicos.length} doc(s)',
                    icon: Icons.description_outlined,
                    color: ac.teal,
                  ),
                if (c.odontograma != null)
                  _MiniChip(
                    label: 'Odontograma',
                    icon: Icons.medical_services_outlined,
                    color: ac.amber,
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (hasNotas) {
      itemCard = Tooltip(
        message: 'Notas: $notas',
        preferBelow: false,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ac.textPrimary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: itemCard,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  c.fecha.day.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  _monthAbbr(c.fecha.month).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: ac.textMuted,
                  ),
                ),
                Text(
                  '${c.fecha.year}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: ac.textDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ac.teal,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: ac.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: itemCard,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Consulta c) {
    final ac = context.appColors;
    final fechaStr =
        '${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}';
    final docNombre = _getDoctorNombre(c);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.divider),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _abrirDetalleConsulta(c),
        leading: CircleAvatar(
          backgroundColor: ac.teal.withValues(alpha: 0.12),
          child: Icon(
            Icons.medical_information_outlined,
            size: 20,
            color: ac.teal,
          ),
        ),
        title: Text(
          c.motivoConsulta?.isNotEmpty == true
              ? c.motivoConsulta!
              : 'Consulta Médica',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ac.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Fecha: $fechaStr ${docNombre != null ? '• $docNombre' : ''}',
              style: TextStyle(fontSize: 12, color: ac.textSecondary),
            ),
            if (c.notas?.isNotEmpty == true)
              Text(
                'Notas: ${c.notas}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: ac.textMuted),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: ac.textMuted),
      ),
    );
  }

  void _abrirDetalleConsulta(Consulta c) {
    final ac = context.appColors;
    final fechaStr =
        '${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}';
    final docNombre = _getDoctorNombre(c);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ac.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ac.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ac.primaryBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.assignment_outlined,
                      color: ac.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.motivoConsulta?.isNotEmpty == true
                              ? c.motivoConsulta!
                              : 'Detalle de Consulta',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: ac.textPrimary,
                          ),
                        ),
                        Text(
                          'Atención del $fechaStr',
                          style: TextStyle(fontSize: 12, color: ac.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: ac.divider),
              const SizedBox(height: 16),

              if (docNombre != null) ...[
                Text(
                  'PROFESIONAL RESPONSABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: ac.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  docNombre,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                'NOTAS CLÍNICAS Y OBSERVACIONES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: ac.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ac.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ac.divider),
                ),
                child: Text(
                  c.notas?.isNotEmpty == true
                      ? c.notas!
                      : 'Sin notas ni observaciones registradas para esta fecha.',
                  style: TextStyle(
                    fontSize: 13,
                    color: ac.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (c.recetas.isNotEmpty) ...[
                Text(
                  'RECETAS Y FÁRMACOS PRESCRITOS (${c.recetas.length})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: ac.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final receta in c.recetas)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ac.indigo.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ac.indigo.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 18,
                          color: ac.indigo,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            receta.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: ac.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              if (c.documentosClinicos.isNotEmpty) ...[
                Text(
                  'DOCUMENTOS Y ADJUNTOS CLINICOS (${c.documentosClinicos.length})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: ac.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                for (final doc in c.documentosClinicos)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.file_present_outlined, color: ac.teal),
                    title: Text(
                      doc.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [ac.cardShadow],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ac.teal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: ac.teal),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ac.bgPage,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: ac.teal),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: ac.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: ac.textPrimary,
                ),
                overflow: fullWidth ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: ac.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ac.textPrimary,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ac.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: ac.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _TipoPill extends StatelessWidget {
  final TipoPaciente tipo;

  const _TipoPill(this.tipo);

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final isEmergencia = tipo == TipoPaciente.emergencia;
    final color = isEmergencia ? ac.red : ac.teal;
    final label = isEmergencia ? 'EMERGENCIA' : 'INTEGRADO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final Genero genero;

  const _GenderChip(this.genero);

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    const labels = {
      Genero.masculino: 'Masculino',
      Genero.femenino: 'Femenino',
      Genero.otro: 'Otro',
      Genero.noPrefiereDecir: 'No especificado',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
      ),
      child: Text(
        labels[genero] ?? genero.name,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: ac.textMuted,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final int count;

  const _CountChip(this.count);

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ac.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ac.teal,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MiniChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: ac.red),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el expediente',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ac.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ac.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
