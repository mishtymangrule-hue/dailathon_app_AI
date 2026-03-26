import 'package:flutter/services.dart';
import '../models/call_info.dart';
import '../models/multi_call_state.dart';

class CallEventChannel {
  static const _channel = EventChannel('com.mangrule.dailathon/call_events');

  Stream<CallInfo> get callStateStream => _channel
      .receiveBroadcastStream()
      .map((event) => CallInfo.fromMap(Map<String, dynamic>.from(event as Map)));

  Stream<MultiCallState> get multiCallStateStream => _channel
      .receiveBroadcastStream()
      .map((event) => MultiCallState.fromMap(Map<String, dynamic>.from(event as Map)));
}
