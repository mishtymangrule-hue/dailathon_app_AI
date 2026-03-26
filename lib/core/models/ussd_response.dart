import 'package:equatable/equatable.dart';

/// Represents a USSD response from the device's telephony system.
/// 
/// Contains information about whether the USSD request was successful,
/// the response text, and any error details if applicable.
class UssdResponse extends Equatable {

  /// Create a UssdResponse from a Map.
  factory UssdResponse.fromMap(Map<String, dynamic> map) {
    return UssdResponse(
      success: map['success'] ?? false,
      code: map['code'] ?? '',
      response: map['response'],
      failureCode: map['failureCode'],
      message: map['message'],
      timestamp: map['timestamp'],
      type: map['type'] ?? 'ussd',
      codeType: map['codeType'],
      result: map['result'],
    );
  }
  const UssdResponse({
    required this.success,
    required this.code,
    this.response,
    this.failureCode,
    this.message,
    this.timestamp,
    this.type = 'ussd',
    this.codeType,
    this.result,
  });

  /// Whether the USSD request was successful.
  final bool success;

  /// The USSD code that was sent (e.g., "*121#").
  final String code;

  /// The response text from the USSD request (if successful).
  /// 
  /// This is the text displayed to the user by the telecom operator.
  /// Examples: "Your balance is 100 TZS", "Service activated".
  final String? response;

  /// The error code if the USSD request failed.
  /// 
  /// Common failure codes:
  /// - 0: Unknown error
  /// - 1: No route to destination
  /// - 2: Unavailable
  /// - 3: Network timeout
  final int? failureCode;

  /// Human-readable error message if the request failed.
  final String? message;

  /// Timestamp when the response was received (milliseconds since epoch).
  final int? timestamp;

  /// Type of response: "ussd" for regular USSD, "interactive" for interactive codes.
  final String type;

  /// Type of interactive code if type is "interactive" (e.g., "IMEI", "DEVICE_INFO").
  final String? codeType;

  /// Result of interactive code if type is "interactive".
  final String? result;

  /// Convert UssdResponse to Map.
  Map<String, dynamic> toMap() => {
      'success': success,
      'code': code,
      'response': response,
      'failureCode': failureCode,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'codeType': codeType,
      'result': result,
    };

  @override
  List<Object?> get props => [
    success,
    code,
    response,
    failureCode,
    message,
    timestamp,
    type,
    codeType,
    result,
  ];

  @override
  String toString() {
    if (type == 'interactive') {
      return 'UssdResponse(type: interactive, codeType: $codeType, result: $result)';
    }
    return 'UssdResponse(success: $success, code: $code, response: $response, failureCode: $failureCode, message: $message)';
  }
}
