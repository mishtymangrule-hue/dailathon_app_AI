import 'package:dailathon_dialer/core/channels/call_method_channel.dart';

/// Repository wrapper for call forwarding via native CallForwardingManager.
class CallForwardingRepository {
  CallForwardingRepository(this._callMethodChannel);

  final CallMethodChannel _callMethodChannel;

  /// Set call forwarding.
  /// [type] maps reason: 0=unconditional, 1=busy, 2=noAnswer, 3=unreachable
  Future<void> setForwarding({
    required String reason,
    required String number,
    required bool enable,
  }) async {
    const reasonTypeMap = {
      'unconditional': 0,
      'busy': 1,
      'noAnswer': 2,
      'unreachable': 3,
    };
    final type = reasonTypeMap[reason] ?? 0;
    try {
      await _callMethodChannel.setCallForwarding(
        enabled: enable,
        type: type,
        number: number,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Query current forwarding settings (via MMI code query).
  /// TODO: Implement when QueryMMI support is added to native layer
  Future<Map<String, String>> getForwardingSettings() async {
    try {
      // TODO: Call native method to query MMI codes
      // Returns map like: {'unconditional': '+1234567890', 'busy': '+1234567890', ...}
      return {};
    } catch (e) {
      rethrow;
    }
  }
}
