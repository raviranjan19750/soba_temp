import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'services/company_membership_service.dart';
import 'services/company_role.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({
    super.key,
    this.joinExistingCompany = false,
  });

  /// When true, opens signup focused on joining via invite code.
  final bool joinExistingCompany;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _inviteCode = TextEditingController();

  bool _submitting = false;
  late bool _joinExistingCompany;

  @override
  void initState() {
    super.initState();
    _joinExistingCompany = widget.joinExistingCompany;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _company.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  /// Replaces legacy Athari Partners logo with MyCatalystPlan wordmark.
  Widget _signupBrandHeader() {
    const accent = Color(0xFF2E7D32);
    const accentDeep = Color(0xFF1B5E20);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accentDeep],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accentDeep],
              ).createShader(bounds),
              child: const Text(
                'MyCatalystPlan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'A product of GROWTH Catalyst HQ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _labeled(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      const SizedBox(height: 6),
      field,
    ],
  );

  /// If signup fails after Auth account creation, remove that account so the user
  /// can retry with the same email (otherwise Firebase returns email-already-in-use).
  Future<void> _rollbackAuthUser(User user) async {
    try {
      await user.delete();
    } catch (_) {
      await FirebaseAuth.instance.signOut();
    }
  }

  String _signupAuthErrorMessage(FirebaseAuthException e) {
    final detail = (e.message ?? '').toLowerCase();
    if (detail.contains('configuration_not_found')) {
      return 'Firebase Authentication is not set up yet. In Firebase Console '
          '→ Authentication → Get started → enable Email/Password, then try again.';
    }
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in, or use '
            'Forgot password on the sign-in page.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled. In Firebase Console go to '
            'Authentication → Sign-in method → Email/Password → Enable.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      default:
        return 'Failed to create account (${e.code}). '
            'If this persists, enable Email/Password in Firebase Authentication.';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    User? newUser;

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      newUser = userCredential.user;
      if (newUser == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Account creation failed',
        );
      }

      final uid = newUser.uid;
      final displayName = '${_firstName.text.trim()} ${_lastName.text.trim()}';

      if (_joinExistingCompany) {
        final batch = firestore.batch();
        batch.set(firestore.collection('users').doc(uid), {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'displayName': displayName,
          'email': _email.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        await CompanyMembershipService.joinCompanyWithInviteCode(
          _inviteCode.text.trim(),
        );
      } else {
        final companyRef = firestore.collection('companies').doc();
        final batch = firestore.batch();
        batch.set(companyRef, {
          'companyName': _company.text.trim(),
          'ownerId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.set(firestore.collection('users').doc(uid), {
          'firstName': _firstName.text.trim(),
          'lastName': _lastName.text.trim(),
          'displayName': displayName,
          'email': _email.text.trim(),
          'companyId': companyRef.id,
          'companyRole': CompanyRole.owner,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        await CompanyMembershipService.ensureOwnerMembership(
          companyId: companyRef.id,
          uid: uid,
          email: _email.text.trim(),
          displayName: displayName,
        );
      }

      await newUser.updateDisplayName(displayName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _joinExistingCompany
                ? 'Welcome! You are connected to your team — complete your account profile next.'
                : 'Welcome! Complete your account profile to continue.',
          ),
        ),
      );
      // Root MaterialApp rebuilds on auth change and shows AccountProfilePage.
    } on FirebaseAuthException catch (e) {
      if (newUser != null) await _rollbackAuthUser(newUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_signupAuthErrorMessage(e)),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (newUser != null) await _rollbackAuthUser(newUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not finish registration. Check your connection and try again.\n'
            '${e is FirebaseException ? e.message ?? e.toString() : e}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _signupBrandHeader(),
                  const SizedBox(height: 20),
                  Text(
                    _joinExistingCompany
                        ? 'Join your team\'s company'
                        : 'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _joinExistingCompany
                        ? 'Enter the invite code from your company owner to collaborate '
                            'on the strategic plan.'
                        : 'Set up a new company or join an existing team with an invite code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text('Or '),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'sign in to your existing account',
                          style: TextStyle(
                            color: blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, c) {
                              final wide = c.maxWidth >= 560;

                              final first = _labeled(
                                'First name',
                                TextFormField(
                                  controller: _firstName,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              );
                              final last = _labeled(
                                'Last name',
                                TextFormField(
                                  controller: _lastName,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              );

                              if (wide) {
                                return Row(
                                  children: [
                                    Expanded(child: first),
                                    const SizedBox(width: 16),
                                    Expanded(child: last),
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  first,
                                  const SizedBox(height: 12),
                                  last,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                label: Text('Create company'),
                                icon: Icon(Icons.business_outlined, size: 18),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text('Join with code'),
                                icon: Icon(Icons.group_add_outlined, size: 18),
                              ),
                            ],
                            selected: {_joinExistingCompany},
                            onSelectionChanged: (value) {
                              setState(() {
                                _joinExistingCompany = value.first;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_joinExistingCompany)
                            _labeled(
                              'Invite code',
                              TextFormField(
                                controller: _inviteCode,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'Enter code from your company owner',
                                ),
                                validator: (v) {
                                  if (!_joinExistingCompany) return null;
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Invite code is required';
                                  }
                                  return null;
                                },
                              ),
                            )
                          else
                            _labeled(
                              'Company name',
                              TextFormField(
                                controller: _company,
                                textInputAction: TextInputAction.next,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                            ),
                          const SizedBox(height: 12),
                          _labeled(
                            'Email address',
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final ok = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                ).hasMatch(v.trim());
                                return ok ? null : 'Enter a valid email';
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _labeled(
                            'Password',
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 6) return 'Min 6 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _labeled(
                            'Confirm password',
                            TextFormField(
                              controller: _confirm,
                              obscureText: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v != _password.text)
                                  return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            // onPressed: _submitting ? null : _submit,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B7BEC),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _joinExistingCompany
                                    ? 'Join company'
                                    : 'Save & Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
