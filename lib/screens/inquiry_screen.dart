import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  static const Color gold = Color(0xFFD4A91F);
  static const Color dark = Color(0xFF080A0B);
  static const Color cream = Color(0xFFF6E9CC);
  static const Color fieldBorder = Color(0xFFE2CDA3);
  static const Color muted = Color(0xFFA98769);
  static const Color green = Color(0xFF0DA65A);

  final GlobalKey<FormState> inquiryFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> contactFormKey = GlobalKey<FormState>();

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  int currentStep = 0;
  String? selectedInquiryType;
  bool isSubmitting = false;

  static const List<String> inquiryTypes = [
    'General Question',
    'Catering Services',
    'Event Hall',
    'Packages and Pricing',
    'Availability',
    'Other',
  ];

  @override
  void dispose() {
    subjectController.dispose();
    messageController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    facebookController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();

    setState(() => currentStep = step);

    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextFromInquiry() {
    FocusScope.of(context).unfocus();

    final bool valid =
        inquiryFormKey.currentState?.validate() ?? false;

    if (!valid) {
      _showMessage('Complete all inquiry details.');
      return;
    }

    _goToStep(1);
  }

  void _nextFromContact() {
    FocusScope.of(context).unfocus();

    final bool valid =
        contactFormKey.currentState?.validate() ?? false;

    if (!valid) {
      _showMessage('Complete all required contact details.');
      return;
    }

    _goToStep(2);
  }

  Future<void> _submitInquiry() async {
    if (isSubmitting) return;

    final String email = emailController.text.trim();
    final String phone = phoneController.text.trim();
    final String phoneDigits =
        phone.replaceAll(RegExp(r'\D'), '');

    final bool inquiryValid =
        selectedInquiryType != null &&
        selectedInquiryType!.trim().isNotEmpty &&
        subjectController.text.trim().isNotEmpty &&
        messageController.text.trim().isNotEmpty;

    final bool contactValid =
        nameController.text.trim().isNotEmpty &&
        phoneDigits.length >= 10 &&
        phoneDigits.length <= 13 &&
        RegExp(
          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
        ).hasMatch(email);

    if (!inquiryValid || !contactValid) {
      _showMessage('Some required fields are incomplete.');
      _goToStep(inquiryValid ? 1 : 0);
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final DocumentReference<Map<String, dynamic>> inquiryReference =
          FirebaseFirestore.instance.collection('inquiries').doc();

      await inquiryReference.set({
        'inquiryId': inquiryReference.id,
        'inquiryType': selectedInquiryType,
        'subject': subjectController.text.trim(),
        'message': messageController.text.trim(),
        'fullName': nameController.text.trim(),
        'phoneNumber': phone,
        'emailAddress': email,
        'emailLower': email.toLowerCase(),
        'facebookProfile': facebookController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() => isSubmitting = false);

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            icon: const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFDDF5E8),
              child: Icon(
                Icons.check,
                color: green,
                size: 30,
              ),
            ),
            title: Text(
              'Inquiry Sent',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Your inquiry was submitted. Shepherd\'s team will contact you using the details provided.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: 130,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => isSubmitting = false);

      _showMessage('Inquiry submission failed: $error');
    }
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF252525),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBackBar(
              onBack: () {
                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              },
            ),
            _buildProgressHeader(),
            const Divider(
              height: 1,
              thickness: 1,
              color: fieldBorder,
            ),
            _buildTitleHeader(),
            const Divider(
              height: 1,
              thickness: 1,
              color: fieldBorder,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: switch (currentStep) {
                    0 => _buildInquiryStep(),
                    1 => _buildContactStep(),
                    _ => _buildReviewStep(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      color: cream,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _ProgressStep(
              number: 1,
              label: 'Inquiry Details',
              state: currentStep == 0
                  ? _StepState.active
                  : _StepState.completed,
            ),
          ),
          _ProgressLine(completed: currentStep >= 1),
          Expanded(
            child: _ProgressStep(
              number: 2,
              label: 'Contact Info',
              state: currentStep == 1
                  ? _StepState.active
                  : currentStep > 1
                      ? _StepState.completed
                      : _StepState.inactive,
            ),
          ),
          _ProgressLine(completed: currentStep >= 2),
          Expanded(
            child: _ProgressStep(
              number: 3,
              label: 'Review',
              state: currentStep == 2
                  ? _StepState.active
                  : _StepState.inactive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleHeader() {
    const List<String> subtitles = [
      'Step 1 of 3 — Inquiry details',
      'Step 2 of 3 — Contact information',
      'Step 3 of 3 — Review inquiry',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              color: gold,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send an Inquiry',
                  style: GoogleFonts.playfairDisplay(
                    color: dark,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitles[currentStep],
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isSubmitting
                ? null
                : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              foregroundColor: dark,
              side: const BorderSide(color: fieldBorder),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryStep() {
    return Form(
      key: inquiryFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey<int>(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('WHAT WOULD YOU LIKE TO ASK?'),
          const SizedBox(height: 22),
          DropdownButtonFormField<String>(
            value: selectedInquiryType,
            isExpanded: true,
            dropdownColor: Colors.white,
            iconEnabledColor: Colors.black,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: _inputDecoration(
              label: 'Inquiry Type *',
              hint: 'Select inquiry type',
            ),
            items: inquiryTypes
                .map(
                  (String value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              setState(() => selectedInquiryType = value);
            },
            validator: (String? value) {
              if (value == null || value.trim().isEmpty) {
                return 'Select inquiry type.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: subjectController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Subject *',
              hint: 'e.g. Question about catering packages',
            ),
            validator: _requiredValidator('Enter subject.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: messageController,
            minLines: 5,
            maxLines: 7,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              label: 'Message *',
              hint: 'Tell us how we can help.',
              alignLabelWithHint: true,
            ),
            validator: _requiredValidator('Enter message.'),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            text: 'Next: Contact Info',
            icon: Icons.chevron_right,
            onPressed: _nextFromInquiry,
          ),
        ],
      ),
    );
  }

  Widget _buildContactStep() {
    return Form(
      key: contactFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        key: const ValueKey<int>(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('HOW CAN WE REACH YOU?'),
          const SizedBox(height: 22),
          TextFormField(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Full Name *',
              hint: 'Juan dela Cruz',
            ),
            validator: _requiredValidator('Enter full name.'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Phone Number *',
              hint: '09XXXXXXXXX',
            ),
            validator: (String? value) {
              final String digits =
                  value?.replaceAll(RegExp(r'\D'), '') ?? '';

              if (digits.isEmpty) {
                return 'Enter phone number.';
              }

              if (digits.length < 10 || digits.length > 13) {
                return 'Enter valid phone number.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Email Address *',
              hint: 'yourname@email.com',
            ),
            validator: (String? value) {
              final String email = value?.trim() ?? '';

              if (email.isEmpty) {
                return 'Enter email address.';
              }

              if (!RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              ).hasMatch(email)) {
                return 'Enter valid email address.';
              }

              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: facebookController,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration(
              label: 'Facebook Profile',
              hint: 'facebook.com/yourname (optional)',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _SecondaryButton(
                  text: 'Back',
                  icon: Icons.chevron_left,
                  onPressed: () => _goToStep(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _PrimaryButton(
                  text: 'Review Inquiry',
                  icon: Icons.chevron_right,
                  onPressed: _nextFromContact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      key: const ValueKey<int>(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('REVIEW YOUR INQUIRY'),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
          decoration: BoxDecoration(
            color: cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: fieldBorder),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: 'Inquiry Type',
                value: selectedInquiryType ?? '',
              ),
              _ReviewRow(
                label: 'Subject',
                value: subjectController.text.trim(),
              ),
              _ReviewRow(
                label: 'Message',
                value: messageController.text.trim(),
              ),
              _ReviewRow(
                label: 'Your Name',
                value: nameController.text.trim(),
              ),
              _ReviewRow(
                label: 'Phone',
                value: phoneController.text.trim(),
              ),
              _ReviewRow(
                label: 'Email',
                value: emailController.text.trim(),
              ),
              _ReviewRow(
                label: 'Facebook',
                value: facebookController.text.trim().isEmpty
                    ? 'Not provided'
                    : facebookController.text.trim(),
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: green,
              size: 16,
            ),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                'Make sure your contact details are correct so our team can respond.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _SecondaryButton(
                text: 'Back',
                icon: Icons.chevron_left,
                onPressed:
                    isSubmitting ? null : () => _goToStep(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 5,
              child: _PrimaryButton(
                text: isSubmitting
                    ? 'Sending...'
                    : 'Send Inquiry',
                icon: Icons.send_rounded,
                onPressed:
                    isSubmitting ? null : _submitInquiry,
                loading: isSubmitting,
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      labelStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF5F5146),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFB00020),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: fieldBorder,
          width: 1.4,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: gold,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(
          color: fieldBorder,
          width: 1.4,
        ),
      ),
    );
  }

  String? Function(String?) _requiredValidator(String message) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }
}

enum _StepState {
  inactive,
  active,
  completed,
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.number,
    required this.label,
    required this.state,
  });

  final int number;
  final String label;
  final _StepState state;

  static const Color gold = Color(0xFFD4A91F);
  static const Color green = Color(0xFF0DA65A);
  static const Color inactiveCircle = Color(0xFFE6D5B5);
  static const Color inactiveText = Color(0xFF9B8168);

  @override
  Widget build(BuildContext context) {
    final bool active = state == _StepState.active;
    final bool completed = state == _StepState.completed;

    final Color circleColor = completed
        ? green
        : active
            ? gold
            : inactiveCircle;

    final Color textColor =
        active ? Colors.black : inactiveText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              color: completed || active
                  ? Colors.white
                  : inactiveText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight:
                  active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: completed
          ? const Color(0xFFD4A91F)
          : const Color(0xFFDEC9A3),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFA98769),
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2A2118),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2A2118),
                    fontSize: 10.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: Color(0xFFDDC9A6),
          ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFD4A91F),
          disabledBackgroundColor: const Color(0xFF7A6421),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19),
                  const SizedBox(width: 9),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2A2118),
          side: const BorderSide(
            color: Color(0xFFE2CDA3),
            width: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBackBar extends StatelessWidget {
  const _TopBackBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF090A0A),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF1E1F20),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 21,
            ),
            tooltip: 'Back to Home',
          ),
          const SizedBox(width: 2),
          const Text(
            'Back to Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
