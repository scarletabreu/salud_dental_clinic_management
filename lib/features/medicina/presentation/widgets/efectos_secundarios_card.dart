import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';

class EfectosSecundariosCard extends StatelessWidget {
  final List<EfectoSecundario> efectos;

  const EfectosSecundariosCard({super.key, required this.efectos});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;
    const activeColor = Color(0xFFB45309);
    const activeBg = Color(0xFFFEF3C7);
    const activeBorder = Color(0xFFD97706);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ac.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ac.divider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: activeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  size: 15,
                  color: activeColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Efectos secundarios',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              if (efectos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${efectos.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (efectos.isEmpty)
            Text(
              'Ninguno registrado',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: ac.textMuted,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: efectos
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: activeBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeBorder.withOpacity(0.40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: activeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            e.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: activeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
