import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/entities/doctor.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';

class RailUserCard extends StatelessWidget {
  final bool extended;

  const RailUserCard({super.key, required this.extended});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final usuario = context.select((AuthCubit c) => c.state.usuario);

    String initials() {
      if (usuario == null) return 'JM';
      final n = usuario.nombre.isNotEmpty ? usuario.nombre[0] : '';
      final a = usuario.apellido.isNotEmpty ? usuario.apellido[0] : '';
      final s = (n + a).trim();
      return s.isNotEmpty ? s.toUpperCase() : 'JM';
    }

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.primary,
      child: Text(
        initials(),
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (!extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 8),
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Cerrar sesión',
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario != null
                      ? (usuario is Doctor
                          ? 'Dr. ${usuario.nombre} ${usuario.apellido}'
                          : '${usuario.nombre} ${usuario.apellido}')
                      : 'Usuario',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  usuario is Doctor
                      ? usuario.specialty
                      : '',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.logout_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
    );
  }
}