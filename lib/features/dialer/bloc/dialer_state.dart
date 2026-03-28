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

/// Shown as a loading overlay while the OS call is being submitted.
/// Does NOT trigger navigation to /in-call.
class DialerPlacingCall extends DialerState {
  const DialerPlacingCall({this.number = '', this.simSlot = 0});
  final String number;
  final int simSlot;

  @override
  List<Object?> get props => [number, simSlot];
}

/// Emitted AFTER dial() returns without error. Triggers navigation to /in-call.
class DialerCalling extends DialerState {
  const DialerCalling({this.number = '', this.simSlot = 0});
  final String number;
  final int simSlot;

  @override
  List<Object?> get props => [number, simSlot];
}

class DialerError extends DialerState {
  const DialerError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
