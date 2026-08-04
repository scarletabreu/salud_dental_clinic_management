import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/repositories/regla_clinica_repository.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_cubit.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/presentation/cubit/reglas_clinicas_state.dart';

import '../../support/senales_de_prueba.dart';

/// MU-5 · La versión de una regla publicada por otro admin llega sola a la
/// pantalla de configuración. Los umbrales que la BD impone en cada
/// escritura no dependen de esto: los triggers leen `reglas_clinicas` al
/// guardar, así que un cambio ya aplica a la siguiente consulta de todas las
/// sesiones.

class _ReglaRepoFalso extends Fake implements ReglaClinicaRepository {
  int lecturas = 0;

  @override
  Future<List<ReglaClinica>> getReglasVigentes() async {
    lecturas++;
    return const [];
  }

  @override
  Future<List<SignoVitalCatalogo>> getCatalogoSignosVitales() async =>
      const [];
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  test('la señal de reglas recarga la pantalla de configuración', () async {
    final repo = _ReglaRepoFalso();
    final fabrica = FabricaCanalesFalsa();
    final cubit = ReglasClinicasCubit(
      repo,
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );

    await cubit.cargar();
    expect(cubit.state, isA<ReglasClinicasCargadas>());
    expect(repo.lecturas, 1);

    fabrica.cambios['reglas_clinicas']!();
    await _asentar();

    expect(repo.lecturas, 2, reason: 'la publicación ajena obliga a releer');
    expect(cubit.state, isA<ReglasClinicasCargadas>());

    await cubit.close();
  });

  test('sin pantalla cargada la señal no dispara lecturas', () async {
    final repo = _ReglaRepoFalso();
    final fabrica = FabricaCanalesFalsa();
    final cubit = ReglasClinicasCubit(
      repo,
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );

    fabrica.cambios['reglas_clinicas']!();
    await _asentar();

    expect(repo.lecturas, 0);
    await cubit.close();
  });
}
