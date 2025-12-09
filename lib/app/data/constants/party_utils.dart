import 'package:uuid/uuid.dart';
import 'package:account_book/app/data/model/party_model.dart';

/// Utility class for handling party ID operations
class PartyIdUtils {
  /// Fetches the ID of a party from the given [PartyModel].
  /// 
  /// If the party model has no ID or invalid ID, it generates a new UUID and updates the model.
  /// This ensures that a valid UUID is always available.
  /// 
  /// Returns the party ID as a String.
  static String fetchPartyId(PartyModel party) {
    if (party.id == null || party.id!.isEmpty) {
      // Generate a new UUID if id is null or empty
      final newId = const Uuid().v4();
      party.id = newId;
      return newId;
    }
    
    // Validate if the existing ID is a valid UUID
    try {
      // Try to parse it as UUID to validate
      // If it fails, it will throw an exception
      Uuid.parse(party.id!);
      return party.id!;
    } catch (_) {
      // Not a valid UUID, generate a new one
      final newId = const Uuid().v4();
      party.id = newId;
      return newId;
    }
  }
  
  /// Converts any string to a valid UUID
  /// 
  /// If the input is null, empty, or not a valid UUID format,
  /// it will generate a new UUID.
  static String toUuid(String? input) {
    if (input == null || input.isEmpty) {
      return const Uuid().v4();
    }
    
    try {
      // Validate if it's already a UUID
      Uuid.parse(input);
      return input;
    } catch (_) {
      // Not a valid UUID, generate a new one
      return const Uuid().v4();
    }
  }
}