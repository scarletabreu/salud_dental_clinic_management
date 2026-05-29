import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_state.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/pages/paciente_form_page.dart';
import 'package:salud_dental_clinic_management/features/record/domain/entities/record.dart';

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

  String _generoLabel(String name) {
    switch (name) {
      case 'masculino':
        return 'Masculino';
      case 'femenino':
        return 'Femenino';
      case 'otro':
        return 'Otro';
      case 'noPrefiereDecir':
        return 'No prefiere decir';
      default:
        return name.isEmpty ? '—' : name[0].toUpperCase() + name.substring(1);
    }
  }

  String _getInitials(String fullName) {
    if (fullName.trim().isEmpty) return 'P';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme
          .surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        title: const Text(
          'Expediente Clínico',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<PacienteCubit, PacienteState>(
        builder: (context, state) {
          if (state is PacienteDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PacienteError) {
            return _ErrorView(message: state.message);
          }
          if (state is PacienteDetailLoaded) {
            final p = state.paciente;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, p),
                _buildStatsBar(context, p),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    children: [
                      _buildAlertasMedicas(context, p.record),
                      if (p.record.condiciones.trim().isNotEmpty ||
                          p.record.cirugiasPrevias.isNotEmpty)
                        const SizedBox(height: 16),
                      _buildDatosContacto(context, p),
                      const SizedBox(height: 16),
                      _buildInformacionClinicaBase(context, p.record),
                      const SizedBox(height: 16),
                      _buildHistorialVisitas(context, p),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Paciente p) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme
        .primary;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(p.fullName),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.fullName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: primaryColor.withAlpha(15),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        p.tipoPaciente.name.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Text(
                      'ID: ${p.govID}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withAlpha(180),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PacienteFormPage(paciente: p),
                    ),
                  ).then((_) {
                    if (!mounted) return;
                    context.read<PacienteCubit>().loadById(p.id!);
                  });
                },
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Editar'),
                style: OutlinedButton.styleFrom(
                  elevation: 0,
                  foregroundColor: colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withAlpha(120),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Próximamente: creación de citas'),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: const Text('Nueva Cita'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, Paciente p) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _DetailStatItem(label: 'EDAD', value: '${p.age} años'),
            ),
            _buildStatDivider(colorScheme),
            Expanded(
              child: _DetailStatItem(
                label: 'GÉNERO',
                value: _generoLabel(p.genero.name),
              ),
            ),
            if (p.trabajo.isNotEmpty) ...[
              _buildStatDivider(colorScheme),
              Expanded(
                flex: 2,
                child: _DetailStatItem(
                  label: 'OCUPACIÓN',
                  value: p.trabajo,
                  isOmissible: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatDivider(ColorScheme colorScheme) {
    return Container(
      height: 24,
      width: 1,
      color: colorScheme.outlineVariant.withAlpha(60),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildAlertasMedicas(BuildContext context, Record record) {
    final colorScheme = Theme.of(context).colorScheme;
    final tieneCondiciones = record.condiciones.trim().isNotEmpty;
    final tieneCirugias = record.cirugiasPrevias.isNotEmpty;

    if (!tieneCondiciones && !tieneCirugias) return const SizedBox.shrink();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Alertas Médicas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          if (tieneCondiciones) ...[
            const SizedBox(height: 14),
            const _SubsectionLabel(label: 'Condiciones / Alergias'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                record.conditions.isEmpty
                    ? record.condiciones
                    : record.condiciones,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (tieneCirugias) ...[
            const SizedBox(height: 14),
            const _SubsectionLabel(label: 'Cirugías Previas'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.cirugiasPrevias
                  .map(
                    (cirugia) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: ShapeDecoration(
                        color: colorScheme.error.withAlpha(12),
                        shape: const StadiumBorder(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_hospital_outlined,
                            size: 12,
                            color: colorScheme.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cirugia,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
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
    );
  }

  Widget _buildDatosContacto(BuildContext context, Paciente p) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.contacts_outlined,
            title: 'Datos de Contacto',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: p.contacto.numeroTelefono.isEmpty
                      ? '—'
                      : p.contacto.numeroTelefono,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoItem(
                  icon: Icons.email_outlined,
                  label: 'Correo Electrónico',
                  value: p.contacto.email.isEmpty ? '—' : p.contacto.email,
                ),
              ),
            ],
          ),
          if (p.contacto.direccion.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withAlpha(40),
            ),
            const SizedBox(height: 14),
            _InfoItem(
              icon: Icons.location_on_outlined,
              label: 'Dirección Residencia',
              value: p.contacto.direccion,
              fullWidth: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInformacionClinicaBase(BuildContext context, Record record) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.medical_information_outlined,
            title: 'Información Clínica',
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.bloodtype_outlined,
                  iconColor: colorScheme.error,
                  iconBg: colorScheme.errorContainer.withAlpha(40),
                  label: 'Tipo de Sangre',
                  value: record.tipoSangre.name.toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.child_care_outlined,
                  iconColor: colorScheme.tertiary,
                  iconBg: colorScheme.tertiaryContainer.withAlpha(40),
                  label: 'Cantidad de Hijos',
                  value: '${record.cantHijos}',
                ),
              ),
            ],
          ),
          if (record.historialFamiliar.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            const _SubsectionLabel(label: 'Historial Familiar'),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withAlpha(40),
                ),
              ),
              child: Text(
                record.historialFamiliar,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorialVisitas(BuildContext context, Paciente p) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.history_edu_outlined,
            title: 'Historial Clínico',
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_outlined,
                      size: 32,
                      color: colorScheme.onSurfaceVariant.withAlpha(120),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin procedimientos registrados',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los procedimientos aparecerán aquí una vez registrados.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(140),
                    ),
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

class _DetailStatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isOmissible;

  const _DetailStatItem({
    required this.label,
    required this.value,
    this.isOmissible = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withAlpha(160),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          overflow: isOmissible ? TextOverflow.ellipsis : null,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  final String label;
  const _SubsectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: colorScheme.onSurfaceVariant.withAlpha(160),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.onSurfaceVariant.withAlpha(140),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withAlpha(160),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withAlpha(160),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar paciente',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
