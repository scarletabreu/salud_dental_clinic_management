import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

class PanelPaciente extends StatelessWidget {
  final Paciente paciente;

  /// `true` renders the fixed-width card used beside the workspace on desktop;
  /// `false` fills whatever container it is given (a drawer on smaller
  /// viewports), where a floating card with margins would only waste space.
  final bool asSidebar;

  const PanelPaciente({
    super.key,
    required this.paciente,
    this.asSidebar = true,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final record = paciente.record;
    final telefono = paciente.contactos.isNotEmpty
        ? paciente.contactos.first.numeroTelefono
        : 'Sin teléfono';
    final condiciones = record.condiciones
        .map((c) => c.nombre)
        .where((nombre) => nombre.trim().isNotEmpty)
        .join(' · ');
    final cirugias = record.cirugiasPrevias
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final radius = asSidebar ? 20.0 : 0.0;

    return Container(
      width: asSidebar ? 300 : null,
      margin: asSidebar
          ? const EdgeInsets.fromLTRB(12, 12, 0, 12)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: asSidebar
            ? Border.all(color: ac.divider.withValues(alpha: 0.5), width: 1)
            : null,
        boxShadow: asSidebar
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _IdentityHeader(paciente: paciente, ac: ac),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _InfoGrid(
                items: [
                  _InfoItem(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: telefono,
                  ),
                  _InfoItem(
                    icon: Icons.cake_outlined,
                    label: 'Edad',
                    value: '${paciente.age} años',
                  ),
                  _InfoItem(
                    icon: Icons.badge_outlined,
                    label: 'Cédula',
                    value: paciente.govID,
                    mono: true,
                  ),
                  _InfoItem(
                    icon: Icons.bloodtype_outlined,
                    label: 'Tipo de sangre',
                    value: record.bloodType,
                    highlight: true,
                    highlightColor: ac.red,
                  ),
                ],
                ac: ac,
              ),
            ),

            Divider(height: 1, color: ac.divider),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Alertas clínicas', ac: ac),
                  const SizedBox(height: 10),
                  _AlertaCard(condiciones: condiciones, ac: ac),
                  if (cirugias.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MedicalBlock(
                      icon: Icons.cut_outlined,
                      iconColor: ac.indigo,
                      title: 'Cirugías previas',
                      content: cirugias.join(' · '),
                      ac: ac,
                    ),
                  ],
                  if (record.historialFamiliar.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _MedicalBlock(
                      icon: Icons.family_restroom_outlined,
                      iconColor: ac.purple,
                      title: 'Historial familiar',
                      content: record.historialFamiliar,
                      ac: ac,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: ac.divider),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _StatsRow(consultas: record.consultas.length, ac: ac),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdentityHeader extends StatelessWidget {
  const _IdentityHeader({required this.paciente, required this.ac});
  final Paciente paciente;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final iniciales =
        '${paciente.nombre.isNotEmpty ? paciente.nombre[0] : ''}'
        '${paciente.apellido.isNotEmpty ? paciente.apellido[0] : ''}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ac.primaryGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              iniciales.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paciente.fullName,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ac.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalize(paciente.tipoPaciente.name),
                    style: TextStyle(
                      color: ac.primaryGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.highlight = false,
    this.highlightColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final bool highlight;
  final Color? highlightColor;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items, required this.ac});
  final List<_InfoItem> items;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    // The cell height has to follow the text scale: with a fixed aspect ratio
    // an accessibility text size overflows every cell at once.
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final cellHeight = (54 * textScale).clamp(54.0, 110.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 240 ? 1 : 2;
        final cellWidth = (constraints.maxWidth - 8 * (columns - 1)) / columns;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: cellWidth / cellHeight,
          children: items.map((item) => _InfoCell(item: item, ac: ac)).toList(),
        );
      },
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.item, required this.ac});
  final _InfoItem item;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final color = item.highlight
        ? (item.highlightColor ?? ac.primaryGreen)
        : ac.teal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ac.divider.withValues(alpha: 0.7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 11, color: ac.textMuted),
              const SizedBox(width: 4),
              // Etiquetas como "TIPO DE SANGRE" no caben en la celda: se
              // recortan en vez de desbordar la fila.
              Expanded(
                child: Text(
                  item.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: ac.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: item.highlight ? color : ac.textPrimary,
              fontFamily: item.mono ? 'monospace' : null,
              height: 1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  const _AlertaCard({required this.condiciones, required this.ac});
  final String condiciones;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final vacio = condiciones.isEmpty;
    final color = vacio ? ac.green : ac.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              vacio
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vacio ? 'Sin condiciones' : 'Condiciones / alergias',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vacio ? 'Paciente sin condiciones registradas.' : condiciones,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 12,
                    height: 1.4,
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

class _MedicalBlock extends StatelessWidget {
  const _MedicalBlock({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.ac,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.divider.withValues(alpha: 0.7), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ac.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 12,
                    height: 1.4,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.consultas, required this.ac});
  final int consultas;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history_rounded, size: 14, color: ac.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$consultas consulta${consultas == 1 ? '' : 's'} previas registradas',
            style: TextStyle(
              fontSize: 12,
              color: ac.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.ac});
  final String label;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: ac.textMuted,
        letterSpacing: 1.0,
      ),
    );
  }
}
