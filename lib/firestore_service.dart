import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _lastWriteTimestamp;

  Future<void> writeUserData(Map<String, dynamic> userData) async {
    final currentTime = DateTime.now();
    // Check if more than 1 minute has passed since the last write
    if (_lastWriteTimestamp == null ||
        currentTime.difference(_lastWriteTimestamp!).inMinutes >= 1) {
      // Allow the write
      _lastWriteTimestamp = currentTime;
      // Specify the collection and document ID
      String collectionName = 'ishaan.sid@gmail.com';
      //String documentId = 'user123'; // You can use a unique identifier or let Firestore generate one

      try {
        // Write the data to Firestore
        await _firestore.collection(collectionName).doc().set(userData);
        print('Document successfully written!');
      } catch (error) {
        print('Error writing document: $error');
      }
    } else {
      print('write not allowed within 1 minute of the last write');
    }
  }
}
