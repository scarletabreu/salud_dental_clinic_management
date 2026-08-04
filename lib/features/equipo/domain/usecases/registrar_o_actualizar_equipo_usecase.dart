import 'package:salud_dental_clinic_management/features/equipo/domain/entities/equipo.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/repositories/equipo_repository.dart';

class RegistrarOActualizarEquipoUseCase {
  final EquipoRepository repository;

  RegistrarOActualizarEquipoUseCase({required this.repository});

  Future<void> call(Equipo equipo) =>
      repository.registrarOActualizarEquipo(equipo);
}
