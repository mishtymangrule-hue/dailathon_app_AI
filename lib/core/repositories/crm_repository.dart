import 'package:dailathon_dialer/core/api/api_client.dart';

/// Models for CRM responses
class CrmContact {

  CrmContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.address,
    this.createdAt,
    this.customFields,
  });

  factory CrmContact.fromJson(Map<String, dynamic> json) {
    return CrmContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String?,
      address: json['address'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      customFields: json['customFields'] as Map<String, dynamic>?,
    );
  }
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String? address;
  final DateTime? createdAt;
  final Map<String, dynamic>? customFields;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'address': address,
        'createdAt': createdAt?.toIso8601String(),
        'customFields': customFields,
      };
}

class CrmCall {

  CrmCall({
    required this.id,
    required this.contactId,
    required this.phoneNumber,
    required this.callTime,
    required this.duration,
    required this.direction,
    required this.status,
    this.notes,
  });

  factory CrmCall.fromJson(Map<String, dynamic> json) {
    return CrmCall(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      phoneNumber: json['phoneNumber'] as String,
      callTime: DateTime.parse(json['callTime'] as String),
      duration: json['duration'] as int,
      direction: json['direction'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }
  final String id;
  final String contactId;
  final String phoneNumber;
  final DateTime callTime;
  final int duration;
  final String direction; // 'inbound' or 'outbound'
  final String status; // 'completed', 'missed', 'declined'
  final String? notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactId': contactId,
        'phoneNumber': phoneNumber,
        'callTime': callTime.toIso8601String(),
        'duration': duration,
        'direction': direction,
        'status': status,
        'notes': notes,
      };
}

/// Repository for CRM operations.
/// 
/// Provides high-level business logic for interacting with the Dailathon CRM backend.
class CrmRepository {

  CrmRepository({required ApiClient apiClient}) : _apiClient = apiClient;
  final ApiClient _apiClient;

  // ============ Contact Management ============

  /// Get all contacts
  Future<List<CrmContact>> getContacts({
    int page = 1,
    int pageSize = 100,
    String? searchQuery,
  }) async {
    try {
      final response = await _apiClient.get(
        '/contacts?page=$page&pageSize=$pageSize${searchQuery != null ? '&search=$searchQuery' : ''}',
      );

      final contacts = (response['data'] as List?)
              ?.map((c) => CrmContact.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [];
      return contacts;
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single contact by ID
  Future<CrmContact> getContact(String contactId) async {
    try {
      final response = await _apiClient.get('/contacts/$contactId');
      return CrmContact.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new contact
  Future<CrmContact> createContact({
    required String name,
    required String phoneNumber,
    String? email,
    String? address,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final response = await _apiClient.post(
        '/contacts',
        data: {
          'name': name,
          'phoneNumber': phoneNumber,
          'email': email,
          'address': address,
          'customFields': customFields,
        },
      );

      return CrmContact.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing contact
  Future<CrmContact> updateContact(
    String contactId, {
    String? name,
    String? email,
    String? address,
    Map<String, dynamic>? customFields,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (email != null) data['email'] = email;
      if (address != null) data['address'] = address;
      if (customFields != null) data['customFields'] = customFields;

      final response = await _apiClient.put(
        '/contacts/$contactId',
        data: data,
      );

      return CrmContact.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _apiClient.delete('/contacts/$contactId');
    } catch (e) {
      rethrow;
    }
  }

  // ============ Call Logging ============

  /// Log a call to the CRM
  Future<CrmCall> logCall({
    required String contactId,
    required String phoneNumber,
    required int duration,
    required String direction,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/calls',
        data: {
          'contactId': contactId,
          'phoneNumber': phoneNumber,
          'duration': duration,
          'direction': direction,
          'status': status,
          'notes': notes,
          'callTime': DateTime.now().toIso8601String(),
        },
      );

      return CrmCall.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get call history for a contact
  Future<List<CrmCall>> getCallHistory(
    String contactId, {
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/contacts/$contactId/calls?limit=$limit',
      );

      final calls = (response['data'] as List?)
              ?.map((c) => CrmCall.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [];
      return calls;
    } catch (e) {
      rethrow;
    }
  }

  /// Get all recent calls
  Future<List<CrmCall>> getRecentCalls({
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/calls?limit=$limit&sort=-callTime',
      );

      final calls = (response['data'] as List?)
              ?.map((c) => CrmCall.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [];
      return calls;
    } catch (e) {
      rethrow;
    }
  }

  // ============ Search & Lookup ============

  /// Search contacts by name, email, or phone number
  Future<List<CrmContact>> searchContacts(String query) async {
    try {
      return await getContacts(searchQuery: query);
    } catch (e) {
      rethrow;
    }
  }

  /// Lookup contact by phone number
  Future<CrmContact?> lookupContactByPhone(String phoneNumber) async {
    try {
      final response = await _apiClient.get(
        '/contacts/lookup?phoneNumber=$phoneNumber',
      );

      if (response['data'] == null) return null;
      return CrmContact.fromJson(response['data'] as Map<String, dynamic>);
    } catch (e) {
      // 404 means contact not found, which is OK
      if (e is ApiException && e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  // ============ Account Management ============

  /// Get current user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiClient.get('/me');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.put(
        '/me',
        data: updates,
      );
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      rethrow;
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> getUsageStatistics() async {
    try {
      final response = await _apiClient.get('/analytics/usage');
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      rethrow;
    }
  }
}
