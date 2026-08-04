import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';

class GetInventarioEquiposUseCase {
  final EquipoRepository repository;

  GetInventarioEquiposUseCase({required this.repository});

  Future<List<Equipo>> call() => repository.getInventarioEquipos();
}
