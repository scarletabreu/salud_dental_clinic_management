import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';

class DashboardQuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  const DashboardQuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: ac.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: ac.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: ac.chipBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ac.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: ac.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
