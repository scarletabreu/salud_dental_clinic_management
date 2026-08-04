import 'package:flutter/material.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/contraindicacion.dart';

class ContraindicacionPicker extends StatelessWidget {
  final AppColors ac;
  final List<Contraindicacion> items;
  final void Function(List<Contraindicacion>) onChanged;
  final Future<Contraindicacion?> Function() onCreate;

  const ContraindicacionPicker({
    super.key,
    required this.ac,
    required this.items,
    required this.onChanged,
    required this.onCreate,
  });

  void _add(BuildContext context) async {
    final result = await onCreate();
    if (result == null) return;

    final updated = List<Contraindicacion>.from(items)..add(result);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _add(context),
              icon: Icon(Icons.add, color: ac.primaryGreen),
              label: const Text('Agregar'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (items.isEmpty)
          Text('Sin contraindicaciones', style: TextStyle(color: ac.textMuted))
        else
          Column(
            children: items.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ac.bgPage,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ac.divider),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.descripcion,
                        style: TextStyle(color: ac.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: ac.red),
                      onPressed: () {
                        final updated = List<Contraindicacion>.from(items)
                          ..remove(c);
                        onChanged(updated);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
