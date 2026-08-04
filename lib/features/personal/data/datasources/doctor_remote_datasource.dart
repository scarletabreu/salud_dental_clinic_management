import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

/// Lectura del catálogo clínico.
///
/// Las altas y bajas de doctores **no** viven aquí: las hace la Edge Function
/// `admin-crear-usuario` con el trigger `handle_new_user`, que son los únicos
/// que dejan `personas`, `usuarios`, `doctores` y `admins` con el mismo UUID.
/// Las escrituras que había en este datasource apuntaban a columnas (`user_id`,
/// `estatus`) y a una tabla (`doctors`) que el esquema vigente no tiene, así
/// que no podían funcionar; se retiraron en HFX-CLIN-000.
abstract class DoctorRemoteDatasource {
  Future<List<DoctorModel>> fetchActiveDoctores();
  Future<Map<String, dynamic>?> fetchDoctorById(String userId);
  Future<List<Map<String, dynamic>>> fetchDoctorAsistentesByAsistenteId(
    String asistenteId,
  );
}
