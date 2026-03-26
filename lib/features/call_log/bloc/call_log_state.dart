part of 'call_log_bloc.dart';

abstract class CallLogState extends Equatable {
  const CallLogState();

  @override
  List<Object?> get props => [];
}

class CallLogLoading extends CallLogState {
  const CallLogLoading();
}

class CallLogLoaded extends CallLogState {
  const CallLogLoaded({required this.entries});
  final List<CallLogEntry> entries;

  @override
  List<Object?> get props => [entries];
}

class CallLogError extends CallLogState {
  const CallLogError({required this.error});
  final String error;

  @override
  List<Object?> get props => [error];
}
