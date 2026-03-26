import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/call_sync_models.dart';
import '../../../core/repositories/crm_repository.dart';

part 'call_sync_event.dart';
part 'call_sync_state.dart';

class CallSyncBloc extends Bloc<CallSyncEvent, CallSyncState> {
  CallSyncBloc({required CrmRepository crmRepository})
      : _crm = crmRepository,
        super(const CallSyncIdle()) {
    on<CallSyncFormRequested>(_onFormRequested);
    on<SyncDegreeSelected>(_onDegreeSelected);
    on<SyncProgramSelected>(_onProgramSelected);
    on<SyncResponseSelected>(_onResponseSelected);
    on<SyncSubResponseSelected>(_onSubResponseSelected);
    on<CallSyncSubmitted>(_onSubmitted);
  }

  final CrmRepository _crm;

  Future<void> _onFormRequested(
    CallSyncFormRequested event,
    Emitter<CallSyncState> emit,
  ) async {
    emit(const CallSyncFormLoading());
    try {
      final degreesRaw = await _crm.getDegrees();
      final responsesRaw = await _crm.getResponses();
      final degrees =
          degreesRaw.map(DegreeOption.fromJson).toList();
      final responses =
          responsesRaw.map(ResponseOption.fromJson).toList();
      emit(CallSyncFormReady(
        callId: event.callId,
        phoneNumber: event.phoneNumber,
        contactId: event.contactId,
        degrees: degrees,
        responses: responses,
      ));
    } catch (e) {
      emit(CallSyncError(e.toString()));
    }
  }

  Future<void> _onDegreeSelected(
    SyncDegreeSelected event,
    Emitter<CallSyncState> emit,
  ) async {
    final current = state as CallSyncFormReady;
    // Reset downstream selections when degree changes
    emit(current.copyWith(
      selectedDegree: event.degree,
      availablePrograms: [],
      clearProgram: true,
    ));
    try {
      final programsRaw = await _crm.getProgramsForDegree(event.degree.id);
      final programs = programsRaw.map(ProgramOption.fromJson).toList();
      final updated = state as CallSyncFormReady;
      emit(updated.copyWith(availablePrograms: programs));
    } catch (_) {
      // Programs failed to load — leave list empty, user can retry
    }
  }

  void _onProgramSelected(
    SyncProgramSelected event,
    Emitter<CallSyncState> emit,
  ) {
    final current = state as CallSyncFormReady;
    emit(current.copyWith(selectedProgram: event.program));
  }

  Future<void> _onResponseSelected(
    SyncResponseSelected event,
    Emitter<CallSyncState> emit,
  ) async {
    final current = state as CallSyncFormReady;
    emit(current.copyWith(
      selectedResponse: event.response,
      availableSubResponses: [],
      clearSubResponse: true,
    ));
    try {
      final subRaw = await _crm.getSubResponses(event.response.id);
      final subs = subRaw.map(SubResponseOption.fromJson).toList();
      final updated = state as CallSyncFormReady;
      emit(updated.copyWith(availableSubResponses: subs));
    } catch (_) {
      // Sub-responses unavailable — not required
    }
  }

  void _onSubResponseSelected(
    SyncSubResponseSelected event,
    Emitter<CallSyncState> emit,
  ) {
    final current = state as CallSyncFormReady;
    emit(current.copyWith(selectedSubResponse: event.subResponse));
  }

  Future<void> _onSubmitted(
    CallSyncSubmitted event,
    Emitter<CallSyncState> emit,
  ) async {
    final current = state;
    if (current is! CallSyncFormReady || !current.isSubmittable) return;

    emit(const CallSyncSubmitting());
    try {
      await _crm.syncCall({
        'callId': current.callId,
        'phoneNumber': current.phoneNumber,
        if (current.contactId != null) 'contactId': current.contactId,
        'degreeId': current.selectedDegree!.id,
        'programId': current.selectedProgram!.id,
        'responseId': current.selectedResponse!.id,
        if (current.selectedSubResponse != null)
          'subResponseId': current.selectedSubResponse!.id,
        'syncedAt': DateTime.now().toIso8601String(),
      });
      emit(const CallSyncSuccess());
    } catch (e) {
      emit(CallSyncError(e.toString()));
    }
  }
}
