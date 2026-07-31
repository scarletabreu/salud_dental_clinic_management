import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/data/datasources/regla_clinica_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/data/models/regla_clinica_model.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/entities/regla_clinica.dart';
import 'package:salud_dental_clinic_management/features/regla_clinica/domain/repositories/regla_clinica_repository.dart';

class ReglaClinicaRepositoryImpl implements ReglaClinicaRepository {
  final ReglaClinicaRemoteDatasource remoteDataSource;

  ReglaClinicaRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ReglaClinica>> getReglasVigentes() {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchReglasVigentes();
      return filas.map(ReglaClinicaModel.fromJson).toList();
    }, context: 'obtener las reglas clínicas');
  }

  @override
  Future<List<SignoVitalCatalogo>> getCatalogoSignosVitales() {
    return runGuarded(() async {
      final filas = await remoteDataSource.fetchCatalogoSignosVitales();
      return filas.map(SignoVitalCatalogo.fromJson).toList();
    }, context: 'obtener el catálogo de signos vitales');
  }

  @override
  Future<ResultadoPublicacion> publicar(ReglaClinica regla, {String? nota}) {
    return runGuarded(() async {
      final resultado = await remoteDataSource.publicarRegla(
        codigo: regla.codigo,
        parametros: regla.parametros.toJson(regla.tipo),
        severidad: regla.severidad.dbValue,
        accion: regla.accion.dbValue,
        nota: nota,
      );
      return ResultadoPublicacion(
        codigo: resultado['codigo'] as String? ?? regla.codigo,
        version: (resultado['version'] as num?)?.toInt() ?? regla.version,
        sinCambios: resultado['sin_cambios'] as bool? ?? false,
      );
    }, context: 'publicar la regla clínica');
  }
}
