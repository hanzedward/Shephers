import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_drawer.dart';

class InquiriesDisplayScreen extends StatefulWidget {
  const InquiriesDisplayScreen({super.key});

  @override
  State<InquiriesDisplayScreen> createState() =>
      _InquiriesDisplayScreenState();
}

class _InquiryRecord {
  const _InquiryRecord({
    required this.documentId,
    required this.inquiryId,
    required this.inquiryType,
    required this.subject,
    required this.message,
    required this.fullName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.facebookProfile,
    required this.status,
    required this.createdAt,
  });

  final String documentId;
  final String inquiryId;
  final String inquiryType;
  final String subject;
  final String message;
  final String fullName;
  final String phoneNumber;
  final String emailAddress;
  final String facebookProfile;
  final String status;
  final DateTime createdAt;


  factory _InquiryRecord.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();
    final Object? createdAtValue = data['createdAt'];

    final DateTime createdAt = createdAtValue is Timestamp
        ? createdAtValue.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    final String facebook =
        (data['facebookProfile'] ?? '').toString().trim();

    return _InquiryRecord(
      documentId: document.id,
      inquiryId:
          (data['inquiryId'] ?? document.id).toString(),
      inquiryType:
          (data['inquiryType'] ?? 'General Question').toString(),
      subject:
          (data['subject'] ?? 'No subject').toString(),
      message:
          (data['message'] ?? '').toString(),
      fullName:
          (data['fullName'] ?? 'Unknown client').toString(),
      phoneNumber:
          (data['phoneNumber'] ?? '').toString(),
      emailAddress:
          (data['emailAddress'] ?? '').toString(),
      facebookProfile:
          facebook.isEmpty ? 'Not provided' : facebook,
      status:
          (data['status'] ?? 'pending').toString().toLowerCase(),
      createdAt: createdAt,
    );
  }

  _InquiryRecord copyWith({
    String? status,
  }) {
    return _InquiryRecord(
      documentId: documentId,
      inquiryId: inquiryId,
      inquiryType: inquiryType,
      subject: subject,
      message: message,
      fullName: fullName,
      phoneNumber: phoneNumber,
      emailAddress: emailAddress,
      facebookProfile: facebookProfile,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class _InquiriesDisplayScreenState
    extends State<InquiriesDisplayScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Pending',
    'Read',
    'Responded',
  ];

  List<_InquiryRecord> _inquiries = const [];

  String _role = 'none';

  bool get _canUpdateInquiry =>
      _role == 'owner' || _role == 'manager';

  bool get _canDeleteInquiry => _role == 'owner';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};
      final bool active = data['active'] == true;
      final String role =
          (data['role'] ?? '').toString().trim().toLowerCase();

      if (!mounted) return;

      setState(() {
        _role = active &&
                <String>{'owner', 'manager', 'staff'}.contains(role)
            ? role
            : 'none';
      });
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _role = 'none');
    }
  }

  void _showAccessDenied(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AT.err,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_InquiryRecord> get _filteredInquiries {
    final String query =
        _searchController.text.trim().toLowerCase();

    return _inquiries.where((inquiry) {
      final bool statusMatches =
          _selectedFilter == 'All' ||
          inquiry.status ==
              _selectedFilter.toLowerCase();

      final bool searchMatches =
          query.isEmpty ||
          <String>[
            inquiry.inquiryId,
            inquiry.inquiryType,
            inquiry.subject,
            inquiry.message,
            inquiry.fullName,
            inquiry.phoneNumber,
            inquiry.emailAddress,
            inquiry.facebookProfile,
            inquiry.status,
          ].any(
            (value) =>
                value.toLowerCase().contains(query),
          );

      return statusMatches && searchMatches;
    }).toList()
      ..sort(
        (a, b) =>
            b.createdAt.compareTo(a.createdAt),
      );
  }

  int _statusCount(String status) {
    return _inquiries
        .where(
          (inquiry) => inquiry.status == status,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('inquiries')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildLoadError(snapshot.error);
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        _inquiries = snapshot.data!.docs
            .map(_InquiryRecord.fromDocument)
            .toList();

        final List<_InquiryRecord> filtered =
            _filteredInquiries;

        return Scaffold(
      backgroundColor: AT.background,
      appBar: AppBar(
        backgroundColor: AT.background,
        elevation: 0,
        title: const AdminPageHeader(
          title: 'Client Inquiries',
          subtitle:
              'Messages submitted through inquiry form',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Inquiries',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            28,
          ),
          children: [
            _buildStats(),
            const SizedBox(height: 14),
            _buildSearchField(),
            const SizedBox(height: 11),
            _buildFilters(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filtered.length} inquir'
                    '${filtered.length == 1 ? 'y' : 'ies'}',
                    style: AT.body(
                      size: 12,
                      color: Colors.white,
                      w: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Tap card for full details',
                  style: AT.body(
                    size: 9,
                    color: AT.textFaint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered.map(
                _buildInquiryCard,
              ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AT.background,
      appBar: AppBar(
        backgroundColor: AT.background,
        elevation: 0,
        title: const AdminPageHeader(
          title: 'Client Inquiries',
          subtitle: 'Loading live inquiry records',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Inquiries',
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: AT.gold,
        ),
      ),
    );
  }

  Widget _buildLoadError(Object? error) {
    return Scaffold(
      backgroundColor: AT.background,
      appBar: AppBar(
        backgroundColor: AT.background,
        elevation: 0,
        title: const AdminPageHeader(
          title: 'Client Inquiries',
          subtitle: 'Could not load inquiry records',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Inquiries',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Firestore error: $error',
            textAlign: TextAlign.center,
            style: AT.body(
              size: 11,
              color: AT.err,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return SizedBox(
      height: 102,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          MiniStatCard(
            label: 'Total Inquiries',
            value: '${_inquiries.length}',
            sub: 'Live Firestore data',
            icon: Icons.chat_bubble_outline,
            color: AT.info,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Pending',
            value: '${_statusCount('pending')}',
            sub: 'Needs review',
            icon: Icons.markunread_outlined,
            color: AT.warn,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Read',
            value: '${_statusCount('read')}',
            sub: 'Already opened',
            icon: Icons.drafts_outlined,
            color: AT.ok,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Responded',
            value: '${_statusCount('responded')}',
            sub: 'Follow-up done',
            icon: Icons.reply_all_outlined,
            color: AT.violet,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: AT.body(
        size: 11,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText:
            'Search name, subject, type, email, or message',
        hintStyle: AT.body(
          size: 10,
          color: AT.textFaint,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AT.gold,
          size: 20,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: AT.textFaint,
                  size: 18,
                ),
              ),
        filled: true,
        fillColor: AT.card,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: AT.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: AT.gold,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final String filter = _filters[index];
          final bool active =
              _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 170),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color:
                    active ? AT.goldSoft : AT.card,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? AT.gold.withOpacity(0.5)
                      : AT.border,
                ),
              ),
              child: Text(
                filter,
                style: AT.body(
                  size: 8.8,
                  color:
                      active ? AT.gold : AT.textMuted,
                  w: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInquiryCard(
    _InquiryRecord inquiry,
  ) {
    final Color statusColor =
        _statusColor(inquiry.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _openInquiryDetails(inquiry),
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AT.card,
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color:
                    statusColor.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 41,
                      height: 41,
                      decoration: BoxDecoration(
                        color:
                            statusColor.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons
                            .mark_email_unread_outlined,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            inquiry.subject,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: AT.body(
                              size: 11.5,
                              color: Colors.white,
                              w: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${inquiry.fullName} · '
                            '${inquiry.inquiryType}',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: AT.body(
                              size: 8.5,
                              color: AT.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    _statusBadge(
                      inquiry.status,
                      statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Text(
                  inquiry.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AT.body(
                    size: 10,
                    color: AT.textMuted,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  padding:
                      const EdgeInsets.only(top: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AT.border,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        color: AT.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _formatDate(
                            inquiry.createdAt,
                          ),
                          style: AT.body(
                            size: 8,
                            color: AT.textFaint,
                          ),
                        ),
                      ),
                      Text(
                        'View details',
                        style: AT.body(
                          size: 8.2,
                          color: Colors.white70,
                          w: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AT.gold,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openInquiryDetails(
    _InquiryRecord inquiry,
  ) {
    final Color statusColor =
        _statusColor(inquiry.status);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.55,
          maxChildSize: 0.97,
          builder: (
            context,
            scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: AT.card,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding:
                          const EdgeInsets.fromLTRB(
                        18,
                        18,
                        18,
                        28,
                      ),
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: statusColor
                                    .withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons
                                    .mark_email_unread_outlined,
                                color: statusColor,
                                size: 23,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inquiry.subject,
                                    style: AT.title(
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: [
                                      _detailBadge(
                                        inquiry.inquiryType,
                                        AT.gold,
                                      ),
                                      _detailBadge(
                                        _displayStatus(
                                          inquiry.status,
                                        ),
                                        statusColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(
                                sheetContext,
                              ),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _detailSection(
                          title: 'Inquiry Details',
                          children: [
                            _detailRow(
                              Icons
                                  .confirmation_number_outlined,
                              'Inquiry ID',
                              inquiry.inquiryId,
                            ),
                            _detailRow(
                              Icons.category_outlined,
                              'Inquiry Type',
                              inquiry.inquiryType,
                            ),
                            _detailRow(
                              Icons.subject_outlined,
                              'Subject',
                              inquiry.subject,
                            ),
                            _detailRow(
                              Icons.schedule_outlined,
                              'Submitted',
                              _formatDate(
                                inquiry.createdAt,
                              ),
                            ),
                            _detailRow(
                              Icons.fact_check_outlined,
                              'Status',
                              _displayStatus(
                                inquiry.status,
                              ),
                              valueColor: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          title: 'Message',
                          children: [
                            _detailRow(
                              Icons.message_outlined,
                              'Message',
                              inquiry.message,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          title: 'Contact Information',
                          children: [
                            _detailRow(
                              Icons.person_outline,
                              'Full Name',
                              inquiry.fullName,
                            ),
                            _detailRow(
                              Icons.phone_outlined,
                              'Phone Number',
                              inquiry.phoneNumber,
                            ),
                            _detailRow(
                              Icons.email_outlined,
                              'Email Address',
                              inquiry.emailAddress,
                            ),
                            _detailRow(
                              Icons.link_outlined,
                              'Facebook Profile',
                              inquiry.facebookProfile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildDetailActions(
                          sheetContext,
                          inquiry,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailActions(
    BuildContext sheetContext,
    _InquiryRecord inquiry,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: inquiry.emailAddress,
                ),
              );

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email address copied.'),
                ),
              );
            },
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
            ),
            label: Text(
              'Copy Email Address',
              style: AT.body(
                size: 10.5,
                color: Colors.black,
                w: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AT.gold,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_canUpdateInquiry) ...[
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 43,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      _updateStatus(
                        inquiry,
                        inquiry.status == 'read'
                            ? 'pending'
                            : 'read',
                      );
                    },
                    icon: Icon(
                      inquiry.status == 'read'
                          ? Icons.markunread_outlined
                          : Icons.drafts_outlined,
                      size: 17,
                    ),
                    label: Text(
                      inquiry.status == 'read'
                          ? 'Mark Pending'
                          : 'Mark Read',
                      style: AT.body(
                        size: 9.5,
                        color: Colors.white,
                        w: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(
                        color: AT.border2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 43,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _updateStatus(inquiry, 'responded');
                    },
                    icon: const Icon(
                      Icons.reply_all_outlined,
                      size: 17,
                    ),
                    label: Text(
                      'Responded',
                      style: AT.body(
                        size: 9.5,
                        color: AT.ok,
                        w: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AT.ok,
                      side: const BorderSide(color: AT.ok),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_canDeleteInquiry) ...[
          const SizedBox(height: 9),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () async {
                final bool delete =
                    await _confirmDelete() ?? false;

                if (!delete) return;

                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }

                await _deleteInquiry(inquiry);
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 17,
              ),
              label: Text(
                'Delete Inquiry',
                style: AT.body(
                  size: 9.5,
                  color: AT.err,
                  w: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AT.err,
                side: const BorderSide(color: AT.err),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
        if (!_canUpdateInquiry && !_canDeleteInquiry) ...[
          const SizedBox(height: 9),
          Text(
            'Staff access is view-only for inquiries.',
            textAlign: TextAlign.center,
            style: AT.body(
              size: 8.8,
              color: AT.textFaint,
              w: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _updateStatus(
    _InquiryRecord inquiry,
    String status,
  ) async {
    if (!_canUpdateInquiry) {
      _showAccessDenied('Manager or owner access required.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(inquiry.documentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Inquiry marked '
            '${_displayStatus(status).toLowerCase()}.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status update failed: ${error.message ?? error.code}',
          ),
          backgroundColor: AT.err,
        ),
      );
    }
  }

  Future<void> _deleteInquiry(
    _InquiryRecord inquiry,
  ) async {
    if (!_canDeleteInquiry) {
      _showAccessDenied('Owner access required.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inquiries')
          .doc(inquiry.documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inquiry deleted from database.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: ${error.message ?? error.code}',
          ),
          backgroundColor: AT.err,
        ),
      );
    }
  }

  Future<bool?> _confirmDelete() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AT.card,
          title: const Text(
            'Delete inquiry?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: const Text(
            'This permanently removes the inquiry from Firestore.',
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
                'Delete',
                style: TextStyle(
                  color: AT.err,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AT.card2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AT.border,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AT.body(
              size: 8,
              color: AT.gold,
              w: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: AT.goldSoft,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AT.gold,
              size: 16,
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
                    color:
                        valueColor ?? Colors.white,
                    w: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Text(
        text,
        style: AT.body(
          size: 7.5,
          color: color,
          w: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusBadge(
    String status,
    Color color,
  ) {
    return Container(
      constraints:
          const BoxConstraints(maxWidth: 94),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Text(
        _displayStatus(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AT.body(
          size: 7.3,
          color: color,
          w: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: AT.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AT.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: AT.gold,
            size: 42,
          ),
          const SizedBox(height: 10),
          Text(
            'No inquiries found',
            style: AT.title(
              size: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Change search or filter.',
            style: AT.body(
              size: 9,
              color: AT.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'read':
        return AT.info;
      case 'responded':
        return AT.ok;
      case 'pending':
        return AT.warn;
      default:
        return AT.textMuted;
    }
  }

  String _displayStatus(String status) {
    if (status.isEmpty) return 'Pending';

    return '${status[0].toUpperCase()}'
        '${status.substring(1)}';
  }

  String _formatDate(DateTime date) {
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

    final String hour =
        (date.hour % 12 == 0 ? 12 : date.hour % 12)
            .toString();
    final String minute =
        date.minute.toString().padLeft(2, '0');
    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year} · '
        '$hour:$minute $period';
  }
}
