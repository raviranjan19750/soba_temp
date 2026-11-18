import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _shouldRemember = false;
  bool _isObscured = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _accent = Color(0xFF2E7D32);
  static const _accentDeep = Color(0xFF1B5E20);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _brandHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accent, _accentDeep],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_accent, _accentDeep],
              ).createShader(bounds),
              child: const Text(
                'MyCatalystPlan',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.45,
                  color: Colors.white,
                  height: 1.05,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
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

  Future<void> _onSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      // Root `home` switches to the signed-in shell; remove this route so it is not
      // left covering the app (otherwise sign-in looks like it failed).
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage = 'An error occurred. Please try again.';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage =
              'Incorrect email or password. If you are new here, create an account first.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Email/password sign-in is not enabled. In Firebase Console go to '
              'Authentication → Sign-in method → Email/Password → Enable.';
          break;
        case 'internal-error':
          if ((e.message ?? '').toLowerCase().contains('configuration_not_found')) {
            errorMessage =
                'Firebase Authentication is not set up yet. In Firebase Console '
                '→ Authentication → Get started → enable Email/Password.';
          }
          break;
      }

      _showMessageDialog('Sign In Failed', errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(
        'Sign In Failed',
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onForgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the email address you used to register, then try again.'),
        ),
      );
      return;
    }

    final rx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!rx.hasMatch(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email address first.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      _showMessageDialog(
        'Check your email',
        'If an account exists for $email, we sent a link to reset your password.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = 'Could not send reset email. Please try again.';
      switch (e.code) {
        case 'invalid-email':
          msg = 'That email address is not valid.';
          break;
        case 'user-not-found':
          msg =
              'No account found for that email. Try creating an account or use a different address.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          msg = 'Network error. Please check your connection.';
          break;
      }
      _showMessageDialog('Reset link not sent', msg);
    } catch (e) {
      if (!mounted) return;
      _showMessageDialog(
        'Reset link not sent',
        'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessageDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final cardMax = width < 560 ? 420.0 : 520.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const BackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardMax),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _brandHeader(),
                const SizedBox(height: 20),
                Text(
                  'Sign in to your account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupPage()),
                    );
                  },
                  child: const Text(
                    'Or create a new account',
                    style: TextStyle(color: Color(0xFF2563EB)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignupPage(joinExistingCompany: true),
                      ),
                    );
                  },
                  child: const Text(
                    'New here? Join your team with an invite code',
                    style: TextStyle(
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email address',
                                  hintText: 'you@company.com',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Email is required';
                                  final rx = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!rx.hasMatch(value)) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _password,
                                obscureText: _isObscured,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    tooltip: _isObscured
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () => setState(
                                      () => _isObscured = !_isObscured,
                                    ),
                                    icon: Icon(
                                      _isObscured
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? '').isEmpty) {
                                    return 'Password is required';
                                  }
                                  if ((v ?? '').length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _shouldRemember,
                                    onChanged: (v) => setState(
                                      () => _shouldRemember = v ?? false,
                                    ),
                                  ),
                                  const Text('Remember me'),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _onForgotPassword,
                                    child: const Text(
                                      'Forgot your password?',
                                      style: TextStyle(color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _onSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accent,
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
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ],
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
    );
  }
}
