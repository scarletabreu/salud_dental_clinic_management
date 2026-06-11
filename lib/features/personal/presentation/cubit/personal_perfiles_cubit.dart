import 'package:flutter_bloc/flutter_bloc.dart';
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
      final usuarios = await _usuarioRepository.getUsuarios();
      emit(PerfilLoaded(todos: usuarios, filtrados: usuarios));
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
}
