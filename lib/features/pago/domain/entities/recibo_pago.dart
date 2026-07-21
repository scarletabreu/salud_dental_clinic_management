import 'package:salud_dental_clinic_management/features/consulta/domain/entities/consulta.dart';
import 'package:salud_dental_clinic_management/features/cuenta/domain/entities/cuenta.dart';
import 'package:salud_dental_clinic_management/features/paciente/domain/entities/paciente.dart';
import 'package:salud_dental_clinic_management/features/pago/domain/entities/pago.dart';

/// Datos que identifican al emisor de la constancia.
///
/// La aplicación todavía no dispone de un perfil administrativo de la clínica,
/// por lo que solo se incluyen datos verificados del producto. No se inventan
/// dirección, teléfono ni RNC y el documento se identifica expresamente como
/// recibo no fiscal.
class DatosClinica {
  final String nombre;
  final String descripcion;

  const DatosClinica({required this.nombre, required this.descripcion});

  static const saludDental = DatosClinica(
    nombre: 'Salud Dental',
    descripcion: 'Clínica odontológica',
  );
}

/// Instantánea de los datos necesarios para mostrar y generar un recibo.
class ReciboPago {
  final DatosClinica clinica;
  final Cuenta cuenta;
  final Pago pago;
  final Consulta consulta;
  final Paciente paciente;

  const ReciboPago({
    this.clinica = DatosClinica.saludDental,
    required this.cuenta,
    required this.pago,
    required this.consulta,
    required this.paciente,
  });

  String get numero {
    final id = pago.id;
    if (id == null || id.isEmpty) return 'SIN-NÚMERO';
    return id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
  }

  String get consultaNumero {
    final id = consulta.id ?? cuenta.consultaId;
    return id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
  }

  double get pagadoAntes {
    return cuenta.pagos
        .where(
          (otro) =>
              otro.fueExitoso &&
              otro.id != pago.id &&
              !otro.fecha.isAfter(pago.fecha),
        )
        .fold(0, (total, otro) => total + otro.monto);
  }

  double get saldoDespues {
    final saldo = cuenta.montoTotal - pagadoAntes - pago.monto;
    return saldo > 0 ? saldo : 0;
  }

  String get nombreArchivo => 'recibo-$numero.pdf';
}
