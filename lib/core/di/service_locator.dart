import 'package:get_it/get_it.dart';
import 'package:salud_dental_clinic_management/features/cuenta/data/datasources/cuenta_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/cuota/data/datasources/cuota_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/diagnosis/data/datasources/diagnosis_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/diagnostico_aplicado/data/datasources/diagnostico_aplicado_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/diente/data/datasources/diente_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/documento_clinico/data/datasources/documento_clinico_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/equipo/data/datasources/equipo_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/equipo_mantenimiento/data/datasources/equipo_mantenimiento_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/item_cuenta/data/datasources/item_cuenta_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/medicina/data/datasources/medicina_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/repositories/i_medicina_repository.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/datasources/movimiento_caja_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/datasources/odontograma_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/data/datasources/orden_medica_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/pago/data/repositories/pago_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/repositories/pago_repository.dart';
import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/tratamiento_aplicado/data/datasources/tratamiento_aplicado_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/medicina/data/datasources/medicina_remote_datasource.dart';
import '../../features/medicina/data/repositories/medicina_repository_impl.dart';
import '../../features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import '../../features/cuenta/data/repositories/cuenta_repository_impl.dart';
import '../../features/cuenta/domain/repositories/cuenta_repository.dart';
import '../../features/item_cuenta/data/datasources/item_cuenta_remote_datasource.dart';
import '../../features/item_cuenta/data/repositories/item_cuenta_repository_impl.dart';
import '../../features/item_cuenta/domain/repositories/item_cuenta_repository.dart';
import '../../features/cuota/data/datasources/cuota_remote_datasource.dart';
import '../../features/cuota/data/repositories/cuota_repository_impl.dart';
import '../../features/cuota/domain/repositories/cuota_repository.dart';
import '../../features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import '../../features/diagnosis/data/repositories/diagnosis_repository_impl.dart';
import '../../features/diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../features/diagnostico_aplicado/data/datasources/diagnostico_aplicado_remote_datasource.dart';
import '../../features/diagnostico_aplicado/data/repositories/diagnostico_aplicado_repository_impl.dart';
import '../../features/diagnostico_aplicado/domain/repositories/diagnostico_aplicado_repository.dart';
import '../../features/odontograma/data/datasources/odontograma_remote_datasource.dart';
import '../../features/odontograma/data/repositories/odontograma_repository_impl.dart';
import '../../features/odontograma/domain/repositories/odontograma_repository.dart';
import '../../features/diente/data/datasources/diente_remote_datasource.dart';
import '../../features/diente/data/repositories/diente_repository_impl.dart';
import '../../features/diente/domain/repositories/diente_repository.dart';
import '../../features/superficie/data/datasources/superficie_remote_datasource.dart';
import '../../features/superficie/data/repositories/superficie_repository_impl.dart';
import '../../features/superficie/domain/repositories/superficie_repository.dart';
import '../../features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';
import '../../features/tratamiento/data/repositories/tratamiento_repository_impl.dart';
import '../../features/tratamiento/domain/repositories/tratamiento_repository.dart';
import '../../features/tratamiento_aplicado/data/datasources/tratamiento_aplicado_datasource.dart';
import '../../features/tratamiento_aplicado/data/repositories/tratamiento_aplicado_repository_impl.dart';
import '../../features/tratamiento_aplicado/domain/repositories/tratamiento_aplicado_repository.dart';
import '../../features/equipo/data/datasources/equipo_remote_datasource.dart';
import '../../features/equipo/data/repositories/equipo_repository_impl.dart';
import '../../features/equipo/domain/repositories/equipo_repository.dart';
import '../../features/equipo_mantenimiento/data/datasources/equipo_mantenimiento_remote_datasource.dart';
import '../../features/equipo_mantenimiento/data/repositories/equipo_mantenimiento_repository_impl.dart';
import '../../features/equipo_mantenimiento/domain/repositories/equipo_mantenimiento_repository.dart';
import '../../features/movimiento_caja/data/datasources/movimiento_caja_remote_datasource.dart';
import '../../features/movimiento_caja/data/repositories/movimiento_caja_repository_impl.dart';
import '../../features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';
import '../../features/documento_clinico/data/datasources/documento_clinico_datasource.dart';
import '../../features/documento_clinico/data/repositories/documento_clinico_repository_impl.dart';
import '../../features/documento_clinico/domain/repositories/documento_clinico_repository.dart';
import '../../features/orden_medica/data/datasources/orden_medica_remote_datasource.dart';
import '../../features/orden_medica/data/repositories/orden_medica_repository_impl.dart';
import '../../features/orden_medica/domain/repositories/orden_medica_repository.dart';
import '../../features/receta/data/datasources/receta_remote_datasource.dart';
import '../../features/receta/data/repositories/receta_repository_impl.dart';
import '../../features/receta/domain/repositories/receta_repository.dart';
import '../../features/record/data/datasources/record_remote_datasource.dart';
import '../../features/record/data/repositories/record_repository_impl.dart';
import '../../features/record/domain/repositories/record_repository.dart';
import '../../features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import '../../features/suplidor/data/repositories/suplidor_repository_impl.dart';
import '../../features/suplidor/domain/repositories/suplidor_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerSingleton<SupabaseClient>(Supabase.instance.client);

  sl.registerLazySingleton<MedicinaRemoteDatasource>(
    () => MedicinaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<CuentaRemoteDatasource>(
    () => CuentaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<ItemCuentaDatasource>(
    () => ItemCuentaDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<CuotaRemoteDatasource>(
    () => CuotaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<PagoRemoteDatasource>(
    () => PagoRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<DiagnosisRemoteDatasource>(
    () => DiagnosisRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<DiagnosticoAplicadoRemoteDatasource>(
    () => DiagnosticoAplicadoRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<OdontogramaRemoteDatasource>(
    () => OdontogramaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<DienteRemoteDatasource>(
    () => DienteRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<SuperficieRemoteDatasource>(
    () => SuperficieRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<TratamientoRemoteDatasource>(
    () => TratamientoRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<TratamientoAplicadoDatasource>(
    () => TratamientoAplicadoDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<EquipoRemoteDatasource>(
    () => EquipoRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<EquipoMantenimientoRemoteDatasource>(
    () => EquipoMantenimientoRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<MovimientoCajaRemoteDatasource>(
    () => MovimientoCajaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<DocumentoClinicoDatasource>(
    () => DocumentoClinicoDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<OrdenMedicaRemoteDatasource>(
    () => OrdenMedicaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<RecetaRemoteDatasource>(
    () => RecetaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<RecordRemoteDatasource>(
    () => RecordRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<SuplidorRemoteDatasource>(
    () => SuplidorRemoteDatasourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<IMedicinaRepository>(
    () => MedicinaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CuentaRepository>(
    () => CuentaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ItemCuentaRepository>(
    () => ItemCuentaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CuotaRepository>(
    () => CuotaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<PagoRepository>(
    () => PagoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DiagnosisRepository>(
    () => DiagnosisRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DiagnosticoAplicadoRepository>(
    () => DiagnosticoAplicadoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<OdontogramaRepository>(
    () => OdontogramaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DienteRepository>(
    () => DienteRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SuperficieRepository>(
    () => SuperficieRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TratamientoRepository>(
    () => TratamientoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TratamientoAplicadoRepository>(
    () => TratamientoAplicadoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<EquipoRepository>(
    () => EquipoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<EquipoMantenimientoRepository>(
    () => EquipoMantenimientoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<MovimientoCajaRepository>(
    () => MovimientoCajaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DocumentoClinicoRepository>(
    () => DocumentoClinicoRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<OrdenMedicaRepository>(
    () => OrdenMedicaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RecetaRepository>(
    () => RecetaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RecordRepository>(
    () => RecordRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SuplidorRepository>(
    () => SuplidorRepositoryImpl(remoteDataSource: sl()),
  );
}
