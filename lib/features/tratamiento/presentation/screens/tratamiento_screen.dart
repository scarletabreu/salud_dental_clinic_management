import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salud_dental_clinic_management/core/presentation/app_colors.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/providers/tratamiento_provider.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/providers/tratamiento_state.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_form_dialog.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/presentation/widgets/tratamiento_card.dart';

class TratamientosScreen extends ConsumerStatefulWidget {
  const TratamientosScreen({super.key});

  @override
  ConsumerState<TratamientosScreen> createState() => _TratamientosScreenState();
}

class _TratamientosScreenState extends ConsumerState<TratamientosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(tratamientoProvider.notifier).loadTratamientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tratamientoProvider);

    ref.listen<TratamientoState>(tratamientoProvider, (previous, next) {
      if (next is TratamientoError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: context.appColors.red),
        );
      }
    });

    return Scaffold(
      body: _buildBody(state),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_tratamientos',
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
    );
  }

  Widget _buildBody(TratamientoState state) {
    if (state is TratamientoLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TratamientoLoaded) {
      final lista = state.tratamientos;
      if (lista.isEmpty) {
        return const Center(child: Text('No hay tratamientos configurados.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: lista.length,
        itemBuilder: (context, index) {
          return TratamientoCard(tratamiento: lista[index], ref: ref);
        },
      );
    }

    return const Center(child: Text('Presiona el botón para cargar.'));
  }

  void _abrirFormulario(BuildContext context, [Tratamiento? tratamiento]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TratamientoFormDialog(tratamiento: tratamiento),
    );
  }
}
