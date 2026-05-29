import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/design_tokens.dart';
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
  const PacienteDetailPage({super.key, required this.pacienteId});

  @override
  State<PacienteDetailPage> createState() => _PacienteDetailPageState();
}

class _PacienteDetailPageState extends State<PacienteDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<PacienteCubit>().loadById(widget.pacienteId);
  }

  // ── Helpers ──────────────────────────────────

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

  String _monthAbbr(int m) =>
      const ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'][m - 1];

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kTextPrimary,
        title: const Text(
          'Expediente Clínico',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<PacienteCubit, PacienteState>(
        builder: (context, state) {
          if (state is PacienteDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kTeal, strokeWidth: 2),
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
    final sorted = [...p.record.consultas]..sort((a, b) => b.fecha.compareTo(a.fecha));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIdentityCard(p),
          const SizedBox(height: 16),
          _buildAlertasMedicas(p.record),
          _buildContactoCard(p),
          const SizedBox(height: 16),
          _buildInfoClinicaCard(p.record),
          const SizedBox(height: 16),
          OdontogramArchWidget(consultas: sorted),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [kCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PacienteFormPage(paciente: p)),
                      ).then((_) {
                        if (!mounted) return;
                        context.read<PacienteCubit>().loadById(p.id!);
                      });
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextSecondary,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Próximamente: creación de citas')),
                      );
                    },
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: const Text('Nueva Cita'),
                    style: FilledButton.styleFrom(
                      backgroundColor: kTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            p.fullName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
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
              _MetaItem(icon: Icons.cake_outlined, text: _ageFormatted(p.birthDate)),
              if (p.trabajo.isNotEmpty)
                _MetaItem(icon: Icons.work_outline_rounded, text: p.trabajo),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  2. Medical alerts card
  // ─────────────────────────────────────────────

  Widget _buildAlertasMedicas(Record record) {
    final hasCondiciones = record.condiciones.trim().isNotEmpty;
    final hasCirugias = record.cirugiasPrevias.isNotEmpty;
    if (!hasCondiciones && !hasCirugias) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [kCardShadow],
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
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: kRed.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, size: 18, color: kRed),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Alertas Médicas',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kRed,
                            ),
                          ),
                        ],
                      ),
                      // Condiciones
                      if (hasCondiciones) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'CONDICIONES / ALERGIAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: kTextMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kRed.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            record.condiciones,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kTextSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                      // Cirugías
                      if (hasCirugias) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'CIRUGÍAS PREVIAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: kTextMuted,
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
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: kRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.local_hospital_outlined,
                                        size: 12,
                                        color: kRed.withValues(alpha: 0.70),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        c,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kRed.withValues(alpha: 0.80),
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
    final phone = p.contacto.numeroTelefono.isEmpty ? '—' : p.contacto.numeroTelefono;
    final email = p.contacto.email.isEmpty ? '—' : p.contacto.email;
    final hasAddress = p.contacto.direccion.isNotEmpty;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(icon: Icons.contacts_outlined, title: 'Contacto'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _InfoCell(icon: Icons.phone_outlined, label: 'TELÉFONO', value: phone)),
              const SizedBox(width: 12),
              Expanded(child: _InfoCell(icon: Icons.email_outlined, label: 'CORREO', value: email)),
            ],
          ),
          if (hasAddress) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: kDivider),
            const SizedBox(height: 16),
            _InfoCell(
              icon: Icons.location_on_outlined,
              label: 'DIRECCIÓN',
              value: p.contacto.direccion,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  4. Clinical info card
  // ─────────────────────────────────────────────

  Widget _buildInfoClinicaCard(Record record) {
    final hasHistorial = record.historialFamiliar.trim().isNotEmpty;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
              icon: Icons.medical_information_outlined, title: 'Información Clínica'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.bloodtype_outlined,
                  iconColor: kRed,
                  label: 'TIPO DE SANGRE',
                  value: record.tipoSangre.name.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  icon: Icons.child_care_outlined,
                  iconColor: kIndigo,
                  label: 'HIJOS',
                  value: '${record.cantHijos}',
                ),
              ),
            ],
          ),
          if (hasHistorial) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: kDivider),
            const SizedBox(height: 16),
            const Text(
              'HISTORIAL FAMILIAR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: kTextMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              record.historialFamiliar,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: kTextSecondary,
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

  Widget _buildTimelineCard(List<Consulta> sorted) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionHeader(
                  icon: Icons.history_edu_outlined, title: 'Historial de Consultas'),
              const Spacer(),
              if (sorted.isNotEmpty)
                _CountChip(sorted.length),
            ],
          ),
          if (sorted.isEmpty) ...[
            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open_outlined, size: 32, color: Color(0xFFD1D5DB)),
                  SizedBox(height: 8),
                  Text(
                    'Sin consultas registradas',
                    style: TextStyle(
                      fontSize: 13,
                      color: kTextDisabled,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else ...[
            const SizedBox(height: 20),
            for (int i = 0; i < sorted.length; i++)
              _buildTimelineItem(sorted[i], i == sorted.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Consulta c, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date column
          SizedBox(
            width: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  c.fecha.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  _monthAbbr(c.fecha.month).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: kTextMuted,
                  ),
                ),
                Text(
                  '${c.fecha.year}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: kTextDisabled,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Timeline axis
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(color: kTeal, shape: BoxShape.circle),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.motivoConsulta?.isNotEmpty == true
                        ? c.motivoConsulta!
                        : 'Consulta general',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  if (c.tempCondiciones.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      c.tempCondiciones.join(' · '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (c.recetas.isNotEmpty)
                        _MiniChip(
                          label:
                              '${c.recetas.length} receta${c.recetas.length > 1 ? 's' : ''}',
                          icon: Icons.medication_outlined,
                          color: kIndigo,
                        ),
                      if (c.documentosClinicos.isNotEmpty)
                        _MiniChip(
                          label:
                              '${c.documentosClinicos.length} doc${c.documentosClinicos.length > 1 ? 's' : ''}',
                          icon: Icons.description_outlined,
                          color: kTeal,
                        ),
                      if (c.odontograma != null)
                        _MiniChip(
                          label: 'Odontograma',
                          icon: Icons.medical_services_outlined,
                          color: kAmber,
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

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [kCardShadow],
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
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kTeal.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: kTeal),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kBgPage,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: kTeal),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: kTextMuted,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kTextPrimary,
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: kBgPage,
        borderRadius: BorderRadius.all(Radius.circular(12)),
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: kTextMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kTextMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: kTextSecondary,
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
    final isEmergencia = tipo == TipoPaciente.emergencia;
    final color = isEmergencia ? kRed : kTeal;
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
    const labels = {
      Genero.masculino: 'Masculino',
      Genero.femenino: 'Femenino',
      Genero.otro: 'Otro',
      Genero.noPrefiereDecir: 'No especificado',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        borderRadius: BorderRadius.all(Radius.circular(100)),
      ),
      child: Text(
        labels[genero] ?? genero.name,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: kTextMuted,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kTeal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: kTeal),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _MiniChip({required this.label, required this.icon, required this.color});

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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: kRed),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el expediente',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kTextMuted),
            ),
          ],
        ),
      ),
    );
  }
}
