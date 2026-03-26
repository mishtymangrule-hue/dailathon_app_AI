part of 'dialer_bloc.dart';

abstract class DialerState extends Equatable {
  const DialerState();

  @override
  List<Object?> get props => [];
}

class DialerInitial extends DialerState {
  const DialerInitial();
}

class DialerActive extends DialerState {
  const DialerActive({
    this.currentNumber = '',
    this.selectedSimSlot = 0,
    this.contactSuggestions = const [],
    this.availableSims = const [],
  });

  final String currentNumber;
  final int selectedSimSlot;
  final List<Contact> contactSuggestions;
  final List<dynamic> availableSims;

  @override
  List<Object?> get props => [currentNumber, selectedSimSlot, contactSuggestions, availableSims];
}

class DialerCalling extends DialerState {
  const DialerCalling();
}

class DialerError extends DialerState {
  const DialerError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
