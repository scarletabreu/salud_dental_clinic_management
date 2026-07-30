import 'package:salud_dental_clinic_management/core/data/models/contacto_model.dart';
import 'package:salud_dental_clinic_management/core/domain/enums/estatus_persona.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/admin_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/asistente_model.dart';
import 'package:salud_dental_clinic_management/features/personal/data/models/doctor_model.dart';

/// Traduce la fila plana de la RPC `perfil_actual()` al perfil del dominio.
///
/// Antes el login encadenaba tres consultas de PostgREST —`admins` ->
/// `doctores` -> `usuarios` -> `personas`— y bastaba con que una relación no
/// existiera en la base para que la sesión muriera después de que Auth ya
/// hubiera autenticado. La RPC devuelve una sola fila, resuelve el rol en el
/// servidor a partir de `auth.uid()` y no incluye ninguna contraseña.
class PerfilActualMapper {
  const PerfilActualMapper._();

  static Usuario? desdeFila(Map<String, dynamic> fila) {
    final rol = fila['rol'] as String?;
    if (rol == null) return null;

    final id = fila['id'] as String?;
    final nombre = fila['nombre'] as String? ?? '';
    final apellido = fila['apellido'] as String? ?? '';
    final birthDate = fila['fecha_nacimiento'] != null
        ? DateTime.parse(fila['fecha_nacimiento'] as String)
        : DateTime.now();
    final govID = fila['cedula'] as String? ?? '';
    final username = fila['username'] as String? ?? '';
    final estatus = fila['estatus'] == 'inactivo'
        ? EstatusPersona.inactivo
        : EstatusPersona.activo;
    final contactos = _contactos(fila);

    switch (rol) {
      case 'admin':
        return AdminModel(
          id: id,
          nombre: nombre,
          apellido: apellido,
          birthDate: birthDate,
          govID: govID,
          contactos: contactos,
          estatus: estatus,
          username: username,
          // La contraseña no viaja al cliente: la RPC no la devuelve.
          passwordHash: '',
          assistants: const [],
          specialty: fila['especialidad'] as String? ?? '',
          isAvailable: fila['esta_disponible'] as bool? ?? true,
          departamento: fila['departamento'] as String? ?? '',
        );
      case 'doctor':
        return DoctorModel(
          id: id,
          nombre: nombre,
          apellido: apellido,
          birthDate: birthDate,
          govID: govID,
          contactos: contactos,
          estatus: estatus,
          username: username,
          passwordHash: '',
          assistants: const [],
          specialty: fila['especialidad'] as String? ?? '',
          isAvailable: fila['esta_disponible'] as bool? ?? true,
        );
      case 'asistente':
        return AsistenteModel(
          id: id,
          nombre: nombre,
          apellido: apellido,
          birthDate: birthDate,
          govID: govID,
          contactos: contactos,
          estatus: estatus,
          username: username,
          passwordHash: '',
          shift: fila['turno'] as String? ?? '',
        );
      default:
        return null;
    }
  }

  /// La RPC trae el contacto principal aplanado; sin teléfono ni correo no se
  /// fabrica un contacto vacío que la UI leería como dato existente.
  static List<ContactoModel> _contactos(Map<String, dynamic> fila) {
    final telefono = fila['telefono'] as String?;
    final email = fila['email'] as String?;
    final direccion = fila['direccion'] as String?;
    if (telefono == null && email == null && direccion == null) {
      return const [];
    }
    return [
      ContactoModel(
        email: email ?? '',
        numeroTelefono: telefono ?? '',
        direccion: direccion ?? '',
      ),
    ];
  }
}
