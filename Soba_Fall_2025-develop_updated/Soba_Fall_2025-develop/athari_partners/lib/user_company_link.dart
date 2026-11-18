import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/company_membership_service.dart';
import 'services/company_role.dart';
import 'services/firestore_connectivity.dart';

/// Ensures `users/{uid}` has a non-empty [companyId].
///
/// Used after any sign-in so email/password users (and restored sessions) match
/// the signup + guest flows. If the user doc is missing [companyId], links to an
/// existing company they own (`ownerId`) or creates one.
Future<void> ensureUserLinkedToCompany(User user) async {
  await ensureFirestoreAuthReady(user);

  final firestore = FirebaseFirestore.instance;
  final uid = user.uid;
  final userRef = firestore.collection('users').doc(uid);

  // Signup writes users/{uid} shortly after Auth account creation — wait briefly.
  Map<String, dynamic>? data;
  for (var attempt = 0; attempt < 8; attempt++) {
    final snap = await getDocumentServer(userRef);
    data = snap.data();
    final existing = data?['companyId'];
    if (existing != null && existing.toString().trim().isNotEmpty) {
      return;
    }
    await Future.delayed(Duration(milliseconds: 250 * (attempt + 1)));
  }

  final existing = data?['companyId'];
  if (existing != null && existing.toString().trim().isNotEmpty) {
    return;
  }

  final isGuest = user.isAnonymous;
  final email = (user.email ?? data?['email'] ?? '').toString();
  final displayName = isGuest
      ? 'Guest'
      : (user.displayName ?? (data?['displayName'] as String?) ?? '').toString();

  final ownedQuery = await runQueryServer(
    firestore
        .collection('companies')
        .where('ownerId', isEqualTo: uid)
        .limit(1),
  );

  if (ownedQuery.docs.isNotEmpty) {
    final companyId = ownedQuery.docs.first.id;
    await withFirestoreRetry(
      () => userRef.set(
        {
          'email': email,
          'displayName': displayName,
          'companyId': companyId,
          'companyRole': CompanyRole.owner,
          if (isGuest) 'isGuest': true,
          'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      ),
    );
    await CompanyMembershipService.ensureOwnerMembership(
      companyId: companyId,
      uid: uid,
      email: email,
      displayName: displayName,
    );
    return;
  }

  final companyData = <String, dynamic>{
    'ownerId': uid,
    'createdAt': FieldValue.serverTimestamp(),
  };
  if (isGuest) {
    companyData['companyName'] = 'Guest workspace';
    companyData['isGuest'] = true;
  } else {
    final dn = user.displayName?.trim();
    companyData['companyName'] =
        (dn != null && dn.isNotEmpty) ? "$dn's workspace" : 'My workspace';
  }

  final companyRef = await withFirestoreRetry(
    () => firestore.collection('companies').add(companyData),
  );

  await withFirestoreRetry(
    () => userRef.set(
      {
        'email': email,
        'displayName': displayName,
        'companyId': companyRef.id,
        'companyRole': CompanyRole.owner,
        if (isGuest) 'isGuest': true,
        'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ),
  );

  await CompanyMembershipService.ensureOwnerMembership(
    companyId: companyRef.id,
    uid: uid,
    email: email,
    displayName: displayName,
  );
}
