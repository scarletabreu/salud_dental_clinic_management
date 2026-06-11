import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/enums/tipo_contraindicacion.dart';

class ContraindicacionesCard extends StatelessWidget {
  final List<Contraindicacion> contraindicaciones;

  const ContraindicacionesCard({super.key, required this.contraindicaciones});

  @override
  Widget build(BuildContext context) {
    final ac = context.appColors;

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
                  color: ac.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.block_rounded, size: 15, color: ac.red),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Contraindicaciones',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ac.textPrimary,
                  ),
                ),
              ),
              if (contraindicaciones.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ac.red.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${contraindicaciones.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ac.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (contraindicaciones.isEmpty)
            Text(
              'Ninguna registrada',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: ac.textMuted,
              ),
            )
          else
            Column(
              children: contraindicaciones.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: i < contraindicaciones.length - 1 ? 8 : 0,
                  ),
                  child: _ContraindicacionItem(ac: ac, contraindicacion: c),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ContraindicacionItem extends StatelessWidget {
  final AppColors ac;
  final Contraindicacion contraindicacion;

  const _ContraindicacionItem({
    required this.ac,
    required this.contraindicacion,
  });

  @override
  Widget build(BuildContext context) {
    final isAbsoluta =
        contraindicacion.tipoContraindicacion == TipoContraindicacion.absoluta;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ac.bgPage,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ac.red.withOpacity(0.20), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isAbsoluta ? ac.red : ac.red.withOpacity(0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              contraindicacion.tipoContraindicacion.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contraindicacion.descripcion,
                  style: TextStyle(fontSize: 12, color: ac.textPrimary),
                ),
                if (contraindicacion.efectosAdversos.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: contraindicacion.efectosAdversos
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ac.red.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: ac.red.withOpacity(0.22),
                              ),
                            ),
                            child: Text(
                              e.name,
                              style: TextStyle(fontSize: 10, color: ac.red),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
