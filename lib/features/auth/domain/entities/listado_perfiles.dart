import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/entities/usuario.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';

/// Un perfil que no se pudo cargar, con lo poco que se sabe de él.
///
/// Existe porque la pantalla de Perfiles moría entera cuando fallaba **una**
/// de sus tres lecturas o **una** fila corrupta (defecto D2 de la jornada de QA
/// del 1 ago 2026). Administrar al resto del personal no debería depender de
/// que todos los registros estén sanos.
class AvisoPerfil extends Equatable {
  /// Id del perfil, cuando la fila trae uno legible.
  final String? id;

  /// Cómo referirse a él en la tarjeta de error. Si la fila trae nombre o
  /// usuario se usa eso; si no, el rol y el id abreviado.
  final String titulo;

  /// Qué salió mal, en términos que el administrador pueda accionar.
  final String detalle;

  /// Rol de la lectura que falló, si se conoce. `null` cuando el fallo fue de
  /// una fila suelta cuyo rol tampoco se pudo determinar.
  final RolUsuario? rol;

  /// `true` si lo que falló fue la lectura completa de un rol, no una fila.
  final bool esSeccionCompleta;

  const AvisoPerfil({
    required this.titulo,
    required this.detalle,
    this.id,
    this.rol,
    this.esSeccionCompleta = false,
  });

  @override
  List<Object?> get props => [id, titulo, detalle, rol, esSeccionCompleta];
}

/// Resultado de consolidar el listado de personal: lo que sí se pudo cargar y
/// lo que no. Nunca lanza por un fallo parcial.
class ListadoPerfiles extends Equatable {
  final List<Usuario> perfiles;
  final List<AvisoPerfil> avisos;

  const ListadoPerfiles({required this.perfiles, this.avisos = const []});

  bool get tieneAvisos => avisos.isNotEmpty;

  @override
  List<Object?> get props => [perfiles, avisos];
}
