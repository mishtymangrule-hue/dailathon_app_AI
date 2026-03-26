import 'package:flutter/services.dart';
import '../models/call_info.dart';

class CallMethodChannel {
  static const _channel = MethodChannel('com.mangrule.dailathon/call_commands');

  Future<void> dial(String number, {int? simSlot}) =>
      _channel.invokeMethod('dial', {'number': number, 'simSlot': simSlot});

  Future<void> answer() => _channel.invokeMethod('answer');

  Future<void> hangUp() => _channel.invokeMethod('hangUp');

  Future<void> hold() => _channel.invokeMethod('hold');

  Future<void> unhold() => _channel.invokeMethod('unhold');

  Future<void> mute(bool isMuted) =>
      _channel.invokeMethod('mute', {'isMuted': isMuted});

  Future<void> setSpeaker(bool enabled) =>
      _channel.invokeMethod('setSpeaker', {'enabled': enabled});

  Future<void> setBluetoothAudio(bool enabled) =>
      _channel.invokeMethod('setBluetoothAudio', {'enabled': enabled});

  Future<List<String>> getAvailableAudioRoutes() async {
    final result = await _channel.invokeMethod('getAvailableAudioRoutes');
    return List<String>.from(result);
  }

  Future<void> sendDtmf(String digit) =>
      _channel.invokeMethod('sendDtmf', {'digit': digit});

  Future<void> mergeActiveCalls() =>
      _channel.invokeMethod('mergeActiveCalls');

  Future<void> swapCalls() => _channel.invokeMethod('swapCalls');

  Future<void> separateFromConference(String callId) =>
      _channel.invokeMethod('separateFromConference', {'callId': callId});

  Future<bool> checkDefaultDialer() async =>
      await _channel.invokeMethod('checkDefaultDialer') as bool;

  Future<void> requestDefaultDialer() =>
      _channel.invokeMethod('requestDefaultDialer');

  Future<List<Map>> getSimSlots() async {
    final result = await _channel.invokeMethod('getSimSlots');
    return List<Map>.from(result);
  }

  Future<void> setCallForwarding({
    required bool enabled,
    required int type, String? number,
  }) =>
      _channel.invokeMethod('setCallForwarding', {
        'enabled': enabled,
        'number': number,
        'type': type,
      });

  Future<Map> getCallForwardingStatus() async {
    final result = await _channel.invokeMethod('getCallForwardingStatus');
    return Map.from(result);
  }

  Future<void> enableCallForwarding({
    required String forwardingType,
    required String forwardingNumber,
  }) =>
      _channel.invokeMethod('enableCallForwarding', {
        'forwardingType': forwardingType,
        'forwardingNumber': forwardingNumber,
      });

  Future<void> disableCallForwarding({
    required String forwardingType,
  }) =>
      _channel.invokeMethod('disableCallForwarding', {
        'forwardingType': forwardingType,
      });

  Future<void> setDefaultDialer() =>
      _channel.invokeMethod('setDefaultDialer');

  Future<void> rejectCall() =>
      _channel.invokeMethod('rejectCall');

  Future<void> sendUssd(String code, {int? simSlot}) =>
      _channel.invokeMethod('sendUssd', {'code': code, 'simSlot': simSlot});
}
