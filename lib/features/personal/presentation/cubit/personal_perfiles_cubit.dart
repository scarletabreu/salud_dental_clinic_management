import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/repositories/usuario_repository.dart';
import 'personal_perfiles_state.dart';

class PersonalPerfilesCubit extends Cubit<PersonalPerfilesState> {
  final UsuarioRepository _usuarioRepository;

  PersonalPerfilesCubit({required UsuarioRepository usuarioRepository})
    : _usuarioRepository = usuarioRepository,
      super(const PerfilInitial());

  Future<void> cargarUsuarios() async {
    emit(const PerfilLoading());
    try {
      final listado = await _usuarioRepository.getUsuarios();
      // `PerfilError` queda para el fallo total. Un fallo parcial —una lectura
      // de rol o una fila corrupta— viaja como aviso y se pinta en su propia
      // tarjeta, sin tumbar la administración del resto del personal.
      emit(
        PerfilLoaded(
          todos: listado.perfiles,
          filtrados: listado.perfiles,
          avisos: listado.avisos,
        ),
      );
    } catch (e) {
      emit(PerfilError(e.toString()));
    }
  }

  void aplicarFiltros({String? query, RolUsuario? Function()? rolFiltro}) {
    final currentState = state;
    if (currentState is! PerfilLoaded) return;

    final nuevaBusqueda = query ?? currentState.queryBusqueda;
    final nuevoRol = rolFiltro != null ? rolFiltro() : currentState.rolFiltro;

    final usuariosFiltrados = currentState.todos.where((usuario) {
      if (nuevoRol != null && usuario.rol != nuevoRol) {
        return false;
      }

      if (nuevaBusqueda.isNotEmpty) {
        final queryClean = nuevaBusqueda.toLowerCase();
        final nombreCompleto = '${usuario.nombre} ${usuario.apellido}'
            .toLowerCase();
        final govID = usuario.govID.toLowerCase();
        final username = usuario.username.toLowerCase();

        return nombreCompleto.contains(queryClean) ||
            govID.contains(queryClean) ||
            username.contains(queryClean);
      }
      return true;
    }).toList();

    emit(
      currentState.copyWith(
        filtrados: usuariosFiltrados,
        queryBusqueda: nuevaBusqueda,
        rolFiltro: () => nuevoRol,
      ),
    );
  }

  Future<void> guardarUsuario({
    Usuario? existente,
    required String nombre,
    required String apellido,
    required DateTime birthDate,
    required String govID,
    required String username,
    required String telefono,
    String? nuevaPassword,
    String? email,
    RolUsuario? rol,
    String? especialidad,
    String? departamento,
    String? turno,
    // Solo aplica para Doctor/Admin. Si es null, no se toca la asignación.
    List<String>? asistenteIdsAsignados,
  }) async {
    emit(const PerfilLoading());
    try {
      String? doctorIdParaAsignar;

      if (existente == null) {
        final creado = await _usuarioRepository.crearUsuario(
          email: email!,
          password: nuevaPassword!,
          nombre: nombre,
          apellido: apellido,
          birthDate: birthDate,
          govID: govID,
          username: username,
          rol: rol!,
          telefono: telefono,
          especialidad: especialidad,
          departamento: departamento,
          turno: turno,
        );
        doctorIdParaAsignar = creado.id;
      } else {
        await _usuarioRepository.actualizarUsuario(
          usuarioId: existente.id!,
          nombre: nombre,
          apellido: apellido,
          birthDate: birthDate,
          govID: govID,
          telefono: telefono,
        );
        if (nuevaPassword != null && nuevaPassword.isNotEmpty) {
          await _usuarioRepository.resetearPassword(
            usuarioId: existente.id!,
            nuevaPassword: nuevaPassword,
          );
        }
        doctorIdParaAsignar = existente.id;
      }

      if (asistenteIdsAsignados != null && doctorIdParaAsignar != null) {
        await _usuarioRepository.asignarAsistentes(
          doctorId: doctorIdParaAsignar,
          asistenteIds: asistenteIdsAsignados,
        );
      }

      await cargarUsuarios();
    } catch (e) {
      emit(PerfilError(e.toString()));
    }
  }

  Future<String?> desactivarUsuario(Usuario usuario) async {
    if (usuario.id == null) {
      return 'No se pudo identificar al usuario a desactivar.';
    }

    try {
      final motivoBloqueo = await _usuarioRepository.desactivarUsuario(
        usuarioId: usuario.id!,
        rol: usuario.rol,
      );

      if (motivoBloqueo == null) {
        await cargarUsuarios();
      }

      return motivoBloqueo;
    } catch (e) {
      return e.toString();
    }
  }

  /// Lista de asistentes disponibles para el multi-select del form.
  Future<List<Usuario>> cargarAsistentesDisponibles() {
    return _usuarioRepository.getAsistentesDisponibles();
  }

  /// IDs ya asignados a un doctor/admin, para pre-marcar el multi-select
  /// en modo edición.
  Future<List<String>> cargarAsistentesAsignados(String doctorId) {
    return _usuarioRepository.getAsistentesAsignadosIds(doctorId);
  }
}