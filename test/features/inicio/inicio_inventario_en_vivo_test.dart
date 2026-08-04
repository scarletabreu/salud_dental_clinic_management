import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/entities/cita.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/entities/consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/enums/estado_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_state.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';

import '../../support/senales_de_prueba.dart';

/// MU-4 · La alerta de stock bajo salta en el Inicio cuando el consumo del
/// día cruza el umbral, sin que nadie navegue a Inventario.

Consumible _consumible(int stock) => Consumible(
  id: 'con-1',
  nombre: 'Anestesia',
  descripcion: '',
  precio: 900,
  stockActual: stock,
  stockMinimo: 2,
  estado: EstadoConsumible.disponible,
);

class _CitaRepoFalso extends Fake implements CitaRepository {
  @override
  Future<List<Cita>> getCitas({DateTime? desde, DateTime? hasta}) async =>
      const [];
}

class _PacienteRepoFalso extends Fake implements IPacienteRepository {
  @override
  Future<Either<Failure, List<Paciente>>> getPacientes() async =>
      const Right([]);
}

class _MedicinaRepoFalso extends Fake implements IMedicinaRepository {}

class _ConsumibleRepoFalso extends Fake implements ConsumibleRepository {
  List<Consumible> inventario = [];

  @override
  Future<List<Consumible>> getInventario() async => List.of(inventario);
}

class _CajaRepoFalso extends Fake implements CajaDiariaRepository {
  @override
  Future<CajaDiaria?> getCajaActual() async => CajaDiaria(
    id: 'caja-1',
    fecha: DateTime.now(),
    montoApertura: 5000,
    montoCierre: 0,
    montoEsperado: 5000,
    montoReal: 0,
  );
}

class _EquipoRepoFalso extends Fake implements EquipoRepository {
  @override
  Future<List<Equipo>> getInventarioEquipos() async => const [];
}

Future<void> _asentar() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  test('el consumo ajeno dispara la alerta de stock bajo en el Inicio',
      () async {
    final consumibles = _ConsumibleRepoFalso()
      ..inventario = [_consumible(5)];
    final fabrica = FabricaCanalesFalsa();
    final cubit = DashboardCubit(
      citaRepository: _CitaRepoFalso(),
      pacienteRepository: _PacienteRepoFalso(),
      medicinaRepository: _MedicinaRepoFalso(),
      consumibleRepository: consumibles,
      cajaDiariaRepository: _CajaRepoFalso(),
      equipoRepository: _EquipoRepoFalso(),
      senales: SenalesRealtime(fabrica: fabrica, debounce: Duration.zero),
    );

    await cubit.load(roles: const [RolUsuario.asistente]);
    var estado = cubit.state as DashboardLoaded;
    expect(estado.consumiblesBajoStock, 0);
    expect(
      estado.alertas.where((a) => a.titulo.contains('stock bajo')),
      isEmpty,
    );

    // El doctor finaliza una consulta que consume casi todo el frasco.
    consumibles.inventario = [_consumible(1)];
    fabrica.cambios['consumibles']!();
    await _asentar();

    estado = cubit.state as DashboardLoaded;
    expect(estado.consumiblesBajoStock, 1);
    expect(
      estado.alertas.where((a) => a.titulo.contains('stock bajo')),
      isNotEmpty,
      reason: 'la alerta debe saltar sin navegar a Inventario',
    );

    await cubit.close();
  });
}
