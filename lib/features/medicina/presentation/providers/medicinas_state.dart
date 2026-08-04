import 'package:equatable/equatable.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/entities/medicina.dart';
import 'package:salud_dental_clinic_management/features/medicina/domain/enums/efecto_secundario.dart';

abstract class MedicinasState extends Equatable {
  const MedicinasState();

  @override
  List<Object?> get props => [];
}

class MedicinasInitial extends MedicinasState {}

class MedicinasLoading extends MedicinasState {}

class MedicinasLoaded extends MedicinasState {
  final List<Medicina> allMedicinas;
  final List<Medicina> filteredMedicinas;
  final String searchQuery;
  final Set<EfectoSecundario> selectedEfectos;

  const MedicinasLoaded({
    required this.allMedicinas,
    required this.filteredMedicinas,
    this.searchQuery = '',
    this.selectedEfectos = const {},
  });

  MedicinasLoaded copyWith({
    List<Medicina>? allMedicinas,
    List<Medicina>? filteredMedicinas,
    String? searchQuery,
    Set<EfectoSecundario>? selectedEfectos,
  }) {
    return MedicinasLoaded(
      allMedicinas: allMedicinas ?? this.allMedicinas,
      filteredMedicinas: filteredMedicinas ?? this.filteredMedicinas,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedEfectos: selectedEfectos ?? this.selectedEfectos,
    );
  }

  @override
  List<Object?> get props => [
    allMedicinas,
    filteredMedicinas,
    searchQuery,
    selectedEfectos,
  ];
}

class MedicinasError extends MedicinasState {
  final String message;
  const MedicinasError(this.message);

  @override
  List<Object?> get props => [message];
}
