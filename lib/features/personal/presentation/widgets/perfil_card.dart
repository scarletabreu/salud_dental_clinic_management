import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';

class PerfilCard extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback? onTap;

  const PerfilCard({super.key, required this.usuario, this.onTap});

  bool get esActivo =>
      usuario.estatus.toString().toLowerCase().contains('activo');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ac = context.appColors;

    return Opacity(
      opacity: esActivo ? 1.0 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: ac.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.4),
                width: 1.1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getRolColor(
                    usuario.rol,
                    ac,
                  ).withOpacity(0.1),
                  radius: 22,
                  child: Text(
                    '${usuario.nombre[0].toUpperCase()}${usuario.apellido[0].toUpperCase()}',
                    style: TextStyle(
                      color: _getRolColor(usuario.rol, ac),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${usuario.nombre} ${usuario.apellido}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRolBadge(usuario.rol, ac),
                          if (!esActivo) ...[
                            const SizedBox(width: 6),
                            _buildInactivoBadge(ac),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '@${usuario.username}',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.7,
                              ),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: colorScheme.outlineVariant,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            usuario.govID,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolBadge(RolUsuario rol, AppColors ac) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getRolColor(rol, ac).withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        rol.label.toUpperCase(),
        style: TextStyle(
          color: _getRolColor(rol, ac),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInactivoBadge(AppColors ac) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ac.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'INACTIVO',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRolColor(RolUsuario rol, AppColors ac) {
    switch (rol) {
      case RolUsuario.admin:
        return ac.indigo;
      case RolUsuario.doctor:
        return ac.primaryBlue;
      case RolUsuario.asistente:
        return ac.teal;
    }
  }
}
