import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_state.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/capacidades_sesion.dart';

/// Muestra [child] sólo si la sesión tiene la capacidad indicada.
///
/// Nace de la jornada de QA del 1 ago 2026: **ninguna pantalla de catálogo
/// consultaba capacidad alguna** y los botones Nuevo/Editar/Eliminar se
/// pintaban siempre, para cualquier rol (defecto D8). Envolver es menos
/// invasivo que repartir un `context.select` por cada pantalla, y deja escrito
/// en el árbol de widgets por qué ese botón puede no estar.
///
/// Ocultar no es la defensa: la RLS rechaza la escritura igual. Esto evita
/// ofrecer algo que va a fallar.
class SoloSiPuede extends StatelessWidget {
  const SoloSiPuede({
    super.key,
    required this.capacidad,
    required this.child,
    this.alternativa,
  });

  /// Se resuelve contra el estado de la sesión.
  final bool Function(AuthState estado) capacidad;

  final Widget child;

  /// Qué pintar cuando no se tiene la capacidad. Por defecto, nada.
  final Widget? alternativa;

  /// Editar el catálogo clínico: crear, modificar y retirar tratamientos,
  /// diagnósticos, procedimientos y medicinas. Sólo administración.
  factory SoloSiPuede.editarCatalogos({
    Key? key,
    required Widget child,
    Widget? alternativa,
  }) => SoloSiPuede(
    key: key,
    capacidad: (estado) => estado.puedeEditarCatalogosClinicos,
    child: child,
    alternativa: alternativa,
  );

  /// Ver lo que cuesta un tratamiento.
  factory SoloSiPuede.verPrecios({
    Key? key,
    required Widget child,
    Widget? alternativa,
  }) => SoloSiPuede(
    key: key,
    capacidad: (estado) => estado.puedeVerPreciosTratamiento,
    child: child,
    alternativa: alternativa,
  );

  @override
  Widget build(BuildContext context) {
    final permitido = context.select(
      (AuthCubit cubit) => capacidad(cubit.state),
    );
    if (permitido) return child;
    return alternativa ?? const SizedBox.shrink();
  }
}
