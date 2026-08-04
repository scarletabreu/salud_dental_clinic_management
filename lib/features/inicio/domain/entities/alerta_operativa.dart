import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/auth/domain/enums/rol_usuario.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/entidad_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/severidad_alerta.dart';
import 'package:salud_dental_clinic_management/features/inicio/domain/enums/tipo_alerta.dart';

class AlertaOperativa extends Equatable {
  final String id;
  final TipoAlerta tipo;
  final SeveridadAlerta severidad;
  final String titulo;
  final String descripcion;
  final EntidadAlerta entidadTipo;
  final String? entidadId;
  final List<RolUsuario> rolesAutorizados;
  final bool esClinicamenteSensible;
  final DateTime timestamp;

  const AlertaOperativa({
    required this.id,
    required this.tipo,
    required this.severidad,
    required this.titulo,
    required this.descripcion,
    required this.entidadTipo,
    this.entidadId,
    required this.rolesAutorizados,
    this.esClinicamenteSensible = false,
    required this.timestamp,
  });

  bool esVisibleParaRoles(List<RolUsuario> rolesUsuario) =>
      rolesUsuario.any(rolesAutorizados.contains);

  @override
  List<Object?> get props => [
    id,
    tipo,
    severidad,
    titulo,
    descripcion,
    entidadTipo,
    entidadId,
    rolesAutorizados,
    esClinicamenteSensible,
    timestamp,
  ];
}
