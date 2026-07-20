import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_drawer.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() =>
      _SchedulesScreenState();
}

class _ScheduleItem {
  const _ScheduleItem({
    required this.documentId,
    required this.status,
    required this.client,
    required this.eventType,
    required this.eventDate,
    required this.time,
    required this.prep,
    required this.packageName,
    required this.guests,
    required this.category,
    required this.venue,
  });

  final String documentId;
  final String status;
  final String client;
  final String eventType;
  final DateTime eventDate;
  final String time;
  final String prep;
  final String packageName;
  final String guests;
  final String category;
  final String venue;

  factory _ScheduleItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    String readText(
      String key, [
      String fallback = '',
    ]) {
      final String value =
          data[key]?.toString().trim() ?? '';

      return value.isEmpty ? fallback : value;
    }

    DateTime readDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }

      if (value is String) {
        return DateTime.tryParse(value) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }

      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final DateTime eventDate =
        readDate(data['eventDate']);

    final String eventTime =
        readText('eventTime', 'Not specified');

    final String location =
        readText('location', 'Not specified');

    final String address =
        readText('venueAddress');

    final bool isEventPlace =
        location == "Shepherd's Event Place";

    return _ScheduleItem(
      documentId: document.id,
      status: readText(
        'status',
        'pending',
      ).toLowerCase(),
      client: readText(
        'customerName',
        'Unknown Customer',
      ),
      eventType: readText(
        'eventType',
        'Other Event',
      ),
      eventDate: eventDate,
      time: eventTime,
      prep: _preparationSchedule(
        eventDate,
        eventTime,
      ),
      packageName: readText(
        'packageName',
        'Unnamed Package',
      ),
      guests: readText(
        'expectedGuests',
        'Not specified',
      ),
      category:
          isEventPlace ? 'Event Place' : 'Catering',
      venue: isEventPlace
          ? location
          : address.isNotEmpty
              ? address
              : location,
    );
  }

  static String _preparationSchedule(
    DateTime eventDate,
    String eventTime,
  ) {
    final DateTime dayBefore =
        eventDate.subtract(const Duration(days: 1));

    switch (eventTime.toLowerCase()) {
      case 'morning':
        return '${_formatDate(dayBefore)} · Afternoon';
      case 'afternoon':
        return '${_formatDate(eventDate)} · Morning';
      case 'evening':
        return '${_formatDate(eventDate)} · Afternoon';
      case 'full day':
        return _formatDate(dayBefore);
      default:
        return 'Before event';
    }
  }

  static String _formatDate(DateTime date) {
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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}

