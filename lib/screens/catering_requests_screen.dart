import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/admin_drawer.dart';
import 'reservation_screen.dart';

class CateringRequestsScreen extends StatefulWidget {
  const CateringRequestsScreen({super.key});

  @override
  State<CateringRequestsScreen> createState() =>
      _CateringRequestsScreenState();
}

class _CateringReservation {
  const _CateringReservation({
    this.documentId = '',
    required this.request,
    this.status = 'pending',
  });

  final String documentId;
  final ReservationRequest request;
  final String status;


  factory _CateringReservation.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    DateTime readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ??
            DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    String readText(
      String key, [
      String fallback = '',
    ]) {
      final String text =
          data[key]?.toString().trim() ?? '';
      return text.isEmpty ? fallback : text;
    }

    List<String> readList(dynamic value) {
      if (value is Iterable) {
        return value
            .map((item) => item.toString())
            .toList();
      }
      return const [];
    }

    return _CateringReservation(
      documentId: document.id,
      status: readText('status', 'pending').toLowerCase(),
      request: ReservationRequest(
        packageName:
            readText('packageName', 'Unnamed Package'),
        packagePrice:
            readText('packagePrice', 'Price unavailable'),
        packageImage: readText(
          'packageImage',
          'assets/images/full_catering.jpg',
        ),
        packageCapacity:
            readText('packageCapacity', 'Not specified'),
        packageInclusions:
            readList(data['packageInclusions']),
        eventDate: readDate(data['eventDate']),
        eventTime:
            readText('eventTime', 'Not specified'),
        eventType:
            readText('eventType', 'Other'),
        expectedGuests:
            readText('expectedGuests', 'Not specified'),
        location:
            readText('location', 'Not specified'),
        venueAddress:
            readText('venueAddress'),
        customerName:
            readText('customerName', 'Unknown Customer'),
        phoneNumber:
            readText('phoneNumber'),
        emailAddress:
            readText('emailAddress'),
        specialRequests:
            readText('specialRequests'),
        createdAt: readDate(data['createdAt']),
      ),
    );
  }

  _CateringReservation copyWith({
    String? status,
  }) {
    return _CateringReservation(
      documentId: documentId,
      request: request,
      status: status ?? this.status,
    );
  }
}


class _AdminCateringPackage {
  const _AdminCateringPackage({
    required this.name,
    required this.price,
    required this.capacity,
    required this.imagePath,
    required this.inclusions,
  });

  final String name;
  final String price;
  final String capacity;
  final String imagePath;
  final List<String> inclusions;
}

