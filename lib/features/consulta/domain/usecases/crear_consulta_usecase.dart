import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/dientes_iniciales.dart';
import 'package:salud_dental_clinic_management/features/diente/domain/entities/diente.dart';
import 'package:salud_dental_clinic_management/features/odontograma/domain/entities/odontograma.dart';
import 'package:salud_dental_clinic_management/features/superficie/domain/entities/superficie.dart';

/// Facade que crea, en una sola operación transaccional, la consulta junto a
/// su odontograma inicializado: las 52 piezas FDI (permanentes y temporales)
/// cada una con sus
/// superficies. La atomicidad la garantiza el RPC en la base de datos, de modo
/// que un fallo (p. ej. pérdida de conexión) no deja registros huérfanos.
class CrearConsultaUseCase {
  final ConsultaRepository _repository;

  CrearConsultaUseCase(this._repository);

  /// Devuelve el id de la consulta creada.
  Future<String> call(Consulta consulta) async {
    // Los IDs reales (odontograma_id, diente_id, consulta_id) los asigna la
    // base de datos dentro del RPC; aquí solo describimos la estructura.
    final odontograma = Odontograma(
      consultaId: '',
      dientes: kFdiTodas.map((fdi) {
        return Diente(
          odontogramaId: '',
          fdiCode: fdi,
          superficies: superficiesParaFdi(fdi)
              .map((tipo) => Superficie(dienteId: '', tipoSuperficie: tipo))
              .toList(),
        );
      }).toList(),
    );

    final completa = consulta.copyWith(odontograma: odontograma);
    return _repository.crearConsultaCompleta(completa);
  }
}