class _SchedulesScreenState
    extends State<SchedulesScreen> {
  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'Pending',
    'Confirmed',
    'Needs Reschedule',
    'Catering',
    'Event Place',
  ];

  List<_ScheduleItem> _items = const [];

  List<_ScheduleItem> get _visibleItems {
    final List<_ScheduleItem> results =
        _items.where((item) {
      switch (_selectedFilter) {
        case 'Pending':
          return item.status == 'pending';
        case 'Confirmed':
          return item.status == 'confirmed';
        case 'Needs Reschedule':
          return item.status ==
              'needs_reschedule';
        case 'Catering':
        case 'Event Place':
          return item.category == _selectedFilter;
        case 'All':
        default:
          return true;
      }
    }).toList();

    results.sort(
      (first, second) => first.eventDate.compareTo(
        second.eventDate,
      ),
    );

    return results;
  }

  int _countStatus(String status) {
    return _items
        .where(
          (item) => item.status == status,
        )
        .length;
  }

  int _countCategory(String category) {
    return _items
        .where(
          (item) => item.category == category,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'status',
            whereIn: [
              'pending',
              'confirmed',
              'needs_reschedule',
            ],
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error);
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        _items = snapshot.data!.docs
            .map(_ScheduleItem.fromDocument)
            .toList();

        final List<_ScheduleItem> visible =
            _visibleItems;

        return Scaffold(
          backgroundColor: AT.background,
          appBar: AppBar(
            backgroundColor: AT.background,
            elevation: 0,
            title: const AdminPageHeader(
              title: 'Schedules',
              subtitle:
                  'Active booking schedules',
            ),
          ),
          drawer: const AdminDrawer(
            current: 'Schedules',
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: AT.gold,
              backgroundColor: AT.card,
              onRefresh: _refreshSchedules,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  28,
                ),
                children: [
                  _buildStats(),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Schedules',
                          style: AT.body(
                            size: 14,
                            color: Colors.white,
                            w: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Active booking schedules appear automatically.',
                          style: AT.body(
                            size: 10.5,
                            color: AT.textFaint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFilters(),
                        const SizedBox(height: 8),
                        const Divider(
                          color: AT.border,
                          height: 20,
                        ),
                        if (visible.isEmpty)
                          _buildEmptyState()
                        else
                          ...visible.map(
                            _scheduleCard,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
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
          title: 'Schedules',
          subtitle:
              'Active booking schedules',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Schedules',
      ),
      body: const Center(
        child: CircularProgressIndicator(
          color: AT.gold,
        ),
      ),
    );
  }

  Widget _buildErrorScreen(Object? error) {
    return Scaffold(
      backgroundColor: AT.background,
      appBar: AppBar(
        backgroundColor: AT.background,
        elevation: 0,
        title: const AdminPageHeader(
          title: 'Schedules',
          subtitle:
              'Active booking schedules',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Schedules',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Schedule loading failed:\n$error',
            textAlign: TextAlign.center,
            style: AT.body(
              size: 11,
              color: AT.err,
              w: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshSchedules() async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .where(
          'status',
          isEqualTo: 'confirmed',
        )
        .get();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 28,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.event_available_outlined,
              color: AT.gold,
              size: 38,
            ),
            const SizedBox(height: 10),
            Text(
              'No booking schedules',
              style: AT.body(
                size: 12,
                color: Colors.white,
                w: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedFilter == 'All'
                  ? 'Active booking schedules appear here.'
                  : 'No $_selectedFilter booking found.',
              textAlign: TextAlign.center,
              style: AT.body(
                size: 9.5,
                color: AT.textFaint,
              ),
            ),
          ],
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
            label: 'All',
            value: '${_items.length}',
            sub: 'Active schedules',
            icon: Icons.calendar_month_outlined,
            color: AT.gold,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Pending',
            value: '${_countStatus('pending')}',
            sub: 'Awaiting approval',
            icon: Icons.pending_actions_outlined,
            color: AT.warn,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Confirmed',
            value: '${_countStatus('confirmed')}',
            sub: 'Approved schedules',
            icon: Icons.check_circle_outline,
            color: AT.ok,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Needs Reschedule',
            value:
                '${_countStatus('needs_reschedule')}',
            sub: 'Date conflict',
            icon: Icons.event_repeat_outlined,
            color: AT.info,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Catering',
            value: '${_countCategory('Catering')}',
            sub: 'Customer venues',
            icon: Icons.room_service_outlined,
            color: AT.info,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Event Place',
            value: '${_countCategory('Event Place')}',
            sub: 'Shepherd’s venue',
            icon: Icons.apartment_outlined,
            color: AT.gold,
          ),
        ],
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
                    active ? AT.goldSoft : AT.card2,
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

  Widget _scheduleCard(_ScheduleItem item) {
    final Color categoryColor =
        item.category == 'Event Place'
            ? AT.gold
            : AT.info;

    final bool pending =
        item.status == 'pending';
    final bool needsReschedule =
        item.status == 'needs_reschedule';

    final Color statusColor =
        needsReschedule
            ? AT.info
            : pending
                ? AT.warn
                : AT.ok;

    final String statusLabel =
        needsReschedule
            ? 'Needs Reschedule'
            : pending
                ? 'Pending'
                : 'Confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AT.card2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: statusColor.withOpacity(0.32),
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
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color:
                      categoryColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  item.category == 'Event Place'
                      ? Icons.apartment_outlined
                      : Icons.room_service_outlined,
                  color: categoryColor,
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
                      item.eventType,
                      style: AT.body(
                        size: 12.5,
                        color: Colors.white,
                        w: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.client,
                      style: AT.body(
                        size: 9.5,
                        color: AT.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                statusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailLine(
            Icons.calendar_month_outlined,
            '${_formatDate(item.eventDate)} · '
            '${item.time}',
          ),
          const SizedBox(height: 6),
          _detailLine(
            Icons.inventory_2_outlined,
            item.packageName,
          ),
          const SizedBox(height: 6),
          _detailLine(
            Icons.groups_outlined,
            item.guests,
          ),
          const SizedBox(height: 6),
          _detailLine(
            Icons.location_on_outlined,
            item.venue,
          ),
          const SizedBox(height: 6),
          _detailLine(
            Icons.schedule_outlined,
            'Prep: ${item.prep}',
          ),
          const SizedBox(height: 10),
          OutlinePill(
            item.category,
            color: categoryColor,
          ),
        ],
      ),
    );
  }

  Widget _detailLine(
    IconData icon,
    String text,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AT.gold,
          size: 15,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: AT.body(
              size: 10,
              color: AT.textMuted,
            ),
          ),
        ),
      ],
    );
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

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }
}
