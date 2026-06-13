import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Crown Cuts Firestore provider — uses the 'crown-cuts' database.
/// Configured with settings to ensure real-time sync across devices.
class _FirestoreInstance {
  static FirebaseFirestore? _instance;
  
  static FirebaseFirestore get instance {
    if (_instance == null) {
      _instance = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'crown-cuts',
      );
      
      // Configure settings ONCE for reliable cross-device synchronization
      _instance!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
    
    return _instance!;
  }
}

FirebaseFirestore get firestore => _FirestoreInstance.instance;
