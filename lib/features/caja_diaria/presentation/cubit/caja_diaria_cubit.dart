import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_dental_clinic_management/core/errors/failures.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/balance_caja.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/arqueo_pendiente.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/caja_diaria.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/entities/resumen_cierre.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/domain/repositories/caja_diaria_repository.dart';
import 'package:salud_dental_clinic_management/features/caja_diaria/presentation/cubit/caja_diaria_state.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/entities/movimiento_caja.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/enums/tipo_movimiento.dart';
import 'package:salud_dental_clinic_management/features/movimiento_caja/domain/repositories/movimiento_caja_repository.dart';

class CajaDiariaCubit extends Cubit<CajaDiariaState> {
  CajaDiariaCubit(this._repository, this._movimientoCajaRepository)
    : super(const CajaDiariaLoading());

  final CajaDiariaRepository _repository;
  final MovimientoCajaRepository _movimientoCajaRepository;
  StreamSubscription<List<MovimientoCaja>>? _movimientosSubscription;
  CajaDiaria? _cajaActual;
  List<ArqueoPendiente> _pendientes = const [];

  /// Un fallo consultando los pendientes no puede impedir trabajar con la caja
  /// de hoy: es información complementaria, no un requisito.
  Future<List<ArqueoPendiente>> _cajasPendientes() async {
    try {
      return await _repository.getArqueosPendientes();
    } catch (_) {
      return const [];
    }
  }

  Future<void> cargar() async {
    await _movimientosSubscription?.cancel();
    _movimientosSubscription = null;
    emit(const CajaDiariaLoading());

    try {
      final caja = await _repository.getCajaActual();
      // Un arqueo olvidado ya no bloquea el día, pero tampoco puede quedar
      // invisible: la pantalla lo nombra en vez de mostrar el saldo de otro día
      // como si fuera el de hoy.
      _pendientes = await _cajasPendientes();

      if (caja == null) {
        _cajaActual = null;
        emit(CajaDiariaSinAbrir(pendientes: _pendientes));
        return;
      }

      _cajaActual = caja;
      emit(CajaDiariaAbierta(caja: caja, pendientes: _pendientes));

      _movimientosSubscription = _repository.watchMovimientos(caja.id!).listen((
        movimientos,
      ) async {
        if (!isClosed) {
          final cajaActualizada = await _repository.getCajaActual();
          if (cajaActualizada != null) {
            _cajaActual = cajaActualizada;
            emit(
              CajaDiariaAbierta(
                caja: cajaActualizada,
                movimientos: movimientos,
                pendientes: _pendientes,
              ),
            );
          } else if (_cajaActual != null) {
            emit(
              CajaDiariaAbierta(
                caja: _cajaActual!,
                movimientos: movimientos,
                pendientes: _pendientes,
              ),
            );
          }
        }
      }, onError: (_, _) {});
    } catch (e) {
      // Se propaga el motivo real. Un `catch (_)` que siempre decía lo mismo
      // convertía cualquier fallo —permisos, red, una caja de ayer sin
      // cerrar— en el mismo mensaje inútil, y no había forma de averiguar por
      // qué no se podía trabajar con la caja (defecto D13).
      emit(CajaDiariaError(_mensaje(e, 'No se pudo consultar la caja de hoy.')));
    }
  }

  /// El mensaje del `Failure` tipado si lo hay; si no, el genérico.
  static String _mensaje(Object error, String generico) {
    if (error is Failure) return error.message;
    final texto = error.toString().replaceFirst('Exception: ', '').trim();
    return texto.isEmpty ? generico : texto;
  }

  Future<String?> abrirCaja(double montoApertura) async {
    if (montoApertura < 0) return 'El monto inicial no puede ser negativo.';

    try {
      await _repository.abrirCaja(montoApertura);
      await cargar();
      return null;
    } catch (e) {
      final mensaje = _mensaje(
        e,
        'No se pudo abrir la caja. Verifica tu conexión e inténtalo de nuevo.',
      );
      if (!isClosed) {
        emit(CajaDiariaSinAbrir(error: mensaje));
      }
      return mensaje;
    }
  }

