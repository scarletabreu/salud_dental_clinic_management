import 'package:get_it/get_it.dart';
import 'package:salud_dental_clinic_management/core/errors/guard.dart';
import 'package:salud_dental_clinic_management/core/network/connectivity_check.dart';
import 'package:salud_dental_clinic_management/core/realtime/fabrica_canales_supabase.dart';
import 'package:salud_dental_clinic_management/core/realtime/senales_realtime.dart';
import 'package:salud_dental_clinic_management/core/presentation/connectivity_cubit.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource.dart';
import 'package:salud_dental_clinic_management/core/data/datasources/supabase_storage_helper.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/services/paciente_foto_storage.dart';

// Módulo Compras
import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/compra/data/datasources/compra_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/compra/data/repositories/compra_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/repositories/compra_repository.dart';
import 'package:salud_dental_clinic_management/features/compra/domain/usecases/recibir_compra.dart';
import 'package:salud_dental_clinic_management/features/compra/presentation/cubit/compra_cubit.dart';

// Módulo Consulta
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/datasources/consulta_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/consulta_abierta_lookup.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_abierta_lookup_impl.dart';
import 'package:salud_dental_clinic_management/features/consulta/data/repositories/consulta_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/repositories/consulta_repository.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/eliminar_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/crear_consulta_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consulta_detalle_cubit.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/consultas_list_cubit.dart';

// Core & Auth
import 'package:salud_dental_clinic_management/core/data/datasources/persona_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/core/data/repositories/persona_repository_impl.dart';
import 'package:salud_dental_clinic_management/core/domain/repositories/persona_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auth/data/datasources/usuario_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/auth/data/repositories/usuario_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:salud_dental_clinic_management/features/configuracion/presentation/cubit/settings_cubit.dart';

// Módulo Consumibles / Inventario
import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/datasources/consumible_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/consumible/data/repositories/consumible_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/repositories/consumible_repository.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/actualizar_existencia.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/eliminar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/get_inventario.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/guardar_consumible.dart';
import 'package:salud_dental_clinic_management/features/consumible/domain/usecases/obtener_articulos_bajo_minimo.dart';
import 'package:salud_dental_clinic_management/features/consumible/presentation/cubit/inventario_cubit.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remore_datasource.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/datasources/procedimiento_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/data/repositories/procedimiento_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/procedimiento/domain/repositories/procedimiento_repository.dart';

// Módulo Suplidores
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/eliminar_suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/get_directorio_suplidores.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/usecases/guardar_suplidor.dart';
import 'package:salud_dental_clinic_management/features/suplidor/presentation/cubit/suplidor_cubit.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/datasources/suplidor_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/suplidor/data/repositories/suplidor_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/suplidor/domain/repositories/suplidor_repository.dart';

// Módulo Equipos & Caja
import 'package:salud_dental_clinic_management/features/equipo/domain/usecases/eliminar_equipo_usecase.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/usecases/get_inventario_usecase.dart';
import 'package:salud_dental_clinic_management/features/equipo/domain/usecases/registrar_o_actualizar_equipo_usecase.dart';
import 'package:salud_dental_clinic_management/features/equipo/presentation/cubit/equipo_cubit.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/usecases/registrar_egreso_caja.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:salud_dental_clinic_management/features/personal/presentation/cubit/personal_perfiles_cubit.dart';

// Citas
import 'package:salud_dental_clinic_management/features/cita/data/datasources/cita_remote_datasources.dart';
import 'package:salud_dental_clinic_management/features/cita/data/repositories/cita_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/cita/domain/repositories/cita_repository.dart';
import 'package:salud_dental_clinic_management/features/cita/presentation/cubit/cita_cubit.dart';
import 'package:salud_dental_clinic_management/features/inicio/presentation/cubit/dashboard_cubit.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/datasources/paciente_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/paciente/data/repositories/paciente_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/repositories/i_paciente_repository.dart';
import 'package:salud_dental_clinic_management/features/paciente/presentation/cubit/paciente_cubit.dart';

