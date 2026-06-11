import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Crown Cuts Firestore provider — uses the 'crown-cuts' database.
FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'crown-cuts',
    );
