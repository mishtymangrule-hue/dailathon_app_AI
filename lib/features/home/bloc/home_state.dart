part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  const HomeLoaded({required this.isDefaultDialer});

  final bool isDefaultDialer;

  @override
  List<Object?> get props => [isDefaultDialer];
}

class HomeError extends HomeState {
  const HomeError({required this.error});

  final String error;

  @override
  List<Object?> get props => [error];
}
