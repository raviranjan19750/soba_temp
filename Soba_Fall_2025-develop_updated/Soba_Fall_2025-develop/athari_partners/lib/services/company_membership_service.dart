import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth_config.dart';
import 'company_collaboration_session_cache.dart';
import 'company_role.dart';
import 'firestore_connectivity.dart';

class CompanyMember {
  const CompanyMember({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.email,
  });

  final String uid;
  final String role;
  final String displayName;
  final String email;
}

class CompanyMembershipService {
  static Future<String?> loadCompanyRoleForCurrentUser() async {
    if (authBypassEnabled) {
      return CompanyCollaborationSessionCache.companyRole;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = (userSnap.data()?['companyRole'] ?? '').toString().trim();
    if (role.isNotEmpty) return role;

    final companyId = userSnap.data()?['companyId']?.toString();
    if (companyId == null || companyId.isEmpty) return null;

    final companySnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();
    if (companySnap.data()?['ownerId'] == uid) return CompanyRole.owner;

    final memberSnap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .doc(uid)
        .get();
    if (memberSnap.exists) {
      return (memberSnap.data()?['role'] ?? CompanyRole.collaborator)
          .toString();
    }

    return CompanyRole.collaborator;
  }

  static Future<bool> isCurrentUserOwner(String? companyId) async {
    final role = await loadCompanyRoleForCurrentUser();
    return CompanyRole.isOwner(role);
  }

  static Future<void> ensureOwnerMembership({
    required String companyId,
    required String uid,
    required String email,
    required String displayName,
  }) async {
    if (skipFirebasePersistence) return;

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final memberRef = firestore
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .doc(uid);

    batch.set(
      memberRef,
      {
        'role': CompanyRole.owner,
        'email': email,
        'displayName': displayName,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    batch.set(
      firestore.collection('users').doc(uid),
      {
        'companyRole': CompanyRole.owner,
      },
      SetOptions(merge: true),
    );

    await withFirestoreRetry(() => batch.commit());
  }

  static Future<String> getOrCreateInviteCode(String companyId) async {
    if (skipFirebasePersistence) {
      return CompanyCollaborationSessionCache.inviteCode;
    }

    final companyRef =
        FirebaseFirestore.instance.collection('companies').doc(companyId);
    final snap = await companyRef.get();
    final existing = (snap.data()?['collaboratorInviteCode'] ?? '')
        .toString()
        .trim();
    if (existing.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('inviteCodes')
          .doc(existing)
          .set({'companyId': companyId}, SetOptions(merge: true));
      return existing;
    }

    final code = _generateInviteCode();
    await companyRef.set(
      {'collaboratorInviteCode': code},
      SetOptions(merge: true),
    );
    await FirebaseFirestore.instance.collection('inviteCodes').doc(code).set(
      {'companyId': companyId},
      SetOptions(merge: true),
    );
    return code;
  }

  static Future<void> joinCompanyWithInviteCode(String inviteCode) async {
    if (skipFirebasePersistence) {
      CompanyCollaborationSessionCache.setRole(CompanyRole.collaborator);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to join a company.');
    }

    final normalized = inviteCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw StateError('Enter a valid invite code.');
    }

    final inviteSnap = await FirebaseFirestore.instance
        .collection('inviteCodes')
        .doc(normalized)
        .get();

    String companyId;
    String companyName;

    if (inviteSnap.exists) {
      companyId = (inviteSnap.data()?['companyId'] ?? '').toString();
      if (companyId.isEmpty) {
        throw StateError('Invite code not found. Check with your company owner.');
      }
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .get();
      if (!companyDoc.exists) {
        throw StateError('Invite code not found. Check with your company owner.');
      }
      companyName = (companyDoc.data()?['companyName'] ?? '').toString().trim();
    } else {
      final query = await FirebaseFirestore.instance
          .collection('companies')
          .where('collaboratorInviteCode', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw StateError('Invite code not found. Check with your company owner.');
      }

      final companyDoc = query.docs.first;
      companyId = companyDoc.id;
      companyName =
          (companyDoc.data()['companyName'] ?? '').toString().trim();
    }

    final user = FirebaseAuth.instance.currentUser!;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final email = (user.email ?? userSnap.data()?['email'] ?? '').toString();
    final displayName = (user.displayName ??
            userSnap.data()?['displayName'] ??
            '')
        .toString()
        .trim();

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      userRef,
      {
        'companyId': companyId,
        'companyRole': CompanyRole.collaborator,
        if (email.isNotEmpty) 'email': email,
      },
      SetOptions(merge: true),
    );

    batch.set(
      FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('members')
          .doc(uid),
      {
        'role': CompanyRole.collaborator,
        'email': email,
        'displayName': displayName,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'companyName': companyName,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  static Future<List<CompanyMember>> listMembers(String? companyId) async {
    if (companyId == null || companyId.isEmpty) return const [];
    if (skipFirebasePersistence) {
      return [
        CompanyMember(
          uid: 'local-owner',
          role: CompanyRole.owner,
          displayName: 'Primary owner',
          email: 'owner@demo.local',
        ),
      ];
    }

    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('members')
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return CompanyMember(
        uid: doc.id,
        role: (data['role'] ?? CompanyRole.collaborator).toString(),
        displayName: (data['displayName'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
      );
    }).toList()
      ..sort((a, b) {
        if (a.role == CompanyRole.owner) return -1;
        if (b.role == CompanyRole.owner) return 1;
        return a.displayName.compareTo(b.displayName);
      });
  }

  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
