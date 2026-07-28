import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';

class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String sectionTitle;
  final bool compact;

  const ShellAppBar({
    super.key,
    required this.sectionTitle,
    this.compact = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(compact ? 64 : 72);

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 16,
        compact ? 8 : 12,
        compact ? 8 : 16,
        0,
      ),
      child: Material(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ac.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: compact ? 28 : 34,
                height: compact ? 28 : 34,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.local_hospital_rounded,
                    color: ac.primaryGreen,
                    size: compact ? 24 : 28,
                  );
                },
              ),
              SizedBox(width: compact ? 10 : 12),

              Expanded(
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: ac.textPrimary,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!compact) ...[const SizedBox(width: 12), const _DoctorChip()],
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorChip extends StatelessWidget {
  const _DoctorChip();

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final usuario = context.select((AuthCubit c) => c.state.usuario);

    String initials() {
      if (usuario == null) return 'JM';
      final n = usuario.nombre.isNotEmpty ? usuario.nombre[0] : '';
      final a = usuario.apellido.isNotEmpty ? usuario.apellido[0] : '';
      final s = (n + a).trim();
      return s.isNotEmpty ? s.toUpperCase() : 'JM';
    }

    final displayName = usuario != null
        ? (usuario is Doctor
              ? 'Dr. ${usuario.nombre} ${usuario.apellido}'
              : '${usuario.nombre} ${usuario.apellido}')
        : 'Usuario Clínico';

    final subtitle = usuario is Doctor
        ? usuario.specialty
        : 'Personal Operativo';

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
      decoration: BoxDecoration(
        color: ac.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: ac.divider.withValues(alpha: 0.4),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ac.textPrimary,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: ac.textMuted,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: ac.primaryGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials(),
              style: TextStyle(
                color: ac.primaryGreen,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
