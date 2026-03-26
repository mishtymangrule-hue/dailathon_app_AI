part of 'call_sync_bloc.dart';

abstract class CallSyncEvent {
  const CallSyncEvent();
}

class CallSyncFormRequested extends CallSyncEvent {
  const CallSyncFormRequested({
    required this.callId,
    required this.phoneNumber,
    this.contactId,
  });
  final String callId;
  final String phoneNumber;
  final String? contactId;
}

class SyncDegreeSelected extends CallSyncEvent {
  const SyncDegreeSelected(this.degree);
  final DegreeOption degree;
}

class SyncProgramSelected extends CallSyncEvent {
  const SyncProgramSelected(this.program);
  final ProgramOption program;
}

class SyncResponseSelected extends CallSyncEvent {
  const SyncResponseSelected(this.response);
  final ResponseOption response;
}

class SyncSubResponseSelected extends CallSyncEvent {
  const SyncSubResponseSelected(this.subResponse);
  final SubResponseOption subResponse;
}

class CallSyncSubmitted extends CallSyncEvent {
  const CallSyncSubmitted();
}