// Data Sources Impl
import 'package:salud_dental_clinic_management/features/contraindicacion/data/datasources/contraindicacion_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/datasources/contraindicacion_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/data/repositories/contraindicacion_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/contraindicacion/domain/repositories/contraindicacion_repository.dart';
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
import 'package:salud_dental_clinic_management/features/movimiento_caja/data/datasources/movimiento_caja_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/datasources/caja_diaria_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/data/repositories/caja_diaria_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_cubit.dart';
import 'package:salud_dental_clinic_management/features/odontograma/data/datasources/odontograma_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/orden_medica/data/datasources/orden_medica_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/pago/data/datasources/pago_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/personal/data/datasources/doctor_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/personal/data/repositories/doctor_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/personal/domain/repositories/doctor_repository.dart';
import 'package:salud_dental_clinic_management/features/receta/data/datasources/receta_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/record/data/datasources/record_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/superficie/data/datasources/superficie_remote_datasource_impl.dart';
import 'package:salud_dental_clinic_management/features/tratamiento/data/datasources/tratamiento_remote_datasource_impl.dart';

// Interfaces y Repositorios
import '../../features/medicina/data/datasources/medicina_remote_datasource.dart';
import '../../features/medicina/data/repositories/medicina_repository_impl.dart';
import '../../features/medicina/domain/repositories/i_medicina_repository.dart';
import '../../features/cuenta/data/datasources/cuenta_remote_datasource.dart';
import '../../features/cuenta/data/repositories/cuenta_repository_impl.dart';
import '../../features/cuenta/domain/repositories/cuenta_repository.dart';
import '../../features/item_cuenta/data/datasources/item_cuenta_remote_datasource.dart';
import '../../features/item_cuenta/data/repositories/item_cuenta_repository_impl.dart';
import '../../features/item_cuenta/domain/repositories/item_cuenta_repository.dart';
import '../../features/cuota/data/datasources/cuota_remote_datasource.dart';
import '../../features/cuota/data/repositories/cuota_repository_impl.dart';
import '../../features/cuota/domain/repositories/cuota_repository.dart';
import '../../features/cuota/domain/usecases/generar_plan_de_cuotas.dart';
import '../../features/pago/data/datasources/pago_remote_datasource.dart';
import '../../features/pago/data/repositories/pago_repository_impl.dart';
import '../../features/pago/domain/repositories/pago_repository.dart';
import '../../features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import '../../features/diagnosis/data/repositories/diagnosis_repository_impl.dart';
import '../../features/diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../features/diagnostico_aplicado/data/datasources/diagnostico_aplicado_remote_datasource.dart';
import '../../features/diagnostico_aplicado/data/repositories/diagnostico_aplicado_repository_impl.dart';
import '../../features/diagnostico_aplicado/domain/repositories/diagnostico_aplicado_repository.dart';
import '../../features/auditoria/data/datasources/auditoria_remote_datasource.dart';
import '../../features/auditoria/data/datasources/auditoria_remote_datasource_impl.dart';
import '../../features/auditoria/data/repositories/auditoria_repository_impl.dart';
import '../../features/auditoria/domain/repositories/auditoria_repository.dart';

