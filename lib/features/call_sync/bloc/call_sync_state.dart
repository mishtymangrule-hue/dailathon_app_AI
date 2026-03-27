part of 'call_sync_bloc.dart';

abstract class CallSyncState {
  const CallSyncState();
}

class CallSyncIdle extends CallSyncState {
  const CallSyncIdle();
}

class CallSyncFormLoading extends CallSyncState {
  const CallSyncFormLoading();
}

class CallSyncFormReady extends CallSyncState {
  const CallSyncFormReady({
    required this.callId,
    required this.phoneNumber,
    required this.degrees, required this.responses, this.contactId,
    this.selectedDegree,
    this.availablePrograms = const [],
    this.selectedProgram,
    this.selectedResponse,
    this.availableSubResponses = const [],
    this.selectedSubResponse,
  });

  final String callId;
  final String phoneNumber;
  final String? contactId;
  final List<DegreeOption> degrees;
  final List<ResponseOption> responses;
  final DegreeOption? selectedDegree;
  final List<ProgramOption> availablePrograms;
  final ProgramOption? selectedProgram;
  final ResponseOption? selectedResponse;
  final List<SubResponseOption> availableSubResponses;
  final SubResponseOption? selectedSubResponse;

  bool get isSubmittable =>
      selectedDegree != null &&
      selectedProgram != null &&
      selectedResponse != null;

  CallSyncFormReady copyWith({
    DegreeOption? selectedDegree,
    List<ProgramOption>? availablePrograms,
    ProgramOption? selectedProgram,
    ResponseOption? selectedResponse,
    List<SubResponseOption>? availableSubResponses,
    SubResponseOption? selectedSubResponse,
    bool clearProgram = false,
    bool clearResponse = false,
    bool clearSubResponse = false,
  }) =>
      CallSyncFormReady(
        callId: callId,
        phoneNumber: phoneNumber,
        contactId: contactId,
        degrees: degrees,
        responses: responses,
        selectedDegree: selectedDegree ?? this.selectedDegree,
        availablePrograms: availablePrograms ?? this.availablePrograms,
        selectedProgram: clearProgram ? null : (selectedProgram ?? this.selectedProgram),
        selectedResponse: clearResponse ? null : (selectedResponse ?? this.selectedResponse),
        availableSubResponses:
            availableSubResponses ?? this.availableSubResponses,
        selectedSubResponse:
            clearSubResponse ? null : (selectedSubResponse ?? this.selectedSubResponse),
      );
}

class CallSyncSubmitting extends CallSyncState {
  const CallSyncSubmitting();
}

class CallSyncSuccess extends CallSyncState {
  const CallSyncSuccess();
}

class CallSyncError extends CallSyncState {
  const CallSyncError(this.message);
  final String message;
}
