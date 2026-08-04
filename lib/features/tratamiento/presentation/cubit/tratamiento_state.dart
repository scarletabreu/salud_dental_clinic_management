import 'package:salud_dental_clinic_management/features/tratamiento/domain/entities/tratamiento.dart';

abstract class TratamientoState {
  const TratamientoState();
}

class TratamientoInitial extends TratamientoState {
  const TratamientoInitial();
}

class TratamientoLoading extends TratamientoState {
  const TratamientoLoading();
}

class TratamientoLoaded extends TratamientoState {
  final List<Tratamiento> tratamientos;
  const TratamientoLoaded(this.tratamientos);
}

class TratamientoError extends TratamientoState {
  final String message;
  const TratamientoError(this.message);
}
