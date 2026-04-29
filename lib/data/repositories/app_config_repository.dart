import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigRepository {
  final FirebaseFirestore _firestore;

  AppConfigRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch the version info from the app_config/version_info document.
  Future<Map<String, dynamic>?> getVersionInfo() async {
    try {
      final doc = await _firestore.collection('app_config').doc('version_info').get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      // In case of error (e.g., no internet, or offline), just return null.
      return null;
    }
  }
}
