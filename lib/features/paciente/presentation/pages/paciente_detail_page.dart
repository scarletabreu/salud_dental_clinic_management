import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/odontograma/presentation/widgets/odontogram_arch_widget.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/genero.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/enums/tipo_paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';

// ─────────────────────────────────────────────
//  Page
// ─────────────────────────────────────────────

class PacienteDetailPage extends StatefulWidget {
  final String pacienteId;

  const PacienteDetailPage({
    super.key,
    required this.pacienteId,
  });

  @override
  State<PacienteDetailPage> createState() =>
      _PacienteDetailPageState();
}

class _PacienteDetailPageState
    extends State<PacienteDetailPage> {
  @override
  void initState() {
    super.initState();

    context
        .read<PacienteCubit>()
        .loadById(widget.pacienteId);
  }

  // ── Helpers ──────────────────────────────────

  String _ageFormatted(DateTime birth) {
    final now = DateTime.now();

    int years = now.year - birth.year;
    int months = now.month - birth.month;

    if (now.day < birth.day) {
      months--;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years == 0) {
      return '$months meses';
    }

    if (months == 0) {
      return '$years años';
    }

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

  // ── Build ─────────────────────────────────────

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
          'Expediente Clínico',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ac.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<PacienteCubit, PacienteState>(
        builder: (context, state) {
          if (state is PacienteDetailLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: context.appColors.primaryBlue,
                strokeWidth: 2,
              ),
            );
          }

          if (state is PacienteError) {
            return _ErrorView(message: state.message);
          }

          if (state is PacienteDetailLoaded) {
            return _buildContent(state.paciente);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(Paciente p) {
    final sorted = [...p.record.consultas]
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIdentityCard(p),
          const SizedBox(height: 16),
          _buildAlertasMedicas(p.record),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildContactoCard(p),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoClinicaCard(
                    p.record,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OdontogramArchWidget(
            consultas: sorted,
          ),
          const SizedBox(height: 16),
          _buildTimelineCard(sorted),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  1. Identity card
  // ─────────────────────────────────────────────

  Widget _buildIdentityCard(Paciente p) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.all(
          Radius.circular(20),
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TipoPill(p.tipoPaciente),
                    _GenderChip(p.genero),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      final pacienteCubit =
                          context.read<PacienteCubit>();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BlocProvider.value(
                            value: pacienteCubit,
                            child: PacienteFormPage(
                              paciente: p,
                            ),
                          ),
                        ),
                      ).then((_) {
                        if (!mounted) {
                          return;
                        }

                        pacienteCubit.loadById(
                          p.id!,
                        );
                      });
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                    ),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          ac.textSecondary,
                      side: BorderSide(
                        color: ac.divider,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      textStyle:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Próximamente: creación de citas',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Nueva Cita',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: ac.primaryBlue,
                      foregroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                      ),
                      textStyle:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
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
            crossAxisAlignment:
                WrapCrossAlignment.center,
            children: [
              _MetaItem(
                icon: Icons.badge_outlined,
                text: 'Cédula: ${p.govID}',
              ),
              _MetaItem(
                icon: Icons.cake_outlined,
                text: _ageFormatted(
                  p.birthDate,
                ),
              ),
              if (p.trabajo.isNotEmpty)
                _MetaItem(
                  icon: Icons.work_outline_rounded,
                  text: p.trabajo,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  2. Medical alerts card
  // ─────────────────────────────────────────────

  Widget _buildAlertasMedicas(
    Record record,
  ) {
    final hasCondiciones =
        record.condiciones.trim().isNotEmpty;

    final hasCirugias =
        record.cirugiasPrevias.isNotEmpty;

    if (!hasCondiciones && !hasCirugias) {
      return const SizedBox.shrink();
    }

    final ac = context.appColors;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: ac.cardBg,
          borderRadius: const BorderRadius.all(
            Radius.circular(16),
          ),
          boxShadow: [ac.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration:
                    BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration:
                                BoxDecoration(
                              color: ac.red
                                  .withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                            child: Icon(
                              Icons
                                  .warning_amber_rounded,
                              size: 18,
                              color: ac.red,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          Text(
                            'Alertas Médicas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight
                                      .w700,
                              color: ac.red,
                            ),
                          ),
                        ],
                      ),
                      if (hasCondiciones) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          'CONDICIONES / ALERGIAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w700,
                            letterSpacing:
                                1.0,
                            color:
                                ac.textMuted,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(12),
                          decoration:
                              BoxDecoration(
                            color: ac.red
                                .withValues(
                              alpha: 0.04,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: Text(
                            record
                                .condiciones,
                            style:
                                TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight
                                      .w500,
                              color:
                                  ac.textSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                      if (hasCirugias) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          'CIRUGÍAS PREVIAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                FontWeight
                                    .w700,
                            letterSpacing:
                                1.0,
                            color:
                                ac.textMuted,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: record
                              .cirugiasPrevias
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: ac.red.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,
                                    children: [
                                      Icon(
                                        Icons
                                            .local_hospital_outlined,
                                        size:
                                            12,
                                        color: ac.red
                                            .withValues(
                                          alpha:
                                              0.70,
                                        ),
                                      ),
                                      const SizedBox(
                                        width:
                                            5,
                                      ),
                                      Text(
                                        c,
                                        style:
                                            TextStyle(
                                          fontSize:
                                              11,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: ac.red.withValues(
                                            alpha:
                                                0.80,
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

  // ─────────────────────────────────────────────
  //  3. Contact card
  // ─────────────────────────────────────────────

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
            const _SectionHeader(
              icon: Icons.contacts_outlined,
              title: 'Contactos',
            ),
            const Spacer(),
            _CountChip(contactos.length),
          ],
        ),
        const SizedBox(height: 20),

        ...List.generate(contactos.length, (index) {
          final contacto = contactos[index];

          final phone = contacto.numeroTelefono.isEmpty
              ? '—'
              : contacto.numeroTelefono;

          final email = contacto.email.isEmpty
              ? '—'
              : contacto.email;

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
                          Icons.person_outline_rounded,
                          size: 16,
                          color: ac.teal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Contacto ${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: ac.textPrimary,
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

  // ─────────────────────────────────────────────
  //  4. Clinical info card
  // ─────────────────────────────────────────────

  Widget _buildInfoClinicaCard(
    Record record,
  ) {
    final ac = context.appColors;
    final hasHistorial =
        record.historialFamiliar
            .trim()
            .isNotEmpty;

    return _SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            icon:
                Icons.medical_information_outlined,
            title: 'Información Clínica',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon:
                      Icons.bloodtype_outlined,
                  iconColor: ac.red,
                  label: 'TIPO DE SANGRE',
                  value: record
                      .tipoSangre.name
                      .toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons
                      .child_care_outlined,
                  iconColor: ac.indigo,
                  label: 'HIJOS',
                  value:
                      '${record.cantHijos}',
                ),
              ),
            ],
          ),
          if (hasHistorial) ...[
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: ac.divider,
            ),
            const SizedBox(height: 16),
            Text(
              'HISTORIAL FAMILIAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 1.0,
                color: ac.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              record.historialFamiliar,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w400,
                color: ac.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  5. Timeline card
  // ─────────────────────────────────────────────

  Widget _buildTimelineCard(
    List<Consulta> sorted,
  ) {
    final ac = context.appColors;

    return _SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionHeader(
                icon:
                    Icons.history_edu_outlined,
                title:
                    'Historial de Consultas',
              ),
              const Spacer(),
              if (sorted.isNotEmpty) _CountChip(sorted.length),
            ],
          ),
          if (sorted.isEmpty) ...[
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 32,
                    color:
                        ac.textDisabled,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sin consultas registradas',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          ac.textDisabled,
                      fontWeight:
                          FontWeight
                              .w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            const SizedBox(height: 20),
            for (
              int i = 0;
              i < sorted.length;
              i++
            )
              _buildTimelineItem(
                sorted[i],
                i == sorted.length - 1,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    Consulta c,
    bool isLast,
  ) {
    final ac = context.appColors;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  c.fecha.day
                      .toString()
                      .padLeft(2, '0'),
                  style:
                      TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ac.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  _monthAbbr(
                    c.fecha.month,
                  ).toUpperCase(),
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing:
                        0.5,
                    color:
                        ac.textMuted,
                  ),
                ),
                Text(
                  '${c.fecha.year}',
                  style:
                      TextStyle(
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
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(
                  color: ac.teal,
                  shape:
                      BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin:
                        const EdgeInsets
                            .symmetric(
                      vertical: 4,
                    ),
                    color:
                        const Color(
                      0xFFE5E7EB,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 16,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    c.motivoConsulta
                                ?.isNotEmpty ==
                            true
                        ? c.motivoConsulta!
                        : 'Consulta general',
                    style:
                        TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight
                              .w600,
                      color:
                          ac.textPrimary,
                    ),
                  ),
                  if (c.tempCondiciones
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      c.tempCondiciones
                          .join(' · '),
                      style:
                          TextStyle(fontSize: 12, color:
                            ac.textSecondary),
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (c.recetas
                          .isNotEmpty)
                        _MiniChip(
                          label:
                              '${c.recetas.length} receta${c.recetas.length > 1 ? 's' : ''}',
                          icon: Icons.medication_outlined,
                          color: ac.indigo,
                        ),
                      if (c
                          .documentosClinicos
                          .isNotEmpty)
                        _MiniChip(
                          label: '${c.documentosClinicos.length} doc${c.documentosClinicos.length > 1 ? 's' : ''}',
                          icon: Icons
                              .description_outlined,
                          color: ac.teal,
                        ),
                      if (c.odontograma !=
                          null)
                        _MiniChip(
                          label:
                              'Odontograma',
                          icon: Icons
                              .medical_services_outlined,
                          color:
                              ac.amber,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared helper widgets
// ─────────────────────────────────────────────


class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
        boxShadow: [ac.cardShadow],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                ac.teal.withValues(alpha: 0.10),
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: ac.teal,
          ),
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ac.bgPage,
            borderRadius:
                BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: ac.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                  letterSpacing: 1.0,
                  color: ac.textMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w500,
                  color: ac.textPrimary,
                ),
                overflow: fullWidth
                    ? null
                    : TextOverflow
                        .ellipsis,
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
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 15,
              color: iconColor,
            ),
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

  const _MetaItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: ac.textMuted,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ac.textSecondary,
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
    final isEmergencia =
        tipo == TipoPaciente.emergencia;

    final color =
        isEmergencia ? ac.red : ac.teal;

    final label = isEmergencia
        ? 'EMERGENCIA'
        : 'INTEGRADO';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(100),
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
      Genero.noPrefiereDecir:
          'No especificado',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: ac.chipBg,
        borderRadius: const BorderRadius.all(
          Radius.circular(100),
        ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            ac.teal.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(100),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.10),
        borderRadius:
            BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color,
          ),
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

  const _ErrorView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: ac.red,
            ),
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
              style: TextStyle(
                fontSize: 13,
                color: ac.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}