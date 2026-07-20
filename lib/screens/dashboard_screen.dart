import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/admin_drawer.dart';
import 'inquiries_display_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.initialName = 'Team Member',
    this.initialRole = 'staff',
  });

  final String initialName;
  final String initialRole;

  static const Color gold = Color(0xFFD5A021);
  static const Color background = Color(0xFF080A0B);
  static const Color headerColor = Color(0xFF0C0E0F);
  static const Color cardColor = Color(0xFF111416);
  static const Color cream = Color(0xFFF7F1E3);
  static const Color darkText = Color(0xFF201D17);
  static const Color border = Color(0xFF292D2F);
  static const Color textMuted = Color(0xFFA8A8A2);

  static const Color goodColor = Color(0xFF58B844);
  static const Color lowColor = Color(0xFFE5A719);
  static const Color repairColor = Color(0xFFE25A4F);
  static const Color infoColor = Color(0xFF5A91D8);
  static const Color violetColor = Color(0xFF9B7BD5);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore database = FirebaseFirestore.instance;
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : database.collection('users').doc(user.uid).snapshots(),
      builder: (context, profileSnapshot) {
        final Map<String, dynamic> profile =
            profileSnapshot.data?.data() ?? <String, dynamic>{};

        final String accountName =
            (profile['name'] ?? initialName).toString().trim();
        final String accountRole =
            (profile['role'] ?? initialRole)
                .toString()
                .trim()
                .toLowerCase();

        return Scaffold(
      backgroundColor: background,
      drawer: const AdminDrawer(current: 'Dashboard'),
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: database.collection('bookings').snapshots(),
        builder: (context, bookingSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: database.collection('inquiries').snapshots(),
            builder: (context, inquirySnapshot) {
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: database.collection('inventory_items').snapshots(),
                builder: (context, inventorySnapshot) {
                  final _DashboardData data = _DashboardData.fromDocuments(
                    bookingDocuments: bookingSnapshot.data?.docs ?? const [],
                    inquiryDocuments: inquirySnapshot.data?.docs ?? const [],
                    inventoryDocuments:
                        inventorySnapshot.data?.docs ?? const [],
                  );

                  final bool loading =
                      bookingSnapshot.connectionState ==
                              ConnectionState.waiting ||
                          inquirySnapshot.connectionState ==
                              ConnectionState.waiting ||
                          inventorySnapshot.connectionState ==
                              ConnectionState.waiting;

                  final Object? error = bookingSnapshot.error ??
                      inquirySnapshot.error ??
                      inventorySnapshot.error;

                  return SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
                      children: [
                        if (loading) ...[
                          const LinearProgressIndicator(
                            minHeight: 2,
                            color: gold,
                            backgroundColor: cardColor,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (error != null) ...[
                          _buildErrorBanner(error),
                          const SizedBox(height: 12),
                        ],
                        _buildWelcomePanel(
                          accountName,
                          accountRole,
                        ),
                        const SizedBox(height: 16),
                        _sectionHeading(
                          eyebrow: 'OPERATIONS OVERVIEW',
                          title: 'Today at a Glance',
                          subtitle:
                              'Live summary from bookings, clients, inquiries, and inventory.',
                        ),
                        const SizedBox(height: 12),
                        _buildStatGrid(data),
                        const SizedBox(height: 20),
                        _buildInventoryCard(data),
                        const SizedBox(height: 20),
                        _buildLatestInquiryCard(context, data.latestInquiry),
                        const SizedBox(height: 20),
                        _buildRecentActivityCard(data.activities),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 68,
      backgroundColor: headerColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 38,
            height: 38,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.admin_panel_settings_outlined,
                color: gold,
                size: 34,
              );
            },
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Shepherd's",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'ADMIN DASHBOARD',
                style: GoogleFonts.montserrat(
                  color: gold,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dashboard data refreshes automatically.'),
              ),
            );
          },
          icon: const Icon(
            Icons.cloud_done_outlined,
            color: Colors.white,
          ),
          tooltip: 'Live Firebase data',
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildErrorBanner(Object error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: repairColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: repairColor.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: repairColor,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Dashboard could not read some Firebase data. Check Firestore rules.\n$error',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
                fontSize: 9.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePanel(
    String accountName,
    String accountRole,
  ) {
    final int hour = DateTime.now().hour;
    final String greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.45)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF191B1C),
            Color(0xFF101314),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: gold.withOpacity(0.55)),
            ),
            child: const Icon(
              Icons.dashboard_customize_outlined,
              color: gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, ${accountName.isEmpty ? 'Team Member' : accountName}',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_roleLabel(accountRole)} access · Live operational data from Firebase.',
                  style: GoogleFonts.montserrat(
                    color: Colors.white60,
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'manager':
        return 'Manager';
      case 'staff':
      default:
        return 'Staff';
    }
  }

  Widget _sectionHeading({
    required String eyebrow,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: GoogleFonts.montserrat(
            color: gold,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.montserrat(
            color: textMuted,
            fontSize: 10,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildStatGrid(_DashboardData data) {
    final List<_StatData> stats = [
      _StatData(
        label: 'Total Bookings',
        value: '${data.totalBookings}',
        detail: 'All submitted bookings',
        icon: Icons.event_available_outlined,
        color: gold,
      ),
      _StatData(
        label: 'Unique Clients',
        value: '${data.uniqueClients}',
        detail: 'Same email or phone counted once',
        icon: Icons.people_outline,
        color: goodColor,
      ),
      _StatData(
        label: 'Upcoming Events',
        value: '${data.upcomingEvents}',
        detail: 'Confirmed or in preparation',
        icon: Icons.calendar_month_outlined,
        color: infoColor,
      ),
      _StatData(
        label: 'New Inquiries',
        value: '${data.newInquiries}',
        detail: 'Pending review',
        icon: Icons.mark_email_unread_outlined,
        color: DashboardScreen.violetColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 760 ? 4 : 2;

        return GridView.builder(
          itemCount: stats.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 118,
          ),
          itemBuilder: (context, index) => _statCard(stats[index]),
        );
      },
    );
  }

  Widget _statCard(_StatData stat) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stat.color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontSize: 7.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(_DashboardData data) {
    final int totalStock =
        data.goodStock + data.lowStock + data.missingStock;
    final int attention = data.lowStock + data.missingStock;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.inventory_2_outlined,
            title: 'Inventory Stock',
            subtitle: 'Live item condition from inventory_items',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 330;
              final Widget pie = _inventoryPie(data, totalStock);
              final Widget legend = _inventoryLegend(data);

              if (compact) {
                return Column(
                  children: [
                    pie,
                    const SizedBox(height: 18),
                    legend,
                  ],
                );
              }

              return Row(
                children: [
                  pie,
                  const SizedBox(width: 20),
                  Expanded(child: legend),
                ],
              );
            },
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: (attention == 0 ? goodColor : gold).withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    (attention == 0 ? goodColor : gold).withOpacity(0.28),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  attention == 0
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: attention == 0 ? goodColor : lowColor,
                  size: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    totalStock == 0
                        ? 'No inventory records yet.'
                        : attention == 0
                            ? 'All inventory items are in good condition.'
                            : '$attention inventory item${attention == 1 ? '' : 's'} need attention.',
                    style: GoogleFonts.montserrat(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: gold, size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  color: textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inventoryPie(_DashboardData data, int totalStock) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(150),
            painter: _InventoryPiePainter(
              values: [
                data.goodStock.toDouble(),
                data.lowStock.toDouble(),
                data.missingStock.toDouble(),
              ],
              colors: const [
                goodColor,
                lowColor,
                repairColor,
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalStock',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'ITEMS',
                style: GoogleFonts.montserrat(
                  color: textMuted,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inventoryLegend(_DashboardData data) {
    return Column(
      children: [
        _LegendRow(
          label: 'Good Condition',
          value: '${data.goodStock} items',
          color: goodColor,
        ),
        const SizedBox(height: 12),
        _LegendRow(
          label: 'Low Stock',
          value: '${data.lowStock} items',
          color: DashboardScreen.lowColor,
        ),
        const SizedBox(height: 12),
        _LegendRow(
          label: 'Missing / Out',
          value: '${data.missingStock} items',
          color: repairColor,
        ),
      ],
    );
  }

  Widget _buildLatestInquiryCard(
    BuildContext context,
    Map<String, dynamic>? inquiry,
  ) {
    final String fullName = _readString(inquiry?['fullName'], 'No inquiry');
    final String inquiryId = _readString(
      inquiry?['inquiryId'],
      _readString(inquiry?['_documentId'], '—'),
    );
    final String message = _readString(
      inquiry?['message'],
      'Customer inquiries will appear here after submission.',
    );
    final String status = _readString(inquiry?['status'], 'none').toLowerCase();
    final DateTime? createdAt = _asDateTime(inquiry?['createdAt']);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Inquiry',
                      style: GoogleFonts.playfairDisplay(
                        color: darkText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Newest Firebase inquiry',
                      style: GoogleFonts.montserrat(
                        color: darkText.withOpacity(0.58),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              if (inquiry != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status == 'pending' ? 'NEW' : status.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF7A5810),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.48),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: darkText.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: GoogleFonts.montserrat(
                    color: darkText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  createdAt == null
                      ? inquiryId
                      : '$inquiryId · ${_formatDate(createdAt)}',
                  style: GoogleFonts.montserrat(
                    color: darkText.withOpacity(0.52),
                    fontSize: 8.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: darkText.withOpacity(0.78),
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InquiriesDisplayScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: Text(
                'Open Inquiries',
                style: GoogleFonts.montserrat(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkText,
                foregroundColor: cream,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(List<_ActivityData> activities) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            icon: Icons.history_rounded,
            title: 'Recent Activity',
            subtitle: 'Latest Firebase records and updates',
          ),
          const SizedBox(height: 14),
          const Divider(color: border, height: 1),
          const SizedBox(height: 14),
          if (activities.isEmpty)
            Text(
              'No recent activity yet.',
              style: GoogleFonts.montserrat(
                color: textMuted,
                fontSize: 10,
              ),
            )
          else
            for (int index = 0; index < activities.length; index++) ...[
              _ActivityRow(
                icon: activities[index].icon,
                iconColor: activities[index].color,
                title: activities[index].title,
                subtitle: activities[index].subtitle,
                time: _relativeTime(activities[index].date),
              ),
              if (index != activities.length - 1)
                const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _DashboardData {
  const _DashboardData({
    required this.totalBookings,
    required this.uniqueClients,
    required this.upcomingEvents,
    required this.newInquiries,
    required this.goodStock,
    required this.lowStock,
    required this.missingStock,
    required this.latestInquiry,
    required this.activities,
  });

  final int totalBookings;
  final int uniqueClients;
  final int upcomingEvents;
  final int newInquiries;
  final int goodStock;
  final int lowStock;
  final int missingStock;
  final Map<String, dynamic>? latestInquiry;
  final List<_ActivityData> activities;

  factory _DashboardData.fromDocuments({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        bookingDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        inquiryDocuments,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        inventoryDocuments,
  }) {
    final List<Map<String, dynamic>> bookings = bookingDocuments
        .map(
          (document) => {
            ...document.data(),
            '_documentId': document.id,
          },
        )
        .toList();

    final List<Map<String, dynamic>> inquiries = inquiryDocuments
        .map(
          (document) => {
            ...document.data(),
            '_documentId': document.id,
          },
        )
        .toList();

    final List<Map<String, dynamic>> inventory = inventoryDocuments
        .map(
          (document) => {
            ...document.data(),
            '_documentId': document.id,
          },
        )
        .toList();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    final int upcomingEvents = bookings.where((booking) {
      final DateTime? eventDate = _asDateTime(booking['eventDate']) ??
          _dateFromKey(booking['eventDateKey']);
      final String status =
          _readString(booking['status'], '').trim().toLowerCase();
      final bool approved =
          status == 'confirmed' || status == 'in preparation';

      return approved && eventDate != null && !eventDate.isBefore(today);
    }).length;

    final int newInquiries = inquiries.where((inquiry) {
      return _readString(inquiry['status'], '').trim().toLowerCase() ==
          'pending';
    }).length;

    int goodStock = 0;
    int lowStock = 0;
    int missingStock = 0;

    for (final Map<String, dynamic> item in inventory) {
      final String status = _inventoryStatus(item);

      if (status == 'missing') {
        missingStock++;
      } else if (status == 'low') {
        lowStock++;
      } else {
        goodStock++;
      }
    }

    inquiries.sort((first, second) {
      final DateTime firstDate =
          _asDateTime(first['createdAt']) ?? DateTime(1970);
      final DateTime secondDate =
          _asDateTime(second['createdAt']) ?? DateTime(1970);
      return secondDate.compareTo(firstDate);
    });

    final List<_ActivityData> activities = _buildActivities(
      bookings: bookings,
      inquiries: inquiries,
      inventory: inventory,
      lowStock: lowStock,
      missingStock: missingStock,
    );

    return _DashboardData(
      totalBookings: bookings.length,
      uniqueClients: _countUniqueClients(
        bookings: bookings,
        inquiries: inquiries,
      ),
      upcomingEvents: upcomingEvents,
      newInquiries: newInquiries,
      goodStock: goodStock,
      lowStock: lowStock,
      missingStock: missingStock,
      latestInquiry: inquiries.isEmpty ? null : inquiries.first,
      activities: activities,
    );
  }

  static int _countUniqueClients({
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> inquiries,
  }) {
    final List<Map<String, dynamic>> records = [
      ...bookings,
      ...inquiries,
    ];

    if (records.isEmpty) return 0;

    final List<int> parent = List<int>.generate(records.length, (index) => index);
    final Map<String, int> emailOwner = <String, int>{};
    final Map<String, int> phoneOwner = <String, int>{};

    int find(int value) {
      if (parent[value] != value) {
        parent[value] = find(parent[value]);
      }
      return parent[value];
    }

    void union(int first, int second) {
      final int firstRoot = find(first);
      final int secondRoot = find(second);

      if (firstRoot != secondRoot) {
        parent[secondRoot] = firstRoot;
      }
    }

    for (int index = 0; index < records.length; index++) {
      final String email = _normalizeEmail(records[index]['emailAddress']);
      final String phone = _normalizePhone(records[index]['phoneNumber']);

      if (email.isNotEmpty) {
        final int? owner = emailOwner[email];
        if (owner == null) {
          emailOwner[email] = index;
        } else {
          union(index, owner);
        }
      }

      if (phone.isNotEmpty) {
        final int? owner = phoneOwner[phone];
        if (owner == null) {
          phoneOwner[phone] = index;
        } else {
          union(index, owner);
        }
      }
    }

    return <int>{
      for (int index = 0; index < records.length; index++) find(index),
    }.length;
  }

  static List<_ActivityData> _buildActivities({
    required List<Map<String, dynamic>> bookings,
    required List<Map<String, dynamic>> inquiries,
    required List<Map<String, dynamic>> inventory,
    required int lowStock,
    required int missingStock,
  }) {
    final List<_ActivityData> activities = [];

    if (bookings.isNotEmpty) {
      final List<Map<String, dynamic>> sortedBookings = [...bookings]
        ..sort((first, second) {
          final DateTime firstDate = _recordActivityDate(first);
          final DateTime secondDate = _recordActivityDate(second);
          return secondDate.compareTo(firstDate);
        });

      final Map<String, dynamic> booking = sortedBookings.first;
      final String status =
          _readString(booking['status'], 'pending').toLowerCase();
      final String customer =
          _readString(booking['customerName'], 'Customer');
      final String eventType = _readString(booking['eventType'], 'Event');

      activities.add(
        _ActivityData(
          icon: status == 'confirmed'
              ? Icons.check_circle
              : Icons.event_note_outlined,
          color: status == 'confirmed'
              ? DashboardScreen.goodColor
              : DashboardScreen.infoColor,
          title: _bookingActivityTitle(status),
          subtitle: '$customer · $eventType',
          date: _recordActivityDate(booking),
        ),
      );
    }

    if (inquiries.isNotEmpty) {
      final Map<String, dynamic> inquiry = inquiries.first;
      activities.add(
        _ActivityData(
          icon: Icons.mark_email_unread_outlined,
          color: DashboardScreen.violetColor,
          title: 'Inquiry received',
          subtitle:
              '${_readString(inquiry['fullName'], 'Customer')} · ${_readString(inquiry['subject'], 'General inquiry')}',
          date: _recordActivityDate(inquiry),
        ),
      );
    }

    if (inventory.isNotEmpty && lowStock + missingStock > 0) {
      DateTime latestInventoryUpdate = DateTime(1970);

      for (final Map<String, dynamic> item in inventory) {
        final DateTime date = _recordActivityDate(item);
        if (date.isAfter(latestInventoryUpdate)) {
          latestInventoryUpdate = date;
        }
      }

      activities.add(
        _ActivityData(
          icon: Icons.inventory_2_outlined,
          color: DashboardScreen.lowColor,
          title: 'Inventory needs attention',
          subtitle:
              '$lowStock low-stock · $missingStock missing/out',
          date: latestInventoryUpdate,
        ),
      );
    }

    activities.sort((first, second) => second.date.compareTo(first.date));
    return activities.take(3).toList();
  }

  static String _bookingActivityTitle(String status) {
    switch (status) {
      case 'confirmed':
        return 'Booking confirmed';
      case 'in preparation':
        return 'Booking in preparation';
      case 'completed':
        return 'Booking completed';
      case 'declined':
        return 'Booking declined';
      case 'cancelled':
        return 'Booking cancelled';
      case 'pending':
      default:
        return 'New booking submitted';
    }
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;
}

class _ActivityData {
  const _ActivityData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.date,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final DateTime date;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.montserrat(
            color: const Color(0xFFA8A8A2),
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.13),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.25)),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFA8A8A2),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          time,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF777A7C),
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }
}

class _InventoryPiePainter extends CustomPainter {
  const _InventoryPiePainter({
    required this.values,
    required this.colors,
  });

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (sum, value) => sum + value);
    final Rect rect = Offset.zero & size;
    final double strokeWidth = size.width * 0.16;

    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFF272B2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      0,
      math.pi * 2,
      false,
      backgroundPaint,
    );

    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    const double gap = 0.035;

    for (int index = 0; index < values.length; index++) {
      final double sweepAngle = (values[index] / total) * math.pi * 2;

      final Paint paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle + gap / 2,
        math.max(0, sweepAngle - gap),
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _InventoryPiePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.colors != colors;
  }
}

String _readString(dynamic value, String fallback) {
  final String text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

DateTime? _dateFromKey(dynamic value) {
  final String key = value?.toString().trim() ?? '';
  if (key.isEmpty) return null;
  return DateTime.tryParse(key);
}

DateTime _recordActivityDate(Map<String, dynamic> record) {
  return _asDateTime(record['statusUpdatedAt']) ??
      _asDateTime(record['updatedAt']) ??
      _asDateTime(record['createdAt']) ??
      DateTime(1970);
}

String _normalizeEmail(dynamic value) {
  return value?.toString().trim().toLowerCase() ?? '';
}

String _normalizePhone(dynamic value) {
  String digits = value?.toString().replaceAll(RegExp(r'\D'), '') ?? '';

  if (digits.startsWith('63') && digits.length >= 12) {
    digits = '0${digits.substring(2)}';
  } else if (digits.startsWith('9') && digits.length == 10) {
    digits = '0$digits';
  }

  return digits;
}

String _inventoryStatus(Map<String, dynamic> item) {
  final String storedStatus =
      _readString(item['status'], '').trim().toLowerCase();

  if (storedStatus.contains('missing') ||
      storedStatus.contains('out') ||
      storedStatus.contains('repair')) {
    return 'missing';
  }

  if (storedStatus.contains('low')) return 'low';
  if (storedStatus.contains('good')) return 'good';

  final int quantity = _readInt(item['quantity'] ?? item['qty']);
  final int minimum =
      _readInt(item['minimumQuantity'] ?? item['minimum'] ?? item['min']);

  if (quantity <= 0) return 'missing';
  if (quantity < minimum) return 'low';
  return 'good';
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatDate(DateTime date) {
  const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _relativeTime(DateTime date) {
  if (date.year == 1970) return '—';

  final Duration difference = DateTime.now().difference(date);

  if (difference.isNegative || difference.inMinutes < 1) return 'now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min';
  if (difference.inHours < 24) return '${difference.inHours} hr';
  if (difference.inDays < 7) return '${difference.inDays} d';
  return _formatDate(date);
}
