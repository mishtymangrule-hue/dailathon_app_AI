part of 'blocked_numbers_bloc.dart';

abstract class BlockedNumbersEvent extends Equatable {
  const BlockedNumbersEvent();

  @override
  List<Object?> get props => [];
}

class BlockedNumbersRequested extends BlockedNumbersEvent {
  const BlockedNumbersRequested();
}

class NumberBlocked extends BlockedNumbersEvent {
  const NumberBlocked(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class NumberUnblocked extends BlockedNumbersEvent {
  const NumberUnblocked(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}
