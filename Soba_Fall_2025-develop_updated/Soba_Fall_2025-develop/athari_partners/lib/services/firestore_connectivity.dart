import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

bool isTransientFirestoreError(FirebaseException error) {
  return error.code == 'unavailable' ||
      error.code == 'deadline-exceeded' ||
      error.code == 'aborted' ||
      error.code == 'resource-exhausted';
}

String formatFirestoreSetupError(Object error) {
  if (error is FirebaseException) {
    if (error.code == 'unavailable') {
      return 'Could not reach Cloud Firestore. Check your internet connection, '
          'try disabling ad blockers for localhost, and confirm Firestore is '
          'enabled in Firebase Console (Build → Firestore Database → Create '
          'database).\n\n${error.message ?? error.code}';
    }
    if (error.code == 'permission-denied') {
      return 'Firestore denied access. Publish the rules from firestore.rules '
          'in Firebase Console.\n\n${error.message ?? error.code}';
    }
    return '${error.code}: ${error.message ?? 'Firestore request failed.'}';
  }
  return error.toString();
}

Future<void> configureFirestoreForPlatform() async {
  final firestore = FirebaseFirestore.instance;
  if (kIsWeb) {
    firestore.settings = const Settings(
      persistenceEnabled: false,
    );
  }
  try {
    await firestore.enableNetwork();
  } catch (_) {
    // Network may already be enabled.
  }
}

/// Ensures the signed-in user token is ready before security-rule reads.
Future<void> ensureFirestoreAuthReady([User? user]) async {
  final signedInUser = user ?? FirebaseAuth.instance.currentUser;
  if (signedInUser == null) return;
  await signedInUser.getIdToken();
}

Future<T> withFirestoreRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = 6,
}) async {
  Object? lastError;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await operation();
    } on FirebaseException catch (error) {
      lastError = error;
      if (isTransientFirestoreError(error) && attempt < maxAttempts - 1) {
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
        continue;
      }
      rethrow;
    }
  }
  throw lastError ?? StateError('Firestore operation failed');
}

Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentServer(
  DocumentReference<Map<String, dynamic>> ref,
) {
  return withFirestoreRetry(
    () => ref.get(const GetOptions(source: Source.server)),
  );
}

Future<QuerySnapshot<Map<String, dynamic>>> runQueryServer(
  Query<Map<String, dynamic>> query,
) {
  return withFirestoreRetry(
    () => query.get(const GetOptions(source: Source.server)),
  );
}
