import 'package:equatable/equatable.dart';
import 'package:capa/domain/entities/capa.dart';

abstract class CapaState extends Equatable {
  const CapaState();

  @override
  List<Object?> get props => [];
}

// State awal
class CapaInitial extends CapaState {}

// State loading
class CapaLoading extends CapaState {}

// State berhasil load list CAPA
class CapaLoaded extends CapaState {
  final List<Capa> capas;

  const CapaLoaded({required this.capas});

  @override
  List<Object?> get props => [capas];
}

// State berhasil load detail CAPA
class CapaDetailLoaded extends CapaState {
  final Capa capa;

  const CapaDetailLoaded({required this.capa});

  @override
  List<Object?> get props => [capa];
}

// State berhasil create CAPA
class CapaCreated extends CapaState {
  final Capa capa;

  const CapaCreated({required this.capa});

  @override
  List<Object?> get props => [capa];
}

// State berhasil closeout CAPA
class CapaClosed extends CapaState {}

// State error
class CapaError extends CapaState {
  final String message;

  const CapaError({required this.message});

  @override
  List<Object?> get props => [message];
}