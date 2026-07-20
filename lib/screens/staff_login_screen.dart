import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_screen.dart';

enum TeamRole {
  staff,
  manager,
  owner,
}

extension TeamRoleLabel on TeamRole {
  String get label {
    switch (this) {
      case TeamRole.staff:
        return 'Staff';
      case TeamRole.manager:
        return 'Manager';
      case TeamRole.owner:
        return 'Owner';
    }
  }
}

class FirebaseTeamAccount {
  const FirebaseTeamAccount({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
  });

  final String uid;
  final String email;
  final TeamRole role;
  final String name;
}

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() =>
      _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  static const Color gold = Color(0xFFE8B923);
  static const Color background = Color(0xFF0B0C10);
  static const Color fieldColor = Color(0xFF16171D);
  static const Color border = Color(0xFF2A2B33);

  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  TeamRole? _parseRole(String value) {
    switch (value.trim().toLowerCase()) {
      case 'staff':
        return TeamRole.staff;
      case 'manager':
        return TeamRole.manager;
      case 'owner':
        return TeamRole.owner;
      default:
        return null;
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final User? user = credential.user;

      if (user == null) {
        throw StateError('Firebase returned no authenticated user.');
      }

      final DocumentReference<Map<String, dynamic>> userReference =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final DocumentSnapshot<Map<String, dynamic>> profileSnapshot =
          await userReference.get();

      if (!profileSnapshot.exists) {
        await FirebaseAuth.instance.signOut();
        _showMessage(
          'Account profile missing. Add users/${user.uid} in Firestore.',
        );
        return;
      }

      final Map<String, dynamic> profile =
          profileSnapshot.data() ?? <String, dynamic>{};

      final bool active = profile['active'] == true;
      final TeamRole? role =
          _parseRole((profile['role'] ?? '').toString());

      if (!active) {
        await FirebaseAuth.instance.signOut();
        _showMessage('Account disabled. Contact owner.');
        return;
      }

      if (role == null) {
        await FirebaseAuth.instance.signOut();
        _showMessage(
          'Invalid account role. Use owner, manager, or staff.',
        );
        return;
      }

      final String name =
          (profile['name'] ?? 'Team Member').toString().trim();

      final FirebaseTeamAccount account = FirebaseTeamAccount(
        uid: user.uid,
        email: user.email ?? emailController.text.trim(),
        role: role,
        name: name.isEmpty ? 'Team Member' : name,
      );

      await userReference.set(
        <String, dynamic>{
          'lastLoginAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      await _showLoginSuccess(account);
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error.code));
    } on FirebaseException catch (error) {
      _showMessage(
        error.code == 'permission-denied'
            ? 'Firestore blocked account profile access. Check rules.'
            : 'Firebase error: ${error.message ?? error.code}',
      );
    } catch (error) {
      _showMessage('Login failed: $error');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'Account disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      default:
        return 'Authentication failed: $code';
    }
  }

  Future<void> _showLoginSuccess(
    FirebaseTeamAccount account,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16171D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          icon: const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0x3322C55E),
            child: Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF22C55E),
              size: 28,
            ),
          ),
          title: Text(
            'Login Successful',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Welcome, ${account.name}.\n'
            'Account role: ${account.role.label}',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            SizedBox(
              width: 150,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DashboardScreen(
                        initialName: account.name,
                        initialRole: account.role.name,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _backToHome() {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: _backToHome,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          tooltip: 'Back to Home',
        ),
        title: Text(
          'Team Access',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 30,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 64,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: gold,
                          size: 58,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Staff, manager, and owner access',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Account role is detected automatically.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _fieldLabel('Email'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: emailController,
                    hint: 'Enter work email',
                    icon: Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (String? value) {
                      final String email =
                          value?.trim() ?? '';

                      if (email.isEmpty) {
                        return 'Enter email.';
                      }

                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Enter valid email.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _fieldLabel('Password'),
                  const SizedBox(height: 6),
                  _buildField(
                    controller: passwordController,
                    hint: 'Enter password',
                    icon: Icons.lock_outline,
                    obscure: obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    suffix: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter password.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showMessage(
                          'Contact owner to reset password.',
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.montserrat(
                          color: gold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          isSubmitting ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor:
                            const Color(0xFF75621E),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'LOGIN',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Accounts are created and assigned by owner.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white38,
                      fontSize: 10.5,
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

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: Colors.white70,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputAction textInputAction,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white30),
        prefixIcon: Icon(
          icon,
          color: Colors.white38,
          size: 20,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: gold,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
