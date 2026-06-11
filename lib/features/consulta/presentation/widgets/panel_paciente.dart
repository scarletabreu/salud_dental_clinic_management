import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';

/// Panel lateral con la información clínica del paciente: identidad, contacto y
/// alertas médicas (condiciones / alergias) visibles antes de iniciar.
class PanelPaciente extends StatelessWidget {
  final Paciente paciente;

  const PanelPaciente({super.key, required this.paciente});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final record = paciente.record;
    final telefono = paciente.contactos.isNotEmpty
        ? paciente.contactos.first.numeroTelefono
        : 'Sin teléfono';
    final condiciones = record.condiciones.trim();
    final cirugias = record.cirugiasPrevias
        .where((s) => s.trim().isNotEmpty)
        .toList();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: c.cardBg,
        border: Border(right: BorderSide(color: c.divider)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(context, c),
          const SizedBox(height: 18),
          _infoRow(c, Icons.phone_outlined, 'Teléfono', telefono),
          _infoRow(c, Icons.cake_outlined, 'Edad', '${paciente.age} años'),
          _infoRow(c, Icons.badge_outlined, 'Cédula', paciente.govID),
          _infoRow(
            c,
            Icons.bloodtype_outlined,
            'Tipo de sangre',
            record.bloodType,
          ),
          const SizedBox(height: 18),
          _alertaCondiciones(c, condiciones),
          if (cirugias.isNotEmpty) ...[
            const SizedBox(height: 14),
            _bloque(c, 'Cirugías previas', cirugias.join(', ')),
          ],
          if (record.historialFamiliar.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _bloque(c, 'Historial familiar', record.historialFamiliar),
          ],
          const SizedBox(height: 14),
          _bloque(
            c,
            'Consultas previas',
            '${record.consultas.length} registradas',
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppColors c) {
    final iniciales = '${paciente.nombre.isNotEmpty ? paciente.nombre[0] : ''}'
        '${paciente.apellido.isNotEmpty ? paciente.apellido[0] : ''}';
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: c.primaryBlue.withValues(alpha: 0.12),
          child: Text(
            iniciales.toUpperCase(),
            style: TextStyle(
              color: c.primaryBlue,
              fontWeight: FontWeight.w700,
              fontSize: 18,
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
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                paciente.tipoPaciente.name,
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(AppColors c, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.textMuted),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: c.textMuted, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertaCondiciones(AppColors c, String condiciones) {
    final vacio = condiciones.isEmpty;
    final color = vacio ? c.green : c.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                vacio ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'Condiciones / alergias',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            vacio ? 'Sin condiciones registradas.' : condiciones,
            style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _bloque(AppColors c, String titulo, String valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: c.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(color: c.textPrimary, fontSize: 13, height: 1.3),
        ),
      ],
    );
  }
}
