import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  static const Color gold = Color(0xFFD79A00);
  static const Color background = Color(0xFF080C0E);
  static const Color panel = Color(0xFF151A1E);
  static const Color panelLight = Color(0xFF1B2025);
  static const Color border = Color(0xFF252B30);
  static const Color muted = Color(0xFF9CA3A9);
  static const Color green = Color(0xFF60D83B);

  void _backToHome(BuildContext context) {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                children: [
                  _buildUserMessage(
                    'Recommend a catering package for my wedding on '
                    'May 24, 2026 with 150 guests and budget around ₱150,000.',
                    '9:41 AM',
                  ),
                  const SizedBox(height: 10),
                  _buildAssistantPackageMessage(),
                  const SizedBox(height: 10),
                  _buildUserMessage(
                    'What add-ons do you suggest?',
                    '9:43 AM',
                  ),
                  const SizedBox(height: 10),
                  _buildAssistantAddOnsMessage(),
                ],
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _backToHome(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 23,
            ),
            tooltip: 'Back to Home',
          ),
          const SizedBox(width: 2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF101518),
              shape: BoxShape.circle,
              border: Border.all(
                color: gold,
                width: 1.4,
              ),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: green,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: null,
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMessage(
    String message,
    String time,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 8),
          decoration: const BoxDecoration(
            color: gold,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      color: Color(0xFFEBD394),
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    color: Color(0xFFEBD394),
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantPackageMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBotAvatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 9),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sure! Based on your event details, I recommend '
                  'the following package:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: panelLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/gallery_1.jpg',
                          width: 72,
                          height: 112,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return Container(
                              width: 72,
                              height: 112,
                              color: const Color(0xFF272D31),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.photo_outlined,
                                color: gold,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Elegant Wedding Package',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF32264C),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Best Match',
                                    style: TextStyle(
                                      color: Color(0xFFD9C5FF),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '₱128,000  •  150 Guests',
                              style: TextStyle(
                                color: muted,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const _FeatureRow('3-Course Buffet'),
                            const _FeatureRow('Venue Setup'),
                            const _FeatureRow('Floral Decoration'),
                            const _FeatureRow('Event Coordination'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'Why this package?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'This package fits your budget and is ideal for '
                  'weddings with 100–200 guests.',
                  style: TextStyle(
                    color: Color(0xFFD2D4D6),
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '9:42 AM',
                    style: TextStyle(
                      color: muted,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantAddOnsMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBotAvatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 9),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Here are some popular add-ons that pair well '
                  'with your event:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 11),
                const _AddOnRow(
                  imagePath: 'assets/images/gallery_2.jpg',
                  title: 'Live Acoustic Band',
                  price: '₱18,000',
                  selected: true,
                ),
                const SizedBox(height: 8),
                const _AddOnRow(
                  imagePath: 'assets/images/gallery_3.jpg',
                  title: 'Photo Booth',
                  price: '₱8,000',
                  selected: true,
                ),
                const SizedBox(height: 8),
                const _AddOnRow(
                  imagePath: 'assets/images/gallery_1.jpg',
                  title: 'LED Dance Floor',
                  price: '₱12,000',
                  selected: false,
                ),
                const SizedBox(height: 5),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '9:43 AM',
                    style: TextStyle(
                      color: muted,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF101518),
        shape: BoxShape.circle,
        border: Border.all(
          color: gold,
          width: 1.5,
        ),
      ),
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
        size: 21,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 12),
      decoration: const BoxDecoration(
        color: background,
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF11171A),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: border),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Type your message...',
                      style: TextStyle(
                        color: Color(0xFF70787E),
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFF7D858A),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 9),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: gold,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 7,
            backgroundColor: Color(0xFF55B83B),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 9,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD5D7D9),
                fontSize: 8.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.imagePath,
    required this.title,
    required this.price,
    required this.selected,
  });

  final String imagePath;
  final String title;
  final String price;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD79A00);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Image.asset(
            imagePath,
            width: 38,
            height: 30,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                width: 38,
                height: 30,
                color: const Color(0xFF272D31),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.photo_outlined,
                  color: gold,
                  size: 15,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: selected ? gold : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? gold
                  : const Color(0xFF727A80),
            ),
          ),
          child: selected
              ? const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 14,
                )
              : null,
        ),
      ],
    );
  }
}
