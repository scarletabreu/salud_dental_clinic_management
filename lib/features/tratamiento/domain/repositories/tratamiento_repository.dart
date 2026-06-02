import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

abstract class TratamientoRepository {
  Future<List<Tratamiento>> getCatalogoTratamientos();
  Future<void> guardarTratamiento(Tratamiento tratamiento);
  Future<void> eliminarTratamiento(String id);
}