// Módulo Reglas clínicas (HFX-CLIN-006)
import '../../features/regla_clinica/data/datasources/regla_clinica_remote_datasource.dart';
import '../../features/regla_clinica/data/datasources/regla_clinica_remote_datasource_impl.dart';
import '../../features/regla_clinica/data/repositories/regla_clinica_repository_impl.dart';
import '../../features/regla_clinica/domain/repositories/regla_clinica_repository.dart';
import '../../features/regla_clinica/presentation/cubit/reglas_clinicas_cubit.dart';
import '../../features/evaluacion_clinica/data/datasources/evaluacion_clinica_remote_datasource.dart';
import '../../features/evaluacion_clinica/data/datasources/evaluacion_clinica_remote_datasource_impl.dart';
import '../../features/evaluacion_clinica/data/repositories/evaluacion_clinica_repository_impl.dart';
import '../../features/evaluacion_clinica/domain/repositories/evaluacion_clinica_repository.dart';
import '../../features/plan_tratamiento/data/datasources/plan_tratamiento_remote_datasource.dart';
import '../../features/plan_tratamiento/data/datasources/plan_tratamiento_remote_datasource_impl.dart';
import '../../features/plan_tratamiento/data/repositories/plan_tratamiento_repository_impl.dart';
import '../../features/plan_tratamiento/domain/repositories/plan_tratamiento_repository.dart';
import '../../features/plan_tratamiento/presentation/cubit/plan_tratamiento_cubit.dart';
import '../../features/odontograma/data/datasources/odontograma_remote_datasource.dart';
import '../../features/odontograma/data/repositories/odontograma_repository_impl.dart';
import '../../features/odontograma/domain/repositories/odontograma_repository.dart';
import '../../features/diente/data/datasources/diente_remote_datasource.dart';
import '../../features/diente/data/repositories/diente_repository_impl.dart';
import '../../features/diente/domain/repositories/diente_repository.dart';
import '../../features/superficie/data/datasources/superficie_remote_datasource.dart';
import '../../features/superficie/data/repositories/superficie_repository_impl.dart';
import '../../features/superficie/domain/repositories/superficie_repository.dart';
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
import '../../features/record/domain/usecases/agregar_condicion_paciente.dart';
import '../../features/record/domain/usecases/get_condiciones_paciente.dart';
import '../../features/record/domain/usecases/quitar_condicion_paciente.dart';
import '../../features/record/presentation/cubit/condiciones_paciente_cubit.dart';
import '../../features/condicion/data/datasources/condicion_remote_datasource.dart';
import '../../features/condicion/data/datasources/condicion_remote_datasource_impl.dart';
import '../../features/condicion/data/repositories/condicion_repository_impl.dart';
import '../../features/condicion/domain/repositories/condicion_repository.dart';

import 'package:salud_dental_clinic_management/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:salud_dental_clinic_management/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:salud_dental_clinic_management/features/auth/presentation/cubit/auth_session_cubit.dart';

// Módulo Tratamiento
import '../../features/tratamiento/data/datasources/tratamiento_remote_datasource.dart';
import '../../features/tratamiento/data/repositories/tratamiento_repository_impl.dart';
import '../../features/tratamiento/domain/repositories/tratamiento_repository.dart';
import '../../features/tratamiento/presentation/cubit/tratamiento_cubit.dart';

// Módulo Cuentas por Cobrar
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuenta_by_id_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/usecases/get_cuentas_por_cobrar_usecase.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/cuentas_por_cobrar_cubit.dart';
import 'package:salud_dental_clinic_management/features/cuenta/presentation/cubit/pre_factura_cubit.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/usecases/registrar_pago.dart';

// Módulo Historial Financiero
import 'package:salud_dental_clinic_management/features/consulta/domain/usecases/get_historial_financiero_usecase.dart';
import 'package:salud_dental_clinic_management/features/consulta/presentation/cubit/historial_financiero_cubit.dart';

