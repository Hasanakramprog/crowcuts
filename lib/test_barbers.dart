import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  final snapshot = await db.collection('barbers').get();
  
  print('================= BARBERS IN FIRESTORE =================');
  for (var doc in snapshot.docs) {
    print('ID: ${doc.id}');
    print('Name: ${doc.data()['name']}');
    print('AvatarUrl: "${doc.data()['avatarUrl']}"');
    print('----------------------------------------------------');
  }
  print('========================================================');
}
