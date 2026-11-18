import 'package:cloud_firestore/cloud_firestore.dart';

import 'company_role.dart';
import 'firestore_connectivity.dart';

/// Decides whether the post-sign-in account profile onboarding can be skipped.
class AccountProfileCompletion {
  AccountProfileCompletion._();

  static bool _nonEmpty(dynamic value) =>
      value != null && value.toString().trim().isNotEmpty;

  static bool _hasExplicitCompletion(Map<String, dynamic> userData) {
    if (userData['accountProfileCompleted'] == true) return true;

    final profile = userData['accountProfile'];
    if (profile is Map && profile['savedAt'] != null) return true;

    return _nonEmpty(userData['jobTitle']) || _nonEmpty(userData['phone']);
  }

  /// Signup only writes `companyName`, `ownerId`, and `createdAt` on the company.
  static bool _isSignupOnlyCompany(Map<String, dynamic> company) {
    const signupKeys = {'companyName', 'ownerId', 'createdAt', 'isGuest'};
    for (final entry in company.entries) {
      if (signupKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return false;
    }
    return true;
  }

  static Future<void> _backfillCompleted(
    DocumentReference<Map<String, dynamic>> userRef,
  ) async {
    await userRef.set(
      {
        'accountProfileCompleted': true,
        'accountProfileCompletedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  static Future<bool> isComplete(String uid) async {
    await ensureFirestoreAuthReady();

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(uid);
    final userSnap = await getDocumentServer(userRef);
    final userData = userSnap.data();
    if (userData == null) return false;

    if (_hasExplicitCompletion(userData)) return true;

    final companyId = userData['companyId']?.toString().trim();
    if (companyId == null || companyId.isEmpty) return false;

    // Owners who used Catalyst before account-profile onboarding existed.
    if (CompanyRole.isOwner(userData['companyRole']?.toString())) {
      final companySnap =
          await getDocumentServer(firestore.collection('companies').doc(companyId));
      final company = companySnap.data();
      if (company != null && !_isSignupOnlyCompany(company)) {
        await _backfillCompleted(userRef);
        return true;
      }

      final progressSnap = await runQueryServer(
        firestore
            .collection('companies')
            .doc(companyId)
            .collection('planProgress')
            .limit(1),
      );
      if (progressSnap.docs.isNotEmpty) {
        await _backfillCompleted(userRef);
        return true;
      }
    }

    return false;
  }
}
