// lib/record_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FetchRecord {
  Future<Map<String, dynamic>> getAllRecords() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }
    String uid = user.uid;

    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref('users/$uid/user_data');
      DataSnapshot snapshot = await ref.get();

      if (!snapshot.exists) {
        return {'allRecords': []};
      }

      Map<Object?, Object?> rawData = snapshot.value as Map<Object?, Object?>;

      List<Map<String, dynamic>> allRecords = [];

      rawData.forEach((subjectKey, subjectValue) {
        if (subjectValue is Map) {
          subjectValue.forEach((codeKey, codeValue) {
            if (codeValue is Map) {
              codeValue.forEach((recordKey, recordValue) {
                if (recordValue is Map) {
                  var record = {
                    'subject': subjectKey.toString(),
                    'subject_code': codeKey.toString(),
                    'lecture_no': recordKey.toString(),
                    'details': Map<String, dynamic>.from(recordValue),
                  };
                  allRecords.add(record);
                }
              });
            }
          });
        }
      });
      return {'allRecords': allRecords};
    } catch (e) {
      throw Exception('Failed to fetch records');
    }
  }
}