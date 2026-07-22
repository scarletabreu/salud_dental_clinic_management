import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

class RailUserCard extends StatelessWidget {
  final bool extended;

  const RailUserCard({super.key, required this.extended});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final usuario = context.select((AuthCubit c) => c.state.usuario);

    String initials() {
      if (usuario == null) return 'JM';
      final n = usuario.nombre.isNotEmpty ? usuario.nombre[0] : '';
      final a = usuario.apellido.isNotEmpty ? usuario.apellido[0] : '';
      final s = (n + a).trim();
      return s.isNotEmpty ? s.toUpperCase() : 'JM';
    }

    final avatar = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: ac.primaryBlue.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials(),
        style: textTheme.labelLarge?.copyWith(
          color: ac.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: -0.2,
        ),
      ),
    );

    final logoutBtn = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.read<AuthCubit>().logout(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ac.red.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.logout_rounded, size: 15, color: ac.red),
        ),
      ),
    );

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            // Opaque: the rail's destination list scrolls underneath and used
            // to show through this card.
            color: ac.cardBg,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: ac.divider.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              avatar,
              const SizedBox(height: 6),
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 4,
                endIndent: 4,
                color: ac.divider.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              logoutBtn,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ac.cardBg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: ac.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    usuario != null
                        ? (usuario is Doctor
                              ? 'Dr. ${usuario.nombre} ${usuario.apellido}'
                              : '${usuario.nombre} ${usuario.apellido}')
                        : 'Usuario',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ac.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    usuario is Doctor ? usuario.specialty : 'Personal Clínico',
                    style: TextStyle(
                      fontSize: 10,
                      color: ac.textMuted,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            logoutBtn,
          ],
        ),
      ),
    );
  }
}
