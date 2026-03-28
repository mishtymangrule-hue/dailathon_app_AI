import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:dailathon_dialer/core/models/contact.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

part 'dialer_event.dart';
part 'dialer_state.dart';

/// DialerBloc manages dialer screen state including number input, T9 suggestions, and SIM selection.
class DialerBloc extends Bloc<DialerEvent, DialerState> {
  DialerBloc(
    this._callMethodChannel,
  ) : super(const DialerInitial()) {
    on<DialerStarted>(_onDialerStarted);
    on<NumberInput>(_onNumberInput);
    on<BackspacePressed>(_onBackspacePressed);
    on<ClearPressed>(_onClearPressed);
    on<CallInitiated>(_onCallInitiated);
    on<SimSlotSelected>(_onSimSlotSelected);
    on<T9SearchPerformed>(_onT9SearchPerformed);
    on<NumberChanged>(_onNumberChanged);
    on<SpeedDialLongPress>(_onSpeedDialLongPress);
    on<SpeedDialAssigned>((event, emit) {});
    on<SpeedDialRemoved>((event, emit) {});
  }

  final CallMethodChannel _callMethodChannel;

  Future<void> _onDialerStarted(
    DialerStarted event,
    Emitter<DialerState> emit,
  ) async {
    try {
      final sims = await _callMethodChannel.getSimSlots();
      emit(DialerActive(availableSims: sims));
    } catch (_) {
      emit(const DialerActive());
    }
  }

  Future<void> _onNumberInput(
    NumberInput event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) {
      emit(const DialerActive(currentNumber: ''));
    }

    final currentState = state as DialerActive;
    final newNumber = currentState.currentNumber + event.digit;

    // Perform T9 search
    final suggestions = await _searchContacts(newNumber);

    emit(
      DialerActive(
        currentNumber: newNumber,
        selectedSimSlot: currentState.selectedSimSlot,
        contactSuggestions: suggestions,
      ),
    );
  }

  Future<void> _onBackspacePressed(
    BackspacePressed event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) return;

    final currentState = state as DialerActive;
    if (currentState.currentNumber.isEmpty) return;

    final newNumber = currentState.currentNumber.substring(0, currentState.currentNumber.length - 1);
    emit(
      DialerActive(
        currentNumber: newNumber,
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
    if (currentState.currentNumber.isEmpty) return;

    // Show loading overlay on the dialer screen while the call is being
    // submitted to the OS. This does NOT navigate away yet.
    emit(DialerPlacingCall(
      number: currentState.currentNumber,
      simSlot: currentState.selectedSimSlot,
    ));

    try {
      await _callMethodChannel.dial(
        currentState.currentNumber,
        simSlot: currentState.selectedSimSlot,
      );
      // dial() returned without error — the OS accepted the call.
      // NOW navigate to /in-call.
      emit(DialerCalling(
        number: currentState.currentNumber,
        simSlot: currentState.selectedSimSlot,
      ));
    } catch (e) {
      // Call failed — go back to dialer and show error snackbar.
      emit(DialerError(error: e.toString()));
      emit(DialerActive(
        currentNumber: currentState.currentNumber,
        selectedSimSlot: currentState.selectedSimSlot,
        availableSims: currentState.availableSims,
      ));
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
        currentNumber: currentState.currentNumber,
        selectedSimSlot: event.simSlot,
      ),
    );
  }

  // Speed dial long-press: handled natively via speed_dial_method_channel.
  void _onSpeedDialLongPress(SpeedDialLongPress event, Emitter<DialerState> emit) {}

  Future<void> _onT9SearchPerformed(
    T9SearchPerformed event,
    Emitter<DialerState> emit,
  ) async {
    if (state is! DialerActive) return;

    final currentState = state as DialerActive;

    final suggestions = await _searchContacts(currentState.currentNumber);
    emit(
      DialerActive(
        currentNumber: currentState.currentNumber,
        selectedSimSlot: currentState.selectedSimSlot,
        contactSuggestions: suggestions,
      ),
    );
  }

  Future<void> _onNumberChanged(
    NumberChanged event,
    Emitter<DialerState> emit,
  ) async {
    final selectedSim = state is DialerActive ? (state as DialerActive).selectedSimSlot : 0;
    final suggestions = event.number.length >= 2 ? await _searchContacts(event.number) : <Contact>[];
    emit(
      DialerActive(
        currentNumber: event.number,
        selectedSimSlot: selectedSim,
        contactSuggestions: suggestions,
      ),
    );
  }

  /// T9 search: match digits against contact names and numbers
  Future<List<Contact>> _searchContacts(String digits) async {
    if (digits.isEmpty) return [];
    try {
      final contacts = await fc.FlutterContacts.getContacts(withProperties: true, withPhoto: false);
      final results = <Contact>[];
      for (final c in contacts) {
        if (results.length >= 5) break;
        // Match against phone numbers
        final numberMatch = c.phones.any((p) => p.number.replaceAll(RegExp(r'[^\d]'), '').contains(digits));
        // Match against T9 name mapping
        final nameDigits = _nameToT9(c.displayName);
        final nameMatch = nameDigits.contains(digits);
        if (numberMatch || nameMatch) {
          results.add(Contact(
            id: c.id,
            name: c.displayName,
            phoneNumber: c.phones.isNotEmpty ? c.phones.first.number : '',
          ));
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  static String _nameToT9(String name) {
    const t9Map = {
      'a': '2', 'b': '2', 'c': '2',
      'd': '3', 'e': '3', 'f': '3',
      'g': '4', 'h': '4', 'i': '4',
      'j': '5', 'k': '5', 'l': '5',
      'm': '6', 'n': '6', 'o': '6',
      'p': '7', 'q': '7', 'r': '7', 's': '7',
      't': '8', 'u': '8', 'v': '8',
      'w': '9', 'x': '9', 'y': '9', 'z': '9',
    };
    return name.toLowerCase().split('').map((c) => t9Map[c] ?? '').join();
  }
}
