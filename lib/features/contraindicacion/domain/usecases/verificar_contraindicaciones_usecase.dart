// features/contraindicacion/domain/usecases/verificar_contraindicaciones_usecase.dart

import 'package:salud_dental_clinic_management/features/condicion/domain/entities/condicion.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/entities/conflicto.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

class VerificarContraindicacionesUseCase {
  const VerificarContraindicacionesUseCase();

  /// [condicionesPaciente] proviene de [Record.condiciones].
  /// [tratamiento] ya lleva su lista de [Contraindicacion] populada.
  List<Conflicto> call({
    required List<Condicion> condicionesPaciente,
    required Tratamiento tratamiento,
  }) {
    if (condicionesPaciente.isEmpty || tratamiento.contraindicaciones.isEmpty) {
      return const [];
    }

    // Índice por id para búsqueda O(1).
    final idsCondicionesPaciente = {
      for (final c in condicionesPaciente)
        if (c.id != null) c.id!,
    };

    final conflictos = <Conflicto>[];

    for (final ci in tratamiento.contraindicaciones) {
      if (!idsCondicionesPaciente.contains(ci.condicionId)) continue;

      // Recupera la entidad Condicion completa para poblar el Conflicto.
      final condicion = condicionesPaciente.firstWhere(
        (c) => c.id == ci.condicionId,
      );

      conflictos.add(
        Conflicto(
          condicionPaciente: condicion,
          contraindicacion: ci,
          severidad: SeveridadConflictoX.fromTipo(ci.tipoContraindicacion),
          descripcion: ci.descripcion,
        ),
      );
    }

    // Ordenar: ABSOLUTA primero, luego CRITICA, luego ADVERTENCIA.
    conflictos.sort((a, b) => b.severidad.index.compareTo(a.severidad.index));

    return conflictos;
  }

  /// Misma lógica que [call], pero para medicinas dentro de una receta.
  /// [medicina] ya lleva su lista de [Contraindicacion] populada.
  List<Conflicto> callMedicina({
    required List<Condicion> condicionesPaciente,
    required Medicina medicina,
  }) {
    if (condicionesPaciente.isEmpty || medicina.contraindicaciones.isEmpty) {
      return const [];
    }

    final idsCondicionesPaciente = {
      for (final c in condicionesPaciente)
        if (c.id != null) c.id!,
    };

    final conflictos = <Conflicto>[];

    for (final ci in medicina.contraindicaciones) {
      if (!idsCondicionesPaciente.contains(ci.condicionId)) continue;

      final condicion = condicionesPaciente.firstWhere(
        (c) => c.id == ci.condicionId,
      );

      conflictos.add(
        Conflicto(
          condicionPaciente: condicion,
          contraindicacion: ci,
          severidad: SeveridadConflictoX.fromTipo(ci.tipoContraindicacion),
          descripcion: ci.descripcion,
        ),
      );
    }

    conflictos.sort((a, b) => b.severidad.index.compareTo(a.severidad.index));

    return conflictos;
  }
}
