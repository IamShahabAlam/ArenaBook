import 'dart:convert';

import '../getx_service/storage_service.dart';

// Moves cached data from an old prefs key to a new one (use when renaming AppCache keys between releases).
class MigrationService {
  static Future<void> migrateKey({required String oldKey, required String newKey}) async {
    var prefs = StorageService.to;

    // Check if the old key exists
    if (prefs.containsKey(oldKey)) {
      // Retrieve data from the old key as a string
      String dataString = prefs.getString(oldKey);

      // Deserialize the string into a Map
      Map<String, dynamic> data = json.decode(dataString);

      // Save the data using the new key
      await prefs.setString(newKey, json.encode(data));

      // Optionally, remove the old key to clean up
      await prefs.remove(oldKey);
    }
  }
}