  Future<String?> registrarEgreso({
    required double monto,
    required String descripcion,
  }) async {
    final currentState = state;
    if (currentState is! CajaDiariaAbierta) {
      return 'No hay una caja abierta para registrar movimientos.';
    }

    final cajaId = currentState.caja.id;
    if (cajaId == null) {
      return 'Identificador de caja no disponible.';
    }

    if (monto <= 0) {
      return 'El monto del egreso debe ser mayor a cero.';
    }

    final descLimpia = descripcion.trim();
    if (descLimpia.isEmpty) {
      return 'La descripción del egreso es obligatoria.';
    }

    if (monto > currentState.montoEsperado) {
      return 'El monto supera el dinero esperado actualmente en caja (RD\$ ${currentState.montoEsperado.toStringAsFixed(2)}).';
    }

    try {
      final movimiento = MovimientoCaja(
        cajaDiariaId: cajaId,
        tipo: TipoMovimiento.egreso,
        monto: monto,
        descripcion: descLimpia,
        fecha: DateTime.now(),
        referenciaId: cajaId,
      );

      await _movimientoCajaRepository.crearMovimiento(movimiento);
      await cargar();
      return null;
    } catch (e) {
      return 'Error al registrar el egreso: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  ResumenCierre? obtenerResumenCierre() {
    final currentState = state;
    if (currentState is! CajaDiariaAbierta) return null;

    final Map<String, double> totalesPorMetodo = {
      'Efectivo / General': currentState.ingresos,
    };

    return ResumenCierre(
      totalesPorMetodoPago: totalesPorMetodo,
      totalIngresos: currentState.ingresos,
      totalEgresos: currentState.egresos,
      montoEsperado: currentState.montoEsperado,
      movimientos: currentState.movimientos,
    );
  }

  /// El monto esperado no se recibe por parámetro a propósito: lo recalcula el
  /// repositorio contra los movimientos persistidos justo antes de cerrar, para
  /// que un cobro que entró mientras el cajero contaba el efectivo no quede
  /// fuera del cuadre.
  Future<String?> cerrarCaja({required double montoReal}) async {
    if (state is! CajaDiariaAbierta) {
      return 'No hay una caja abierta para cerrar.';
    }

    if (montoReal < 0) {
      return 'El monto contado no puede ser negativo.';
    }

    try {
      await _repository.cerrarCaja(
        montoReal: montoReal,
        montoCierre: montoReal,
      );
      // La caja quedó cerrada en la base: el estado debe reflejarlo o la
      // pantalla seguiría ofreciendo registrar movimientos sobre una caja muerta.
      await cargar();
      return null;
    } catch (e) {
      return 'Error al cerrar la caja: ${e.toString().replaceAll('Exception: ', '')}';
    }
  }

  /// Arqueo pendiente por su id, o `null` si ya no está en la lista.
  ArqueoPendiente? arqueoPendiente(String cajaId) {
    for (final arqueo in _pendientes) {
      if (arqueo.id == cajaId) return arqueo;
    }
    return null;
  }

  /// Cierra el arqueo de un día anterior que nadie cuadró.
  ///
  /// El descuadre se queda en su día: no genera ningún ajuste en la caja de
  /// hoy. Corregir el pasado tocando el presente es lo que convierte un
  /// faltante en dos cajas descuadradas.
  Future<String?> cerrarArqueoPendiente({
    required String cajaId,
    required double montoReal,
    String? observaciones,
  }) async {
    if (montoReal < 0) {
      return 'El monto contado no puede ser negativo.';
    }

    final arqueo = arqueoPendiente(cajaId);
    if (arqueo == null) {
      return 'Ese arqueo ya no está pendiente. Actualiza la pantalla.';
    }

    // Días después, la nota es el único registro de por qué el dinero no
    // cuadró. Sin ella el descuadre queda como un número sin historia.
    final nota = observaciones?.trim();
    final diferencia = BalanceCaja.diferencia(
      montoReal: montoReal,
      montoEsperado: arqueo.esperado,
    );
    if (diferencia != 0 && (nota == null || nota.isEmpty)) {
      return 'Un arqueo que no cuadra necesita una nota que explique la diferencia.';
    }

    try {
      await _repository.cerrarArqueoPendiente(
        cajaId: cajaId,
        montoReal: montoReal,
        observaciones: nota,
      );
      await cargar();
      return null;
    } catch (e) {
      return _mensaje(e, 'No se pudo cerrar el arqueo pendiente.');
    }
  }

  @override
  Future<void> close() async {
    await _movimientosSubscription?.cancel();
    return super.close();
  }
}
