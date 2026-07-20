import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final TextEditingController _nameController =
      TextEditingController();

  bool _loading = true;
  bool _savingName = false;
  bool _sendingPasswordReset = false;
  bool _loggingOut = false;

  String _savedName = '';
  String _email = '';
  DateTime? _lastLogin;

  User? get _user => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final User? user = _user;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      final String firestoreName =
          (data['name'] ?? '').toString().trim();
      final String authName =
          user.displayName?.trim() ?? '';

      final String resolvedName =
          firestoreName.isNotEmpty
              ? firestoreName
              : authName;

      final Object? lastLoginValue =
          data['lastLoginAt'];

      DateTime? lastLogin;

      if (lastLoginValue is Timestamp) {
        lastLogin = lastLoginValue.toDate();
      } else if (lastLoginValue is DateTime) {
        lastLogin = lastLoginValue;
      } else if (lastLoginValue is String) {
        lastLogin =
            DateTime.tryParse(lastLoginValue);
      }

      if (!mounted) return;

      _nameController.text = resolvedName;

      setState(() {
        _savedName = resolvedName;
        _email = user.email ?? '';
        _lastLogin = lastLogin;
        _loading = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _email = user.email ?? '';
        _loading = false;
      });

      _showMessage(
        'Account loading failed: '
        '${error.message ?? error.code}',
        error: true,
      );
    }
  }

  Future<void> _saveName() async {
    if (_savingName) return;

    final User? user = _user;
    final String name =
        _nameController.text.trim();

    if (user == null) {
      _showMessage(
        'No signed-in account found.',
        error: true,
      );
      return;
    }

    if (name.length < 2) {
      _showMessage(
        'Enter at least 2 characters.',
        error: true,
      );
      return;
    }

    setState(() {
      _savingName = true;
    });

    try {
      await Future.wait([
        _firestore
            .collection('users')
            .doc(user.uid)
            .update({
          'name': name,
        }),
        user.updateDisplayName(name),
      ]);

      await user.reload();

      if (!mounted) return;

      setState(() {
        _savedName = name;
        _savingName = false;
      });

      FocusScope.of(context).unfocus();

      _showMessage(
        'Name updated successfully.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _savingName = false;
      });

      _showMessage(
        'Name update failed: '
        '${error.message ?? error.code}',
        error: true,
      );
    }
  }

  Future<void> _sendPasswordReset() async {
    if (_sendingPasswordReset) return;

    final String email =
        (_user?.email ?? '').trim();

    if (email.isEmpty) {
      _showMessage(
        'Account has no email address.',
        error: true,
      );
      return;
    }

    final bool confirmed =
        await _confirmPasswordReset(email);

    if (!confirmed || !mounted) return;

    setState(() {
      _sendingPasswordReset = true;
    });

    try {
      await _auth.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        _sendingPasswordReset = false;
      });

      _showMessage(
        'Password reset email sent to $email.',
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _sendingPasswordReset = false;
      });

      _showMessage(
        'Password reset failed: '
        '${error.message ?? error.code}',
        error: true,
      );
    }
  }

  Future<bool> _confirmPasswordReset(
    String email,
  ) async {
    final bool? result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AT.card,
          title: const Text(
            'Change password?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            'Password reset instructions '
            'will be sent to $email.',
            style: const TextStyle(
              color: AT.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text(
                'Send Email',
                style: TextStyle(
                  color: AT.gold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    final bool confirmed =
        await _confirmLogout();

    if (!confirmed || !mounted) return;

    setState(() {
      _loggingOut = true;
    });

    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _loggingOut = false;
      });

      _showMessage(
        'Logout failed: '
        '${error.message ?? error.code}',
        error: true,
      );
    }
  }

  Future<bool> _confirmLogout() async {
    final bool? result =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AT.card,
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: const Text(
            'Current admin session will end.',
            style: TextStyle(
              color: AT.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AT.err,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            error ? AT.err : AT.card2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AT.background,
      appBar: AppBar(
        backgroundColor: AT.background,
        elevation: 0,
        title: const AdminPageHeader(
          title: 'Settings',
          subtitle: 'Account information and security',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Settings',
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AT.gold,
                ),
              )
            : ListView(
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  28,
                ),
                children: [
                  _buildAccountHeader(),
                  const SizedBox(height: 12),
                  _buildNameSection(),
                  const SizedBox(height: 12),
                  _buildAccountDetails(),
                  const SizedBox(height: 12),
                  _buildPasswordSection(),
                  const SizedBox(height: 12),
                  _buildLogoutSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildAccountHeader() {
    final String displayName =
        _savedName.isEmpty
            ? 'Name not added'
            : _savedName;

    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AT.goldSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(displayName),
              style: AT.body(
                size: 15,
                color: AT.gold,
                w: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AT.title(
                    size: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email.isEmpty
                      ? 'No email available'
                      : _email,
                  style: AT.body(
                    size: 9.5,
                    color: AT.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    final bool addingName =
        _savedName.isEmpty;

    return SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            addingName
                ? 'ADD ACCOUNT NAME'
                : 'UPDATE ACCOUNT NAME',
            style: AT.body(
              size: 8,
              color: AT.gold,
              w: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization:
                TextCapitalization.words,
            textInputAction:
                TextInputAction.done,
            onSubmitted: (_) => _saveName(),
            style: AT.body(
              size: 11,
              color: Colors.white,
              w: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter account name',
              prefixIcon: const Icon(
                Icons.person_outline,
                color: AT.gold,
                size: 18,
              ),
              labelStyle: AT.body(
                size: 8.5,
                color: AT.gold,
                w: FontWeight.w700,
              ),
              hintStyle: AT.body(
                size: 9.5,
                color: AT.textFaint,
              ),
              filled: true,
              fillColor: AT.card2,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AT.border,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AT.gold,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed:
                  _savingName ? null : _saveName,
              icon: _savingName
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : Icon(
                      addingName
                          ? Icons.add_rounded
                          : Icons.save_outlined,
                      size: 18,
                    ),
              label: Text(
                _savingName
                    ? 'Saving...'
                    : addingName
                        ? 'Add Name'
                        : 'Update Name',
                style: AT.body(
                  size: 10,
                  color: Colors.black,
                  w: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AT.gold,
                disabledBackgroundColor:
                    AT.gold.withOpacity(0.55),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountDetails() {
    return SectionCard(
      child: Column(
        children: [
          _detailRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _email.isEmpty
                ? 'Not available'
                : _email,
          ),
          const Divider(
            color: AT.border,
            height: 22,
          ),
          _detailRow(
            icon: Icons.schedule_outlined,
            label: 'Last Login',
            value: _formatDateTime(
              _lastLogin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'SECURITY',
            style: AT.body(
              size: 8,
              color: AT.gold,
              w: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Change password using secure '
            'Firebase password reset email.',
            style: AT.body(
              size: 9.5,
              color: AT.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed:
                  _sendingPasswordReset
                      ? null
                      : _sendPasswordReset,
              icon: _sendingPasswordReset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AT.gold,
                      ),
                    )
                  : const Icon(
                      Icons.lock_reset_rounded,
                      size: 18,
                    ),
              label: Text(
                _sendingPasswordReset
                    ? 'Sending...'
                    : 'Change Password',
                style: AT.body(
                  size: 10,
                  color: AT.gold,
                  w: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AT.gold,
                side: const BorderSide(
                  color: AT.gold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return SectionCard(
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed:
              _loggingOut ? null : _logout,
          icon: _loggingOut
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AT.err,
                  ),
                )
              : const Icon(
                  Icons.logout_rounded,
                  size: 18,
                ),
          label: Text(
            _loggingOut
                ? 'Logging out...'
                : 'Logout',
            style: AT.body(
              size: 10,
              color: AT.err,
              w: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AT.err,
            side: const BorderSide(
              color: AT.err,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AT.goldSoft,
            borderRadius:
                BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: AT.gold,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AT.body(
                  size: 8,
                  color: AT.textMuted,
                  w: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: AT.body(
                  size: 10.5,
                  color: Colors.white,
                  w: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String value) {
    if (value == 'Name not added') {
      return '?';
    }

    final List<String> words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '?';

    if (words.length == 1) {
      return words.first[0].toUpperCase();
    }

    return '${words.first[0]}'
        '${words.last[0]}'
        .toUpperCase();
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return 'No login record';
    }

    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final int twelveHour =
        date.hour % 12 == 0
            ? 12
            : date.hour % 12;

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year} · '
        '$twelveHour:$minute $period';
  }
}
