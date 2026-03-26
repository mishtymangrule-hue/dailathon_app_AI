import 'package:dailathon_dialer/core/models/call_log_entry.dart';
import 'package:dailathon_dialer/core/repositories/call_log_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'call_log_event.dart';
part 'call_log_state.dart';

/// CallLogBloc manages call history display, filtering, and deletion.
class CallLogBloc extends Bloc<CallLogEvent, CallLogState> {
  CallLogBloc(this._callLogRepository) : super(const CallLogLoading()) {
    on<CallLogRequested>(_onCallLogRequested);
    on<CallLogFiltered>(_onCallLogFiltered);
    on<CallLogTypeFiltered>(_onCallLogTypeFiltered);
    on<CallLogEntryDeleted>(_onCallLogEntryDeleted);
    on<CallLogCleared>(_onCallLogCleared);
  }

  final CallLogRepository _callLogRepository;

  Future<void> _onCallLogRequested(
    CallLogRequested event,
    Emitter<CallLogState> emit,
  ) async {
    try {
      emit(const CallLogLoading());
      final callLog = await _callLogRepository.getCallLog();
      emit(CallLogLoaded(entries: callLog));
    } catch (e) {
      emit(CallLogError(error: e.toString()));
    }
  }

  Future<void> _onCallLogFiltered(
    CallLogFiltered event,
    Emitter<CallLogState> emit,
  ) async {
    try {
      if (event.phoneNumber.isEmpty) {
        // Load full log
        final callLog = await _callLogRepository.getCallLog();
        emit(CallLogLoaded(entries: callLog));
      } else {
        // Filter by phone number
        final filtered = await _callLogRepository.getCallsWithNumber(event.phoneNumber);
        emit(CallLogLoaded(entries: filtered));
      }
    } catch (e) {
      emit(CallLogError(error: e.toString()));
    }
  }

  Future<void> _onCallLogTypeFiltered(
    CallLogTypeFiltered event,
    Emitter<CallLogState> emit,
  ) async {
    try {
      final all = await _callLogRepository.getCallLog();
      if (event.type == 'all') {
        emit(CallLogLoaded(entries: all));
      } else {
        final typeMap = {'missed': 3, 'outgoing': 2, 'incoming': 1};
        final typeCode = typeMap[event.type];
        final filtered = typeCode == null
            ? all
            : all.where((e) => e.type == typeCode).toList();
        emit(CallLogLoaded(entries: filtered));
      }
    } catch (e) {
      emit(CallLogError(error: e.toString()));
    }
  }

  Future<void> _onCallLogEntryDeleted(
    CallLogEntryDeleted event,
    Emitter<CallLogState> emit,
  ) async {
    try {
      await _callLogRepository.deleteEntry(event.entryId);
      // Refresh call log
      final callLog = await _callLogRepository.getCallLog();
      emit(CallLogLoaded(entries: callLog));
    } catch (e) {
      emit(CallLogError(error: e.toString()));
    }
  }

  Future<void> _onCallLogCleared(
    CallLogCleared event,
    Emitter<CallLogState> emit,
  ) async {
    try {
      await _callLogRepository.clearCallLog();
      emit(const CallLogLoaded(entries: []));
    } catch (e) {
      emit(CallLogError(error: e.toString()));
    }
  }
}
