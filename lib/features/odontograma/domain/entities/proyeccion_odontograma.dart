import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/evaluacion_odontologica.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/enums/tipo_superficie.dart';

/// Traduce la fuente normalizada de la boca al vocabulario visual del papel.
///
/// El formulario no es un segundo almacén: solo consume esta proyección. Los
/// tejidos blandos siguen viniendo de `evaluacion_clinica`, porque no cuelgan
/// de una pieza ni de un catálogo.
///
/// Solo se proyecta lo de **esta** consulta. Los antecedentes
/// (`Diente.tratamientosHistoricos`) no se dibujan: un tratamiento viejo sin
/// clave en el catálogo caía en «Otro» y estampaba un asterisco sobre cada
/// pieza con historial, indistinguible de lo anotado hoy. El historial se lee
/// en la ficha de la pieza, al tocarla.
EvaluacionOdontologica proyectarEvaluacionOdontologica(
  Odontograma odontograma,
) {
  final hallazgos = <int, List<HallazgoDental>>{};
  for (final diente in odontograma.dientes) {
    final porEstado = <EstadoClinicoDental, Set<TipoSuperficie>>{};

    void agregar(String? clave, TipoSuperficie? superficie) {
      final estado = EstadoClinicoDentalX.fromDb(clave);
      if (estado == null) return;
      final caras = porEstado.putIfAbsent(estado, () => <TipoSuperficie>{});
      if (superficie != null && estado.esPorSuperficie) caras.add(superficie);
    }

    for (final diagnostico in diente.diagnosis) {
      agregar(diagnostico.claveOdontograma, diagnostico.superficie);
    }
    for (final tratamiento in diente.tratamientos) {
      // Catálogos antiguos aún no tienen clave: se muestran como «Otro» en
      // vez de desaparecer de la otra vista mientras la clínica los clasifica.
      agregar(tratamiento.claveOdontograma ?? 'otro', tratamiento.superficie);
    }

    if (diente.estaAusente) {
      porEstado.putIfAbsent(
        EstadoClinicoDental.perdida,
        () => <TipoSuperficie>{},
      );
    }
    if (porEstado.isNotEmpty) {
      hallazgos[diente.fdiCode] = [
        for (final entry in porEstado.entries)
          HallazgoDental(estado: entry.key, superficies: entry.value),
      ];
    }
  }
  return EvaluacionOdontologica(
    hallazgos: Map.unmodifiable(hallazgos),
    tejidosBlandos: odontograma.evaluacion.tejidosBlandos,
  );
}

bool dienteEstaAusente(Diente diente) =>
    diente.estaAusente ||
    diente.diagnosis.any(
      (diagnostico) => diagnostico.claveOdontograma == 'perdida',
    );
