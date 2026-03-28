import 'package:flutter/services.dart';
import '../models/call_info.dart';
import '../models/multi_call_state.dart';

class CallEventChannel {
  static const _channel = EventChannel('com.mangrule.dailathon/call_events');

  Stream<MultiCallState> get multiCallStateStream => _channel
      .receiveBroadcastStream()
      .map((event) => MultiCallState.fromMap(Map<String, dynamic>.from(event as Map)));

    // Keep a compatibility stream for older callers, but avoid creating a second
    // EventChannel subscription by deriving from the canonical multi-call stream.
    Stream<CallInfo> get callStateStream =>
        multiCallStateStream
          .map((state) => state.activeCall)
          .where((call) => call != null)
          .cast<CallInfo>();
}
