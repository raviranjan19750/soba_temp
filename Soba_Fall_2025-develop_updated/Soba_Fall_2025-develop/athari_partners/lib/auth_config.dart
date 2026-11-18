import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Set `BYPASS_AUTH=true` in `.env` for local UI testing without Firebase Auth.
/// Production default: real sign-in and Firestore persistence.
bool get authBypassEnabled =>
    dotenv.env['BYPASS_AUTH']?.trim().toLowerCase() == 'true';

/// Master switch for OpenAI-powered suggestion UI (identity, external assessment, etc.).
/// Set `ENABLE_AI_SUGGESTIONS=false` for closed beta to avoid shipping a client API key.
/// Defaults to enabled when the flag is omitted, as long as a valid OpenAI key exists.
bool get aiSuggestionsEnabled {
  final flag = dotenv.env['ENABLE_AI_SUGGESTIONS']?.trim().toLowerCase();
  if (flag == 'false' || flag == '0' || flag == 'off' || flag == 'no') {
    return false;
  }
  final key = dotenv.env['OPENAI_API_KEY']?.trim();
  return key != null && key.isNotEmpty && key != 'your_openai_api_key_here';
}

/// Placeholder company id when auth is bypassed (Firestore still skipped).
const String kLocalDemoCompanyId = 'local-demo';

bool get skipFirebasePersistence => authBypassEnabled;

/// Resolves the active company id, or a local demo id when auth is bypassed.
Future<String?> loadCompanyIdForCurrentUser() async {
  if (authBypassEnabled) return kLocalDemoCompanyId;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!userDoc.exists || userDoc.data() == null) return null;

  final companyId = userDoc.data()!['companyId'];
  if (companyId == null) return null;
  return companyId.toString();
}
