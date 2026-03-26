import 'package:flutter/services.dart';
import '../models/speed_dial_entry.dart';

class SpeedDialMethodChannel {
  static const _channel = MethodChannel('com.mangrule.dailathon/speed_dial');

  /// Get speed dial entry at position (1-9).
  Future<SpeedDialEntry?> getSpeedDial(int position) async {
    try {
      final result = await _channel.invokeMethod('getSpeedDial', {'position': position});
      if (result == null) return null;
      return SpeedDialEntry.fromMap(Map<String, dynamic>.from(result));
    } catch (e) {
      throw Exception('Failed to get speed dial: $e');
    }
  }

  /// Get all speed dial assignments.
  Future<List<SpeedDialEntry>> getAllSpeedDials() async {
    try {
      final result = await _channel.invokeMethod('getAllSpeedDials');
      return (result as List).map((e) => SpeedDialEntry.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw Exception('Failed to get all speed dials: $e');
    }
  }

  /// Assign a contact to a speed dial position.
  Future<void> assignSpeedDial({
    required int position,
    required String contactId,
    required String displayName,
    required String phoneNumber,
    String? photoUri,
  }) async {
    try {
      await _channel.invokeMethod('assignSpeedDial', {
        'position': position,
        'contactId': contactId,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoUri': photoUri,
      });
    } catch (e) {
      throw Exception('Failed to assign speed dial: $e');
    }
  }

  /// Remove speed dial assignment.
  Future<void> removeSpeedDial(int position) async {
    try {
      await _channel.invokeMethod('removeSpeedDial', {'position': position});
    } catch (e) {
      throw Exception('Failed to remove speed dial: $e');
    }
  }

  /// Check if position has an assignment.
  Future<bool> hasAssignment(int position) async {
    try {
      final result = await _channel.invokeMethod('hasAssignment', {'position': position}) as bool;
      return result;
    } catch (e) {
      throw Exception('Failed to check assignment: $e');
    }
  }

  /// Get all assigned positions.
  Future<List<int>> getAssignedPositions() async {
    try {
      final result = await _channel.invokeMethod('getAssignedPositions');
      return List<int>.from(result);
    } catch (e) {
      throw Exception('Failed to get assigned positions: $e');
    }
  }

  /// Add contact to favorites.
  Future<void> addFavorite({
    required String contactId,
    required String displayName,
    required String phoneNumber,
    String? photoUri,
  }) async {
    try {
      await _channel.invokeMethod('addFavorite', {
        'contactId': contactId,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'photoUri': photoUri,
      });
    } catch (e) {
      throw Exception('Failed to add favorite: $e');
    }
  }

  /// Remove contact from favorites.
  Future<void> removeFavorite(String contactId) async {
    try {
      await _channel.invokeMethod('removeFavorite', {'contactId': contactId});
    } catch (e) {
      throw Exception('Failed to remove favorite: $e');
    }
  }

  /// Check if contact is favorited.
  Future<bool> isFavorite(String contactId) async {
    try {
      final result = await _channel.invokeMethod('isFavorite', {'contactId': contactId}) as bool;
      return result;
    } catch (e) {
      throw Exception('Failed to check if favorite: $e');
    }
  }

  /// Get all favorite contacts.
  Future<List<ContactFavorite>> getAllFavorites() async {
    try {
      final result = await _channel.invokeMethod('getAllFavorites');
      return (result as List).map((e) => ContactFavorite.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw Exception('Failed to get favorites: $e');
    }
  }
}
