import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:dailathon_dialer/core/models/contact.dart';
import 'package:dailathon_dialer/core/models/sim_info.dart';

part 'dialer_event.dart';
part 'dialer_state.dart';

/// DialerBloc manages dialer screen state including number input, T9 suggestions, and SIM selection.
class DialerBloc extends Bloc<DialerEvent, DialerState> {
  DialerBloc(
    this._callMethodChannel,
  ) : super(const DialerInitial()) {
    on<NumberInput>(_onNumberInput);
    on<BackspacePressed>(_onBackspacePressed);
    on<ClearPressed>(_onClearPressed);
    on<CallInitiated>(_onCallInitiated);
    on<SimSlotSelected>(_onSimSlotSelected);
    on<T9SearchPerformed>(_onT9SearchPerformed);
  }

  final CallMethodChannel _callMethodChannel;

  Future<void> _onNumberInput(
    NumberInput event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) {
      emit(const DialerActive(number: ''));
    }

    final currentState = state as DialerActive;
    final newNumber = currentState.number + event.digit;

    emit(
      DialerActive(
        number: newNumber,
        selectedSimSlot: currentState.selectedSimSlot,
        suggestions: const [], // TODO: Perform T9 search
      ),
    );
  }

  Future<void> _onBackspacePressed(
    BackspacePressed event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) return;

    final currentState = state as DialerActive;
    if (currentState.number.isEmpty) return;

    final newNumber = currentState.number.substring(0, currentState.number.length - 1);
    emit(
      DialerActive(
        number: newNumber,
        selectedSimSlot: currentState.selectedSimSlot,
      ),
    );
  }

  Future<void> _onClearPressed(
    ClearPressed event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) return;

    final currentState = state as DialerActive;
    emit(DialerActive(selectedSimSlot: currentState.selectedSimSlot));
  }

  Future<void> _onCallInitiated(
    CallInitiated event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) return;

    final currentState = state as DialerActive;
    if (currentState.number.isEmpty) return;

    emit(const DialerCalling());

    try {
      await _callMethodChannel.dial(
        currentState.number,
        simSlot: currentState.selectedSimSlot,
      );
    } catch (e) {
      emit(DialerError(error: e.toString()));
    }
  }

  Future<void> _onSimSlotSelected(
    SimSlotSelected event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) {
      emit(const DialerActive());
    }

    final currentState = state as DialerActive;
    emit(
      DialerActive(
        number: currentState.number,
        selectedSimSlot: event.simSlot,
      ),
    );
  }

  Future<void> _onT9SearchPerformed(
    T9SearchPerformed event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) return;

    final currentState = state as DialerActive;

    // TODO: Perform actual T9 search via ContactsRepository
    emit(
      DialerActive(
        number: currentState.number,
        selectedSimSlot: currentState.selectedSimSlot,
        suggestions: event.suggestions,
      ),
    );
  }
}
