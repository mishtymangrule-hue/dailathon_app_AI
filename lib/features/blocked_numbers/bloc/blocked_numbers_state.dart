part of 'blocked_numbers_bloc.dart';

abstract class BlockedNumbersState extends Equatable {
  const BlockedNumbersState();

  @override
  List<Object?> get props => [];
}

class BlockedNumbersLoading extends BlockedNumbersState {
  const BlockedNumbersLoading();
}

class BlockedNumbersLoaded extends BlockedNumbersState {
  const BlockedNumbersLoaded({required this.blockedNumbers});
  final List<String> blockedNumbers;

  @override
  List<Object?> get props => [blockedNumbers];
}

class BlockedNumbersError extends BlockedNumbersState {
  const BlockedNumbersError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
