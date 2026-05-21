import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTimestampHelper {
  const FirestoreTimestampHelper._();

  static DateTime? tryRead(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
  }

  static Timestamp serverNow() => Timestamp.now();
}
