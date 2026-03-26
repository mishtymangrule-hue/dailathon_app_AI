import 'package:flutter/services.dart';
import '../models/ussd_response.dart';

/// EventChannel for receiving USSD responses from native Android code.
/// 
/// Listens to USSD results (both successful responses and failures) sent from
/// the Android UssdManager via UssdEventChannelService.
class UssdEventChannel {
  static const _channel = EventChannel('com.mangrule.dailathon/ussd_events');

  /// Stream of USSD responses from the device.
  /// 
  /// Emits [UssdResponse] objects when:
  /// - A USSD request completes successfully
  /// - A USSD request fails
  /// - An interactive code (like *#06# for IMEI) is executed
  /// 
  /// Example:
  /// ```dart
  /// ussdEventChannel.ussdResponseStream.listen((response) {
  ///   if (response.success) {
  ///     print('USSD Response: ${response.response}');
  ///   } else {
  ///     print('USSD Failed: ${response.message}');
  ///   }
  /// });
  /// ```
  Stream<UssdResponse> get ussdResponseStream => _channel
      .receiveBroadcastStream()
      .map((event) => UssdResponse.fromMap(Map<String, dynamic>.from(event as Map)));
}
