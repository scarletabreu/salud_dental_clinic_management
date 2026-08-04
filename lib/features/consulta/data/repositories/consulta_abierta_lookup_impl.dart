import 'package:salud_dental_clinic_management/features/cita/domain/repositories/consulta_abierta_lookup.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta_de_cita.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';

/// Adaptador que resuelve el puerto [ConsultaAbiertaLookup] con el repositorio
/// de consultas. Mantiene la dependencia en un solo sentido: el feature de
/// consulta conoce a cita, no al revés.
class ConsultaAbiertaLookupImpl implements ConsultaAbiertaLookup {
  final ConsultaRepository _consultaRepository;

  const ConsultaAbiertaLookupImpl(this._consultaRepository);

  @override
  Future<Map<String, ConsultaDeCita>> paraCitas(List<String> citaIds) =>
      _consultaRepository.getConsultasPorCitaIds(citaIds);

  @override
  Future<bool> tieneConsultaAbierta(String citaId) async {
    final porCita = await paraCitas([citaId]);
    return porCita[citaId]?.estaAbierta ?? false;
  }
}
