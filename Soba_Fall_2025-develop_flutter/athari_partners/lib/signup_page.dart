import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // Import your login page
import 'index_screen.dart'; // Import your index screen

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

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

  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _company.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // 1. Create user in Firebase Auth
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );

      final uid = userCredential.user!.uid;
      final displayName = '${_firstName.text.trim()} ${_lastName.text.trim()}';

      // Update displayName in Auth
      await userCredential.user!.updateDisplayName(displayName);

      // 2. Create company document with auto-generated ID
      final companyRef = await firestore.collection('companies').add({
        'companyName': _company.text.trim(),
        'ownerId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final companyId = companyRef.id;

      // 3. Create user document
      await firestore.collection('users').doc(uid).set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'displayName': displayName,
        'email': _email.text.trim(),
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      // 4. Redirect to IndexScreen
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const IndexScreen()));
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to create account';
      if (e.code == 'email-already-in-use') {
        message = 'Email already in use';
      } else if (e.code == 'weak-password') {
        message = 'Password too weak';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/logos/athari_logo.png', height: 80),
                  const SizedBox(height: 16),
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
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
                          const SizedBox(height: 12),
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
                              child: const Text(
                                'Save & Continue',
                                style: TextStyle(
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