import 'package:salud_dental_clinic_management/features/plan_tratamiento/presentation/cubit/resumen_plan_cubit.dart';
import 'package:salud_dental_clinic_management/features/plan_tratamiento/domain/usecases/get_resumen_actividad_plan.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Supabase Client ──────────────────────────────────────────────────────
  sl.registerSingleton<SupabaseClient>(Supabase.instance.client);

  // --- Red / conectividad ---
  sl.registerLazySingleton<ConnectivityCheck>(() => ConnectivityCheckImpl());

  // Señales de invalidación multiusuario (MU-0). Lazy: los canales se abren
  // la primera vez que un cubit escucha, siempre con sesión autenticada.
  sl.registerLazySingleton<SenalesRealtime>(
    () => SenalesRealtime(fabrica: FabricaCanalesSupabase(sl())),
  );
  guardConnectivityCheck = () => sl<ConnectivityCheck>().hasConnection;
  sl.registerFactory<ConnectivityCubit>(() => ConnectivityCubit(sl())..start());

  // ── Remote Data Sources ──────────────────────────────────────────────────
  sl.registerLazySingleton<ContraindicacionRemoteDatasource>(
    () => ContraindicacionRemoteDatasourceImpl(supabaseClient: sl()),
  );
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
  sl.registerLazySingleton<EvaluacionClinicaRemoteDatasource>(
    () => EvaluacionClinicaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<AuditoriaRemoteDatasource>(
    () => AuditoriaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<ReglaClinicaRemoteDatasource>(
    () => ReglaClinicaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<PlanTratamientoRemoteDatasource>(
    () => PlanTratamientoRemoteDatasourceImpl(supabaseClient: sl()),
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
  sl.registerLazySingleton<CajaDiariaDatasource>(
    () => CajaDiariaDatasourceImpl(sl()),
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
  sl.registerLazySingleton<CondicionRemoteDatasource>(
    () => CondicionRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<SuplidorRemoteDatasource>(
    () => SuplidorRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<PacienteRemoteDatasource>(
    () => PacienteRemoteDatasource(sl()),
  );
  sl.registerLazySingleton<CitaRemoteDataSource>(
    () => CitaRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<ConsultaRemoteDatasource>(
    () => ConsultaRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<SupabaseStorageHelper>(
    () => SupabaseStorageHelper(supabaseClient: sl()),
  );
  sl.registerLazySingleton<PacienteFotoStorage>(
    () => PacienteFotoStorage(sl()),
  );

  // ── Repositories ─────────────────────────────────────────────────────────
  sl.registerLazySingleton<ContraindicacionRepository>(
    () => ContraindicacionRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<IMedicinaRepository>(
    () => MedicinaRepositoryImpl(
      remoteDataSource: sl(),
      contraindicacionRepository: sl(),
    ),
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
  sl.registerLazySingleton<EvaluacionClinicaRepository>(
    () => EvaluacionClinicaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AuditoriaRepository>(
    () => AuditoriaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ReglaClinicaRepository>(
    () => ReglaClinicaRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<ReglasClinicasCubit>(() => ReglasClinicasCubit(sl()));
  sl.registerLazySingleton<PlanTratamientoRepository>(
    () => PlanTratamientoRepositoryImpl(remoteDataSource: sl()),
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
  sl.registerLazySingleton<CajaDiariaRepository>(
    () => CajaDiariaRepositoryImpl(sl()),
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
  sl.registerLazySingleton<CondicionRepository>(
    () => CondicionRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SuplidorRepository>(
    () => SuplidorRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<IPacienteRepository>(
    () => PacienteRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<DoctorRemoteDatasource>(
    () => DoctorRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<DoctorRepository>(() => DoctorRepositoryImpl(sl()));
  sl.registerLazySingleton<PersonaRemoteDataSource>(
    () => PersonaRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PersonaRepository>(
    () => PersonaRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ConsultaRepository>(
    () => ConsultaRepositoryImpl(remoteDataSource: sl()),
  );
  // El lookup se resuelve perezosamente: la cita necesita preguntar por su
  // consulta, y registrar `ConsultaRepository` antes evita la referencia
  // circular entre ambos repositorios (SD-160).
  sl.registerLazySingleton<ConsultaAbiertaLookup>(
    () => ConsultaAbiertaLookupImpl(sl<ConsultaRepository>()),
  );
  sl.registerLazySingleton<CitaRepository>(
    () => CitaRepositoryImpl(
      remoteDataSource: sl(),
      consultaAbiertaLookup: sl<ConsultaAbiertaLookup>(),
    ),
  );
  sl.registerFactory<CrearConsultaUseCase>(() => CrearConsultaUseCase(sl()));
  sl.registerLazySingleton<UsuarioRemoteDataSource>(
    () => UsuarioRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<UsuarioRepository>(
    () => UsuarioRepositoryImpl(sl()),
  );

  // ── Auth ─────────────────────────────────────────────────────────────────
  sl.registerFactory<AuthCubit>(() => AuthCubit(usuarioRepository: sl()));
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<IAuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerSingleton<AuthSessionCubit>(AuthSessionCubit(sl())..initialize());

  // ── Cubits ───────────────────────────────────────────────────────────────
  sl.registerFactory<PacienteCubit>(() => PacienteCubit(sl(), sl(), sl()));
  sl.registerFactory<CitaCubit>(
    () => CitaCubit(sl(), sl<ConsultaAbiertaLookup>()),
  );
  sl.registerFactory<ConsultaCubit>(
    () => ConsultaCubit(
      sl<CrearConsultaUseCase>(),
      sl<SupabaseStorageHelper>(),
      sl<CitaRepository>(),
      sl<ConsultaRepository>(),
    ),
  );
  sl.registerFactory<ConsultaDetalleCubit>(
    () => ConsultaDetalleCubit(
      sl(),
      sl<IMedicinaRepository>(),
      sl<CitaRepository>(),
    ),
  );
  sl.registerFactory<PlanTratamientoCubit>(
    () => PlanTratamientoCubit(repository: sl()),
  );
  sl.registerFactory(() => GetResumenActividadPlan(sl()));
  sl.registerFactory(() => ResumenPlanCubit(sl()));
  sl.registerFactory<SettingsCubit>(() => SettingsCubit());
  sl.registerFactory<CajaDiariaCubit>(() => CajaDiariaCubit(sl(), sl()));
  sl.registerFactory<ConsultasListCubit>(
    () => ConsultasListCubit(
      consultaRepository: sl(),
      pacienteRepository: sl(),
      doctorRepository: sl(),
      eliminarConsultaUseCase: EliminarConsultaUseCase(repository: sl()),
    ),
  );

  sl.registerFactory<DashboardCubit>(
    () => DashboardCubit(
      citaRepository: sl(),
      pacienteRepository: sl(),
      medicinaRepository: sl(),
      consumibleRepository: sl(),
      cajaDiariaRepository: sl(),
      equipoRepository: sl(),
      senales: sl<SenalesRealtime>(),
    ),
  );
  sl.registerFactory<PersonalPerfilesCubit>(
    () => PersonalPerfilesCubit(usuarioRepository: sl<UsuarioRepository>()),
  );
  sl.registerFactory<TratamientoCubit>(
    () => TratamientoCubit(sl<TratamientoRepository>()),
  );
  sl.registerFactory<GetCuentasPorCobrarUseCase>(
    () => GetCuentasPorCobrarUseCase(repository: sl()),
  );
  sl.registerFactory<CuentasPorCobrarCubit>(
    () => CuentasPorCobrarCubit(
      sl<CuentaRepository>(),
      sl<IPacienteRepository>(),
    ),
  );

  sl.registerFactory<GetCuentaByIdUseCase>(
    () => GetCuentaByIdUseCase(repository: sl()),
  );
  sl.registerFactory<RegistrarPago>(() => RegistrarPago(sl()));
  sl.registerFactory<GenerarPlanDeCuotas>(() => GenerarPlanDeCuotas(sl()));
  sl.registerFactory<PreFacturaCubit>(
    () => PreFacturaCubit(
      getCuenta: sl(),
      registrarPago: sl(),
      cuotaRepository: sl(),
      generarPlan: sl(),
      consultaRepository: sl(),
      pacienteRepository: sl(),
      cuentaRepository: sl(),
    ),
  );

  sl.registerFactory<GetHistorialFinancieroUseCase>(
    () => GetHistorialFinancieroUseCase(repository: sl()),
  );
  sl.registerFactory<HistorialFinancieroCubit>(
    () => HistorialFinancieroCubit(getHistorial: sl()),
  );
  sl.registerFactory<GetCondicionesPaciente>(
    () => GetCondicionesPaciente(sl()),
  );
  sl.registerFactory<AgregarCondicionPaciente>(
    () => AgregarCondicionPaciente(sl()),
  );
  sl.registerFactory<QuitarCondicionPaciente>(
    () => QuitarCondicionPaciente(sl()),
  );
  sl.registerFactoryParam<CondicionesPacienteCubit, String, void>(
    (pacienteId, _) => CondicionesPacienteCubit(
      pacienteId: pacienteId,
      getCondiciones: sl(),
      agregarCondicion: sl(),
      quitarCondicion: sl(),
      catalogoRepository: sl(),
    ),
  );
  sl.registerFactory<GetInventarioEquiposUseCase>(
    () => GetInventarioEquiposUseCase(repository: sl()),
  );
  sl.registerFactory<RegistrarOActualizarEquipoUseCase>(
    () => RegistrarOActualizarEquipoUseCase(repository: sl()),
  );
  sl.registerFactory<EliminarEquipoUseCase>(
    () => EliminarEquipoUseCase(repository: sl()),
  );
  sl.registerFactory<EquipoCubit>(
    () => EquipoCubit(
      getInventario: sl(),
      registrarOActualizar: sl(),
      eliminar: sl(),
      mantenimientoRepository: sl(),
    ),
  );

  // ── Módulo Consumibles ───────────────────────────────────────────────────
  sl.registerLazySingleton<ConsumibleRemoteDatasource>(
    () => ConsumibleRemoteDatasourceImpl(supabaseClient: sl()),
  );
  sl.registerLazySingleton<ConsumibleRepository>(
    () => ConsumibleRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetInventario(sl()));
  sl.registerLazySingleton(() => GuardarConsumible(sl()));
  sl.registerLazySingleton(() => ActualizarExistencia(sl()));
  sl.registerLazySingleton(() => EliminarConsumible(sl()));
  sl.registerLazySingleton(() => ObtenerArticulosBajoMinimo(sl()));

  sl.registerFactory(
    () => InventarioCubit(
      getInventario: sl(),
      guardarConsumible: sl(),
      actualizarExistencia: sl(),
      eliminarConsumible: sl(),
      getDirectorioSuplidores: sl(),
    ),
  );

  sl.registerLazySingleton(() => RegistrarEgresoCaja(sl()));

  // ── Módulo Suplidores ────────────────────────────────────────────────────
  sl.registerLazySingleton(() => GetDirectorioSuplidores(sl()));
  sl.registerLazySingleton(() => GuardarSuplidor(sl()));
  sl.registerLazySingleton(() => EliminarSuplidor(sl()));

  sl.registerFactory(
    () => SuplidorCubit(
      getDirectorio: sl(),
      guardarSuplidor: sl(),
      eliminarSuplidor: sl(),
    ),
  );

  // ── Módulo Compras ───────────────────────────────────────────────────────
  sl.registerLazySingleton<CompraRemoteDatasource>(
    () => CompraRemoteDatasourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<CompraRepository>(
    () => CompraRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => RecibirCompra(sl()));

  sl.registerFactory(
    () => CompraCubit(repository: sl(), recibirCompraUseCase: sl()),
  );

  // --- PROCEDIMIENTOS ---
  sl.registerLazySingleton<ProcedimientoRemoteDatasource>(
    () => ProcedimientoRemoteDatasourceImpl(supabaseClient: sl()),
  );

  sl.registerLazySingleton<ProcedimientoRepository>(
    () => ProcedimientoRepositoryImpl(
      remoteDataSource: sl(),
      contraindicacionRepository: sl(),
    ),
  );
}