class _CateringRequestsScreenState
    extends State<CateringRequestsScreen> {
  static const Color gold = Color(0xFFD5A021);
  static const Color background = Color(0xFF080A0B);
  static const Color headerColor = Color(0xFF0C0E0F);
  static const Color cardColor = Color(0xFF111416);
  static const Color cardColor2 = Color(0xFF171B1D);
  static const Color border = Color(0xFF292D2F);
  static const Color textMuted = Color(0xFFA8A8A2);
  static const Color green = Color(0xFF58B844);
  static const Color orange = Color(0xFFE5A719);
  static const Color red = Color(0xFFE25A4F);
  static const Color blue = Color(0xFF5A91D8);
  static const Color violet = Color(0xFF9B7BD5);

  static const int _highWorkloadThreshold = 3;

  static const List<String> _monthNames = [
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

  static const List<String> _filters = [
    'Upcoming',
    'All',
    'Past',
  ];

  static const List<_AdminCateringPackage> _packageOptions = [
    _AdminCateringPackage(
      name: 'Classic Package',
      price: '₱12,000',
      capacity: 'Up to 100 pax',
      imagePath: 'assets/images/light_catering.jpg',
      inclusions: [
        '2-course set menu',
        'Rice and one beverage option',
        'Basic buffet setup',
        'Service staff assistance',
        'Basic cleanup after service',
      ],
    ),
    _AdminCateringPackage(
      name: 'Premium Package',
      price: '₱24,000',
      capacity: 'Up to 200 pax',
      imagePath: 'assets/images/full_catering.jpg',
      inclusions: [
        'Buffet spread with 3 viands',
        'Steamed rice, drinks, and dessert',
        'Professional service staff',
        'Buffet setup and cleanup',
        'Tables and basic linens',
        'Serving utensils and food warmers',
      ],
    ),
    _AdminCateringPackage(
      name: 'Grand Package',
      price: '₱42,000',
      capacity: 'Up to 300 pax',
      imagePath: 'assets/images/premium_catering.jpg',
      inclusions: [
        'Full buffet with 5 viands',
        'Appetizers and dessert bar',
        'Rice and beverage selections',
        'Complete tableware',
        'Event staff and coordinator',
        'Full buffet setup and cleanup',
      ],
    ),
  ];

  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'Upcoming';

  List<_CateringReservation> _requests = const [];

  String _role = 'none';

  bool get _canCreateRequest =>
      _role == 'owner' || _role == 'manager';

  bool get _canUpdateRequest =>
      _role == 'owner' ||
      _role == 'manager' ||
      _role == 'staff';

  bool get _canDeleteRequest =>
      _role == 'owner';

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

  void _showAccessDenied(String action) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action requires manager or owner access.'),
        backgroundColor: red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CateringReservation> get _filteredRequests {
    final String query =
        _searchController.text.trim().toLowerCase();

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final List<_CateringReservation> results =
        _requests.where((reservation) {
      final ReservationRequest request =
          reservation.request;

      final DateTime eventDay = DateTime(
        request.eventDate.year,
        request.eventDate.month,
        request.eventDate.day,
      );

      final String status =
          reservation.status.trim().toLowerCase();

      final bool filterMatches;

      switch (_selectedFilter) {
        case 'Past':
          filterMatches =
              eventDay.isBefore(today) ||
              status == 'completed';
          break;
        case 'All':
          filterMatches = true;
          break;
        case 'Upcoming':
        default:
          filterMatches =
              !eventDay.isBefore(today) &&
              status != 'completed' &&
              status != 'declined';
      }

      final List<String> values = [
        request.customerName,
        request.emailAddress,
        request.phoneNumber,
        request.eventType,
        request.packageName,
        request.venueAddress,
        request.expectedGuests,
        request.eventTime,
        reservation.status,
      ];

      final bool queryMatches =
          query.isEmpty ||
          values.any(
            (value) =>
                value.toLowerCase().contains(query),
          );

      return filterMatches && queryMatches;
    }).toList();

    results.sort((first, second) {
      final int comparison = first.request.eventDate
          .compareTo(second.request.eventDate);

      return _selectedFilter == 'Past'
          ? -comparison
          : comparison;
    });

    return results;
  }

  int _statusCount(String status) {
    return _requests.where((reservation) {
      return reservation.status == status;
    }).length;
  }

  bool _sameEventDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<_CateringReservation> _requestsOnDate(
    DateTime date,
  ) {
    return _requests.where((reservation) {
      return _sameEventDate(
        reservation.request.eventDate,
        date,
      );
    }).toList();
  }

  int _bookingsOnDate(DateTime date) {
    return _requestsOnDate(date)
        .where((reservation) {
          return reservation.status != 'declined' &&
              reservation.status != 'cancelled';
        })
        .length;
  }

  int _confirmedRequestsOnDate(DateTime date) {
    return _requestsOnDate(date)
        .where((reservation) {
          return reservation.status == 'confirmed' ||
              reservation.status ==
                  'in preparation' ||
              reservation.status == 'completed';
        })
        .length;
  }

  Color _dateLoadColor(DateTime date) {
    final int confirmed =
        _confirmedRequestsOnDate(date);

    if (confirmed >= 4) return red;
    if (confirmed >= 3) return orange;
    return green;
  }

  String _dateLoadLabel(DateTime date) {
    final int bookings =
        _bookingsOnDate(date);
    final int confirmed =
        _confirmedRequestsOnDate(date);

    return '$bookings bookings · $confirmed confirmed';
  }

  Future<bool> _confirmHighWorkload(
    _CateringReservation reservation,
  ) async {
    final int confirmed =
        _confirmedRequestsOnDate(
      reservation.request.eventDate,
    );

    if (confirmed + 1 < _highWorkloadThreshold) return true;

    final bool? continueAnyway =
        await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'High catering workload',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '$confirmed catering booking'
            '${confirmed == 1 ? '' : 's'} '
            'already confirmed for '
            '${_formatDate(reservation.request.eventDate)}.\n\n'
            'Confirm this request anyway?',
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 10,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                false,
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                true,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
              ),
              child: Text(
                'Confirm Anyway',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return continueAnyway ?? false;
  }

  Future<bool> _confirmDeleteRequest(
    _CateringReservation reservation,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Delete catering request?',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '${reservation.request.customerName} — '
            '${reservation.request.eventType}\n\n'
            'This permanently removes the booking from Firestore.',
            style: GoogleFonts.montserrat(
              color: textMuted,
              fontSize: 10,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: Text(
                'Delete',
                style: GoogleFonts.montserrat(
                  color: red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteRequest(
    _CateringReservation reservation,
  ) async {
    if (!_canDeleteRequest) {
      _showAccessDenied('Deleting catering requests');
      return;
    }

    try {
      final FirebaseFirestore database =
          FirebaseFirestore.instance;

      final WriteBatch batch = database.batch();

      batch.delete(
        database
            .collection('venue_schedule_locks')
            .doc(
              _cateringScheduleId(
                reservation.documentId,
              ),
            ),
      );

      batch.delete(
        database
            .collection('bookings')
            .doc(reservation.documentId),
      );

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Catering request and schedule record deleted.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: '
            '${error.message ?? error.code}',
          ),
          backgroundColor: red,
        ),
      );
    }
  }

  String _cateringScheduleId(
    String bookingId,
  ) {
    return 'catering_$bookingId';
  }

  Future<void> _updateStatus(
    _CateringReservation reservation,
    String status,
  ) async {
    if (!_canUpdateRequest) {
      _showAccessDenied('Updating catering requests');
      return;
    }

    if (status == 'confirmed') {
      final bool proceed =
          await _confirmHighWorkload(
        reservation,
      );

      if (!proceed) return;
    }

    try {
      final FirebaseFirestore database =
          FirebaseFirestore.instance;

      final DocumentReference<Map<String, dynamic>>
          bookingReference = database
              .collection('bookings')
              .doc(reservation.documentId);

      final DocumentReference<Map<String, dynamic>>
          scheduleReference = database
              .collection('venue_schedule_locks')
              .doc(
                _cateringScheduleId(
                  reservation.documentId,
                ),
              );

      final WriteBatch batch = database.batch();

      batch.update(
        bookingReference,
        {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
          'statusUpdatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      if (status == 'declined' ||
          status == 'cancelled') {
        batch.delete(scheduleReference);
      } else if (status == 'confirmed' ||
          status == 'in preparation' ||
          status == 'completed') {
        batch.set(
          scheduleReference,
          {
            'bookingId': reservation.documentId,
            'eventDateKey':
                reservation.request.eventDateKey,
            'eventTime':
                reservation.request.eventTime,
            'status': status,
            'createdAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;

      final int confirmedAfter =
          status == 'confirmed'
              ? _confirmedRequestsOnDate(
                    reservation.request.eventDate,
                  ) +
                  1
              : _confirmedRequestsOnDate(
                  reservation.request.eventDate,
                );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                status == 'confirmed'
                    ? const Color(0xFF17351F)
                    : const Color(0xFF3A1C1C),
            content: Text(
              status == 'confirmed'
                  ? 'Catering request confirmed. '
                      '$confirmedAfter confirmed booking'
                      '${confirmedAfter == 1 ? '' : 's'} '
                      'on this date.'
                  : 'Catering request declined.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Status update failed: '
            '${error.message ?? error.code}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'location',
            isEqualTo: "Customer's Venue",
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildLoadError(snapshot.error);
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        _requests = snapshot.data!.docs
            .map(_CateringReservation.fromDocument)
            .toList();

        final visibleRequests = _filteredRequests;

        return Scaffold(
      backgroundColor: background,
      drawer: const AdminDrawer(
        current: 'Catering Requests',
      ),
      appBar: _buildAppBar(),
      floatingActionButton: _canCreateRequest
          ? FloatingActionButton.small(
              onPressed: _openManualCateringReservation,
              backgroundColor: gold,
              foregroundColor: Colors.black,
              elevation: 3,
              tooltip: 'Add catering request',
              child: const Icon(
                Icons.add_rounded,
                size: 22,
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: gold,
          backgroundColor: cardColor,
          onRefresh: () async {
            await FirebaseFirestore.instance
                .collection('bookings')
                .where(
                  'location',
                  isEqualTo: "Customer's Venue",
                )
                .get();
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      _buildPageIntro(),
                      const SizedBox(height: 14),
                      _buildSummaryStrip(),
                      const SizedBox(height: 14),
                      _buildSearchField(),
                      const SizedBox(height: 18),
                      Text(
                        'Reservations',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildFilterBar(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${visibleRequests.length} request'
                              '${visibleRequests.length == 1 ? '' : 's'}',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'Tap card for details',
                            style:
                                GoogleFonts.montserrat(
                              color: textMuted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              if (visibleRequests.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    84,
                  ),
                  sliver: SliverList.separated(
                    itemCount: visibleRequests.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _buildRequestCard(
                        visibleRequests[index],
                      );
                    },
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

  Future<void> _openManualCateringReservation() async {
    if (!_canCreateRequest) {
      _showAccessDenied('Adding catering requests');
      return;
    }

    final _AdminCateringPackage? selectedPackage =
        await showModalBottomSheet<_AdminCateringPackage>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.76),
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(sheetContext).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    16,
                    10,
                    10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Catering Package',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Select package before entering customer-venue details.',
                              style: GoogleFonts.montserrat(
                                color: textMuted,
                                fontSize: 8.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  color: border,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      22,
                    ),
                    itemCount: _packageOptions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final _AdminCateringPackage package =
                          _packageOptions[index];

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(
                            sheetContext,
                            package,
                          ),
                          borderRadius:
                              BorderRadius.circular(13),
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor2,
                              borderRadius:
                                  BorderRadius.circular(13),
                              border: Border.all(
                                color: index == 1
                                    ? gold.withOpacity(0.6)
                                    : border,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 68,
                                    height: 68,
                                    child: Image.asset(
                                      package.imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: cardColor,
                                          alignment:
                                              Alignment.center,
                                          child: const Icon(
                                            Icons
                                                .restaurant_menu,
                                            color: gold,
                                            size: 28,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              package.name,
                                              style: GoogleFonts
                                                  .playfairDisplay(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (index == 1)
                                            Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 7,
                                                vertical: 4,
                                              ),
                                              decoration:
                                                  BoxDecoration(
                                                color: gold
                                                    .withOpacity(0.14),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(20),
                                              ),
                                              child: Text(
                                                'POPULAR',
                                                style: GoogleFonts
                                                    .montserrat(
                                                  color: gold,
                                                  fontSize: 6.8,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        package.price,
                                        style: GoogleFonts
                                            .playfairDisplay(
                                          color: gold,
                                          fontSize: 16,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        package.capacity,
                                        style:
                                            GoogleFonts.montserrat(
                                          color: textMuted,
                                          fontSize: 8.5,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        package.inclusions
                                            .take(2)
                                            .join(' • '),
                                        maxLines: 2,
                                        overflow:
                                            TextOverflow.ellipsis,
                                        style:
                                            GoogleFonts.montserrat(
                                          color: Colors.white54,
                                          fontSize: 7.5,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: gold,
                                  size: 21,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPackage == null || !mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationScreen(
          packageName: selectedPackage.name,
          packagePrice: selectedPackage.price,
          packageImage: selectedPackage.imagePath,
          packageGuests: selectedPackage.capacity,
          packageInclusions: selectedPackage.inclusions,
          packageSelected: false,
          initialLocation: "Customer's Venue",
          returnToPreviousOnSubmit: true,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: background,
      drawer: const AdminDrawer(
        current: 'Catering Requests',
      ),
      appBar: _buildAppBar(),
      body: const Center(
        child: CircularProgressIndicator(
          color: gold,
        ),
      ),
    );
  }

  Widget _buildLoadError(Object? error) {
    return Scaffold(
      backgroundColor: background,
      drawer: const AdminDrawer(
        current: 'Catering Requests',
      ),
      appBar: _buildAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Firestore error: $error',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: red,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: headerColor,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 36,
            height: 36,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const Icon(
                Icons.room_service_outlined,
                color: gold,
                size: 31,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Catering Requests',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'CUSTOMER VENUE BOOKINGS',
                  style: GoogleFonts.montserrat(
                    color: gold,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATERING MANAGEMENT',
          style: GoogleFonts.montserrat(
            color: gold,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Customer Venue Requests',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Catering bookings delivered to customer locations.',
          style: GoogleFonts.montserrat(
            color: textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip() {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _summaryCard(
            label: 'All Requests',
            value: '${_requests.length}',
            icon: Icons.list_alt_outlined,
            color: blue,
          ),
          const SizedBox(width: 9),
          _summaryCard(
            label: 'Pending',
            value: '${_statusCount('pending')}',
            icon: Icons.pending_actions_outlined,
            color: orange,
          ),
          const SizedBox(width: 9),
          _summaryCard(
            label: 'Confirmed',
            value: '${_statusCount('confirmed')}',
            icon: Icons.check_circle_outline,
            color: green,
          ),
          const SizedBox(width: 9),
          _summaryCard(
            label: 'Preparing',
            value:
                '${_statusCount('in preparation')}',
            icon: Icons.room_service_outlined,
            color: violet,
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 11,
      ),
      decoration: InputDecoration(
        hintText:
            'Search customer, package, event, or address',
        hintStyle: GoogleFonts.montserrat(
          color: Colors.white30,
          fontSize: 10,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: gold,
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
                  color: Colors.white38,
                  size: 18,
                ),
              ),
        filled: true,
        fillColor: cardColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(
            color: gold,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final String filter = _filters[index];
          final bool selected =
              _selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(milliseconds: 180),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? gold
                    : cardColor,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? gold
                      : border,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.montserrat(
                  color: selected
                      ? Colors.black
                      : textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    _CateringReservation reservation,
  ) {
    final request = reservation.request;
    final statusColor =
        _statusColor(reservation.status);
    final needsAction =
        reservation.status == 'pending' && _canUpdateRequest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _openRequestDetails(reservation),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusColor.withOpacity(0.25),
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
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color:
                          statusColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _eventIcon(request.eventType),
                      color: statusColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.eventType,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.customerName,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              GoogleFonts.montserrat(
                            color: textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  _statusBadge(
                    reservation.status,
                    statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _infoPill(
                    Icons.calendar_month_outlined,
                    _shortDate(request.eventDate),
                  ),
                  _infoPill(
                    Icons.schedule_outlined,
                    request.eventTime,
                  ),
                  _infoPill(
                    Icons.people_alt_outlined,
                    request.expectedGuests,
                  ),
                  _infoPill(
                    Icons.event_note_outlined,
                    _dateLoadLabel(
                      request.eventDate,
                    ),
                    color: _dateLoadColor(
                      request.eventDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.only(top: 11),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.packageName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                GoogleFonts.montserrat(
                              color: Colors.white70,
                              fontSize: 8.5,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.packagePrice,
                            style: GoogleFonts
                                .playfairDisplay(
                              color: gold,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Full details',
                      style: GoogleFonts.montserrat(
                        color: Colors.white54,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: gold,
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (needsAction) ...[
                const SizedBox(height: 12),
                const Divider(color: border, height: 1),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _updateStatus(
                              reservation,
                              'confirmed',
                            );
                          },
                          icon: const Icon(
                            Icons.check_rounded,
                            size: 17,
                          ),
                          label: Text(
                            'Accept',
                            style:
                                GoogleFonts.montserrat(
                              fontSize: 9.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: gold,
                            foregroundColor:
                                Colors.black,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _updateStatus(
                              reservation,
                              'declined',
                            );
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 17,
                          ),
                          label: Text(
                            'Decline',
                            style:
                                GoogleFonts.montserrat(
                              fontSize: 9.5,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor: red,
                            side: const BorderSide(
                              color: red,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill(
    IconData icon,
    String text, {
    Color color = gold,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: cardColor2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.montserrat(
              color: textMuted,
              fontSize: 7.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(
    String status,
    Color color,
  ) {
    return Container(
      constraints:
          const BoxConstraints(maxWidth: 110),
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
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 7.3,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: gold,
              size: 47,
            ),
            const SizedBox(height: 12),
            Text(
              'No catering requests',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Change search or filter.',
              style: GoogleFonts.montserrat(
                color: textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRequestDetails(
    _CateringReservation reservation,
  ) {
    final request = reservation.request;
    final statusColor =
        _statusColor(reservation.status);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.76),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.58,
          maxChildSize: 0.97,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: cardColor,
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
                                _eventIcon(
                                  request.eventType,
                                ),
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
                                    request.eventType,
                                    style: GoogleFonts
                                        .playfairDisplay(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _statusBadge(
                                    reservation.status,
                                    statusColor,
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
                          title: 'Package',
                          children: [
                            _detailRow(
                              Icons.inventory_2_outlined,
                              'Package Name',
                              request.packageName,
                            ),
                            _detailRow(
                              Icons.payments_outlined,
                              'Package Price',
                              request.packagePrice,
                              valueColor: gold,
                            ),
                            _detailRow(
                              Icons.groups_outlined,
                              'Package Capacity',
                              request.packageCapacity,
                            ),
                            _detailRow(
                              Icons.list_alt_outlined,
                              'Package Inclusions',
                              request.packageInclusions
                                  .join('\n'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          title: 'Event Details',
                          children: [
                            _detailRow(
                              Icons
                                  .calendar_month_outlined,
                              'Preferred Date',
                              _formatDate(
                                request.eventDate,
                              ),
                            ),
                            _detailRow(
                              Icons.schedule_outlined,
                              'Preferred Time',
                              request.eventTime,
                            ),
                            _detailRow(
                              Icons.event_outlined,
                              'Event Type',
                              request.eventType,
                            ),
                            _detailRow(
                              Icons.people_alt_outlined,
                              'Expected Guests',
                              request.expectedGuests,
                            ),
                            _detailRow(
                              Icons.location_on_outlined,
                              'Event Location',
                              request.location,
                            ),
                            _detailRow(
                              Icons.home_work_outlined,
                              'Complete Venue Address',
                              request.venueAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          title: 'Daily Catering Load',
                          children: [
                            _detailRow(
                              Icons.event_note_outlined,
                              'Total Bookings',
                              '${_bookingsOnDate(request.eventDate)}',
                              valueColor:
                                  _dateLoadColor(
                                request.eventDate,
                              ),
                            ),
                            _detailRow(
                              Icons.check_circle_outline,
                              'Confirmed Bookings',
                              '${_confirmedRequestsOnDate(request.eventDate)}',
                              valueColor:
                                  _dateLoadColor(
                                request.eventDate,
                              ),
                            ),
                            _detailRow(
                              Icons.info_outline_rounded,
                              'Workload',
                              _confirmedRequestsOnDate(
                                        request.eventDate,
                                      ) >=
                                      3
                                  ? 'High workload'
                                  : 'Normal workload',
                              valueColor:
                                  _dateLoadColor(
                                request.eventDate,
                              ),
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
                              request.customerName,
                            ),
                            _detailRow(
                              Icons.phone_outlined,
                              'Phone Number',
                              request.phoneNumber,
                            ),
                            _detailRow(
                              Icons.email_outlined,
                              'Email Address',
                              request.emailAddress,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          title: 'Special Requests',
                          children: [
                            _detailRow(
                              Icons.notes_outlined,
                              'Special Requests',
                              request.specialRequests
                                      .trim()
                                      .isEmpty
                                  ? 'No special requests'
                                  : request.specialRequests,
                            ),
                          ],
                        ),
                        if (reservation.status ==
                                'pending' &&
                            _canUpdateRequest) ...[
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child:
                                      ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(
                                        sheetContext,
                                      );
                                      _updateStatus(
                                        reservation,
                                        'confirmed',
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Accept',
                                      style: GoogleFonts
                                          .montserrat(
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton
                                        .styleFrom(
                                      backgroundColor: gold,
                                      foregroundColor:
                                          Colors.black,
                                      elevation: 0,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: SizedBox(
                                  height: 46,
                                  child:
                                      OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(
                                        sheetContext,
                                      );
                                      _updateStatus(
                                        reservation,
                                        'declined',
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Decline',
                                      style: GoogleFonts
                                          .montserrat(
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                    style: OutlinedButton
                                        .styleFrom(
                                      foregroundColor: red,
                                      side:
                                          const BorderSide(
                                        color: red,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_canDeleteRequest) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final bool confirmed =
                                    await _confirmDeleteRequest(
                                  reservation,
                                );

                                if (!confirmed) return;

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                await _deleteRequest(
                                  reservation,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Delete Catering Request',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: red,
                                side: const BorderSide(
                                  color: red,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _detailSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.montserrat(
              color: gold,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: gold,
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
                  style: GoogleFonts.montserrat(
                    color: textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color:
                        valueColor ?? Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
      case 'confirmed':
        return green;
      case 'pending':
        return orange;
      case 'in preparation':
        return blue;
      case 'declined':
        return red;
      default:
        return textMuted;
    }
  }

  String _displayStatus(String status) {
    switch (status) {
      case 'in preparation':
        return 'In Preparation';
      case 'confirmed':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'declined':
        return 'Declined';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  IconData _eventIcon(String eventType) {
    final value = eventType.toLowerCase();

    if (value.contains('wedding')) {
      return Icons.favorite_border_rounded;
    }

    if (value.contains('birthday')) {
      return Icons.cake_outlined;
    }

    if (value.contains('corporate')) {
      return Icons.business_center_outlined;
    }

    if (value.contains('debut')) {
      return Icons.auto_awesome_outlined;
    }

    if (value.contains('baptism')) {
      return Icons.water_drop_outlined;
    }

    return Icons.celebration_outlined;
  }

  String _formatDate(DateTime date) {
    return '${_monthNames[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  String _shortDate(DateTime date) {
    return '${_monthNames[date.month - 1].substring(0, 3)} '
        '${date.day}, ${date.year}';
  }
}
