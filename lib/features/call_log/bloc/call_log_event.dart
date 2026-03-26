part of 'call_log_bloc.dart';

abstract class CallLogEvent extends Equatable {
  const CallLogEvent();

  @override
  List<Object?> get props => [];
}

class CallLogRequested extends CallLogEvent {
  const CallLogRequested();
}

class CallLogFiltered extends CallLogEvent {
  const CallLogFiltered(this.phoneNumber);
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class CallLogEntryDeleted extends CallLogEvent {
  const CallLogEntryDeleted(this.entryId);
  final String entryId;

  @override
  List<Object?> get props => [entryId];
}

class CallLogCleared extends CallLogEvent {
  const CallLogCleared();
}
