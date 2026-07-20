import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/admin_drawer.dart';
import 'reservation_screen.dart';

class EventPlaceScreen extends StatefulWidget {
  const EventPlaceScreen({super.key});

  @override
  State<EventPlaceScreen> createState() =>
      _EventPlaceScreenState();
}

class _EventReservation {
  const _EventReservation({
    this.documentId = '',
    required this.request,
    this.status = 'pending',
  });

  final String documentId;
  final ReservationRequest request;
  final String status;


  factory _EventReservation.fromDocument(
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

    return _EventReservation(
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

  _EventReservation copyWith({
    String? status,
  }) {
    return _EventReservation(
      documentId: documentId,
      request: request,
      status: status ?? this.status,
    );
  }
}


class _AdminPackageOption {
  const _AdminPackageOption({
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

class _EventPlaceScreenState extends State<EventPlaceScreen> {
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

  static const List<String> _weekdays = [
    'SU',
    'MO',
    'TU',
    'WE',
    'TH',
    'FR',
    'SA',
  ];

  static const List<_AdminPackageOption> _packageOptions = [
    _AdminPackageOption(
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
    _AdminPackageOption(
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
    _AdminPackageOption(
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

  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  String _selectedTab = 'Upcoming';

  List<_EventReservation> _reservations = const [];

  String _role = 'none';

  bool get _canCreateReservation =>
      _role == 'owner' || _role == 'manager';

  bool get _canUpdateReservation =>
      _role == 'owner' ||
      _role == 'manager' ||
      _role == 'staff';

  bool get _canDeleteReservation =>
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

      final String resolvedRole = active &&
              <String>{'owner', 'manager', 'staff'}.contains(role)
          ? role
          : 'none';

      setState(() {
        _role = resolvedRole;
      });

      if (resolvedRole != 'none') {
        await _migrateLegacyEventScheduleRecords();
      }
    } on FirebaseException {
      if (!mounted) return;
      setState(() => _role = 'none');
    }
  }

  Future<void> _migrateLegacyEventScheduleRecords() async {
    try {
      final FirebaseFirestore database =
          FirebaseFirestore.instance;

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await database
              .collection('venue_schedule_locks')
              .get();

      final RegExp legacyIdPattern = RegExp(
        r'^\d{4}-\d{2}-\d{2}_(morning|afternoon|evening|full_day)$',
      );

      final Map<String,
              List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          groups = {};

      for (final document in snapshot.docs) {
        if (!legacyIdPattern.hasMatch(document.id)) {
          continue;
        }

        final String dateKey =
            (document.data()['eventDateKey'] ?? '')
                .toString()
                .trim();

        if (dateKey.isEmpty) continue;

        groups.putIfAbsent(dateKey, () => []).add(document);
      }

      for (final entry in groups.entries) {
        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
            legacyDocuments = entry.value;

        final Set<String> bookingIds = legacyDocuments
            .map(
              (document) =>
                  (document.data()['bookingId'] ?? '')
                      .toString()
                      .trim(),
            )
            .where((bookingId) => bookingId.isNotEmpty)
            .toSet();

        if (bookingIds.length != 1) {
          continue;
        }

        final String bookingId = bookingIds.single;

        final DocumentReference<Map<String, dynamic>>
            bookingReference = database
                .collection('bookings')
                .doc(bookingId);

        final DocumentSnapshot<Map<String, dynamic>>
            bookingSnapshot = await bookingReference.get();

        final Map<String, dynamic>? bookingData =
            bookingSnapshot.data();

        if (!bookingSnapshot.exists ||
            bookingData == null ||
            (bookingData['location'] ?? '').toString().trim() !=
                "Shepherd's Event Place") {
          continue;
        }

        final String status =
            (bookingData['status'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        final WriteBatch batch = database.batch();

        for (final document in legacyDocuments) {
          batch.delete(document.reference);
        }

        if (<String>{
          'confirmed',
          'in preparation',
          'completed',
        }.contains(status)) {
          final dynamic oldCreatedAt =
              legacyDocuments.first.data()['createdAt'];

          batch.set(
            database
                .collection('venue_schedule_locks')
                .doc(_eventScheduleId(entry.key)),
            {
              'bookingId': bookingId,
              'eventDateKey': entry.key,
              'eventTime':
                  (bookingData['eventTime'] ?? '')
                      .toString(),
              'status': status,
              'createdAt': oldCreatedAt is Timestamp
                  ? oldCreatedAt
                  : FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }

        await batch.commit();
      }
    } on FirebaseException catch (error) {
      debugPrint(
        'Legacy event schedule migration failed: '
        '${error.message ?? error.code}',
      );
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

  List<_EventReservation> get _monthReservations {
    final reservations = _reservations.where((reservation) {
      final date = reservation.request.eventDate;
      return date.year == _displayedMonth.year &&
          date.month == _displayedMonth.month;
    }).toList();

    reservations.sort(
      (a, b) =>
          a.request.eventDate.compareTo(b.request.eventDate),
    );

    return reservations;
  }

  List<_EventReservation> get _selectedDateReservations {
    return _reservations.where((reservation) {
      return _sameDate(
        reservation.request.eventDate,
        _selectedDate,
      );
    }).toList();
  }

  List<_EventReservation> get _filteredReservations {
    switch (_selectedTab) {
      case 'Past':
        return _monthReservations.where((reservation) {
          return reservation.status == 'completed';
        }).toList();
      case 'All':
        return _monthReservations;
      case 'Upcoming':
      default:
        return _monthReservations.where((reservation) {
          return reservation.status != 'completed' &&
              reservation.status != 'declined';
        }).toList();
    }
  }

  Set<int> get _bookedDays {
    return _monthReservations
        .where((reservation) {
          final String status =
              reservation.status.trim().toLowerCase();

          return status == 'confirmed' ||
              status == 'in preparation' ||
              status == 'completed';
        })
        .map(
          (reservation) =>
              reservation.request.eventDate.day,
        )
        .toSet();
  }

  List<_EventReservation> _reservationsForDate(
    DateTime date,
  ) {
    return _reservations.where((reservation) {
      return _sameDate(
        reservation.request.eventDate,
        date,
      );
    }).toList();
  }

  int _dateStatusCount(
    DateTime date,
    String status,
  ) {
    return _reservationsForDate(date)
        .where(
          (reservation) =>
              reservation.status == status,
        )
        .length;
  }

  int _activeDateCount(DateTime date) {
    return _reservationsForDate(date)
        .where((reservation) {
          final String status =
              reservation.status;

          return status != 'declined' &&
              status != 'cancelled' &&
              status != 'completed';
        })
        .length;
  }

  int get _daysInMonth {
    return DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;
  }

  int get _leadingBlankCount {
    final firstDay = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );

    return firstDay.weekday % 7;
  }

  int get _pendingCount {
    return _monthReservations.where((reservation) {
      return reservation.status == 'pending';
    }).length;
  }

  int get _needsRescheduleCount {
    return _monthReservations.where((reservation) {
      return reservation.status == 'needs_reschedule';
    }).length;
  }

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void _changeMonth(int offset) {
    final newMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + offset,
    );

    setState(() {
      _displayedMonth = newMonth;
      _selectedDate = DateTime(
        newMonth.year,
        newMonth.month,
        1,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();

    setState(() {
      _displayedMonth = DateTime(now.year, now.month);
      _selectedDate = DateTime(
        now.year,
        now.month,
        now.day,
      );
    });
  }

  void _selectDay(int day) {
    setState(() {
      _selectedDate = DateTime(
        _displayedMonth.year,
        _displayedMonth.month,
        day,
      );
    });
  }

  Future<bool> _confirmDeleteReservation(
    _EventReservation reservation,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Delete event reservation?',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '${reservation.request.customerName} — '
            '${reservation.request.eventType}\n\n'
            'This permanently removes the booking and its venue schedule lock.',
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

  Future<void> _deleteReservation(
    _EventReservation reservation,
  ) async {
    if (!_canDeleteReservation) {
      _showAccessDenied('Deleting event reservations');
      return;
    }

    try {
      final FirebaseFirestore database =
          FirebaseFirestore.instance;

      final QuerySnapshot<Map<String, dynamic>> locks =
          await database
              .collection('venue_schedule_locks')
              .where(
                'bookingId',
                isEqualTo: reservation.documentId,
              )
              .get();

      final WriteBatch batch = database.batch();

      for (final lock in locks.docs) {
        batch.delete(lock.reference);
      }

      batch.delete(
        database
            .collection('bookings')
            .doc(reservation.documentId),
      );

      await batch.commit();

      if (locks.docs.isNotEmpty) {
        await _restoreSameDateRequests(
          reservation.request.eventDateKey,
          excludeDocumentId:
              reservation.documentId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF17351F),
          content: Text(
            'Event reservation deleted. Date unlocked.',
            style: TextStyle(
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
            'Delete failed: '
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

  Future<int> _markSameDateForReschedule(
    String dateKey, {
    required String confirmedDocumentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        sameDateSnapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where(
              'eventDateKey',
              isEqualTo: dateKey,
            )
            .get();

    final WriteBatch batch =
        FirebaseFirestore.instance.batch();

    int updatedCount = 0;

    for (final document in sameDateSnapshot.docs) {
      if (document.id == confirmedDocumentId) {
        continue;
      }

      final Map<String, dynamic> data =
          document.data();

      final String location =
          (data['location'] ?? '')
              .toString()
              .trim();

      final String status =
          (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (location != "Shepherd's Event Place" ||
          status != 'pending') {
        continue;
      }

      batch.update(
        document.reference,
        {
          'status': 'needs_reschedule',
          'updatedAt':
              FieldValue.serverTimestamp(),
          'statusUpdatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      updatedCount++;
    }

    if (updatedCount > 0) {
      await batch.commit();
    }

    return updatedCount;
  }

  Future<int> _restoreSameDateRequests(
    String dateKey, {
    required String excludeDocumentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>>
        sameDateSnapshot =
        await FirebaseFirestore.instance
            .collection('bookings')
            .where(
              'eventDateKey',
              isEqualTo: dateKey,
            )
            .get();

    final WriteBatch batch =
        FirebaseFirestore.instance.batch();

    int restoredCount = 0;

    for (final document in sameDateSnapshot.docs) {
      if (document.id == excludeDocumentId) {
        continue;
      }

      final Map<String, dynamic> data =
          document.data();

      final String location =
          (data['location'] ?? '')
              .toString()
              .trim();

      final String status =
          (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      if (location != "Shepherd's Event Place" ||
          status != 'needs_reschedule') {
        continue;
      }

      batch.update(
        document.reference,
        {
          'status': 'pending',
          'updatedAt':
              FieldValue.serverTimestamp(),
          'statusUpdatedAt':
              FieldValue.serverTimestamp(),
        },
      );

      restoredCount++;
    }

    if (restoredCount > 0) {
      await batch.commit();
    }

    return restoredCount;
  }

  String _eventScheduleId(String dateKey) {
    return 'event_$dateKey';
  }

  List<String> _legacyDateLockIds(String dateKey) {
    return [
      '${dateKey}_morning',
      '${dateKey}_afternoon',
      '${dateKey}_evening',
      '${dateKey}_full_day',
    ];
  }

  Future<void> _updateStatus(
    _EventReservation reservation,
    String status,
  ) async {
    if (!_canUpdateReservation) {
      _showAccessDenied('Updating reservations');
      return;
    }

    final FirebaseFirestore database =
        FirebaseFirestore.instance;

    final DocumentReference<Map<String, dynamic>>
        bookingReference = database
            .collection('bookings')
            .doc(reservation.documentId);

    try {
      int affectedRequests = 0;

      if (status == 'confirmed') {
        final String dateKey =
            reservation.request.eventDateKey;

        final DocumentReference<Map<String, dynamic>>
            scheduleReference = database
                .collection('venue_schedule_locks')
                .doc(_eventScheduleId(dateKey));

        final List<DocumentReference<Map<String, dynamic>>>
            legacyReferences = _legacyDateLockIds(dateKey)
                .map(
                  (lockId) => database
                      .collection('venue_schedule_locks')
                      .doc(lockId),
                )
                .toList();

        await database.runTransaction(
          (transaction) async {
            final List<DocumentReference<Map<String, dynamic>>>
                references = [
              scheduleReference,
              ...legacyReferences,
            ];

            for (final reference in references) {
              final DocumentSnapshot<Map<String, dynamic>>
                  lockSnapshot =
                  await transaction.get(reference);

              if (!lockSnapshot.exists) continue;

              final Map<String, dynamic> lockData =
                  lockSnapshot.data() ??
                      <String, dynamic>{};

              final String lockStatus =
                  (lockData['status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

              final String lockBookingId =
                  (lockData['bookingId'] ?? '')
                      .toString();

              final bool belongsToAnotherBooking =
                  lockBookingId.isNotEmpty &&
                  lockBookingId !=
                      reservation.documentId;

              final bool blocksDate =
                  lockStatus == 'confirmed' ||
                  lockStatus == 'in preparation' ||
                  lockStatus == 'completed';

              if (belongsToAnotherBooking &&
                  blocksDate) {
                throw StateError(
                  'Another reservation is already '
                  'confirmed for this date.',
                );
              }
            }

            transaction.update(
              bookingReference,
              {
                'status': 'confirmed',
                'updatedAt':
                    FieldValue.serverTimestamp(),
                'statusUpdatedAt':
                    FieldValue.serverTimestamp(),
              },
            );

            transaction.set(
              scheduleReference,
              {
                'bookingId':
                    reservation.documentId,
                'eventDateKey': dateKey,
                'eventTime':
                    reservation.request.eventTime,
                'status': 'confirmed',
                'createdAt':
                    FieldValue.serverTimestamp(),
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );

            for (final reference in legacyReferences) {
              transaction.delete(reference);
            }
          },
        );

        affectedRequests =
            await _markSameDateForReschedule(
          dateKey,
          confirmedDocumentId:
              reservation.documentId,
        );
      } else if (status == 'declined' ||
          status == 'cancelled') {
        final QuerySnapshot<Map<String, dynamic>>
            locks = await database
                .collection('venue_schedule_locks')
                .where(
                  'bookingId',
                  isEqualTo: reservation.documentId,
                )
                .get();

        final WriteBatch batch = database.batch();

        batch.update(
          bookingReference,
          {
            'status': status,
            'updatedAt':
                FieldValue.serverTimestamp(),
            'statusUpdatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        for (final lock in locks.docs) {
          batch.delete(lock.reference);
        }

        await batch.commit();

        if (locks.docs.isNotEmpty) {
          affectedRequests =
              await _restoreSameDateRequests(
            reservation.request.eventDateKey,
            excludeDocumentId:
                reservation.documentId,
          );
        }
      } else {
        final QuerySnapshot<Map<String, dynamic>>
            locks = await database
                .collection('venue_schedule_locks')
                .where(
                  'bookingId',
                  isEqualTo: reservation.documentId,
                )
                .get();

        final WriteBatch batch = database.batch();

        batch.update(
          bookingReference,
          {
            'status': status,
            'updatedAt':
                FieldValue.serverTimestamp(),
            'statusUpdatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        for (final lock in locks.docs) {
          batch.update(
            lock.reference,
            {
              'status': status,
              'updatedAt':
                  FieldValue.serverTimestamp(),
            },
          );
        }

        await batch.commit();
      }

      if (!mounted) return;

      final String message;

      if (status == 'confirmed') {
        message = affectedRequests == 0
            ? 'Reservation confirmed. Date locked.'
            : 'Reservation confirmed. Date locked. '
                '$affectedRequests other request'
                '${affectedRequests == 1 ? '' : 's'} '
                'marked for rescheduling.';
      } else if (status == 'declined' ||
          status == 'cancelled') {
        message = affectedRequests == 0
            ? 'Reservation ${status == 'declined' ? 'declined' : 'cancelled'}.'
            : 'Reservation ${status == 'declined' ? 'declined' : 'cancelled'}. '
                '$affectedRequests request'
                '${affectedRequests == 1 ? '' : 's'} '
                'returned to pending.';
      } else {
        message = 'Reservation status updated.';
      }

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
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    } on StateError catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: red,
            content: Text(
              error.message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: red,
            content: Text(
              'Status update failed: '
              '${error.message ?? error.code}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
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
            isEqualTo: "Shepherd's Event Place",
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildLoadError(snapshot.error);
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        _reservations = snapshot.data!.docs
            .map(_EventReservation.fromDocument)
            .toList();

        final visibleReservations =
        _filteredReservations;

        return Scaffold(
      backgroundColor: background,
      drawer: const AdminDrawer(current: 'Event Place'),
      appBar: _buildAppBar(),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      floatingActionButton: _canCreateReservation
          ? FloatingActionButton.small(
              onPressed: _openManualReservation,
              backgroundColor: gold,
              foregroundColor: Colors.black,
              elevation: 3,
              tooltip: 'Add reservation',
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
                  isEqualTo: "Shepherd's Event Place",
                )
                .get();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              84,
            ),
            children: [
              _buildPageIntro(),
              const SizedBox(height: 14),
              _buildSummaryStrip(),
              const SizedBox(height: 14),
              _buildCalendarCard(),
              const SizedBox(height: 14),
              _buildSelectedDateCard(),
              const SizedBox(height: 18),
              _buildReservationSection(
                visibleReservations,
              ),
              const SizedBox(height: 18),
              _buildAvailabilityCard(),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Future<void> _openManualReservation() async {
    if (!_canCreateReservation) {
      _showAccessDenied('Adding reservations');
      return;
    }

    final _AdminPackageOption? selectedPackage =
        await showModalBottomSheet<_AdminPackageOption>(
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
                              'Choose Package',
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Select package before entering reservation details.',
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
                      final _AdminPackageOption package =
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
          initialLocation: "Shepherd's Event Place",
          returnToPreviousOnSubmit: true,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: background,
      drawer: const AdminDrawer(
        current: 'Event Place',
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
        current: 'Event Place',
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
                Icons.apartment_outlined,
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
                  'Event Place',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'RESERVATION CALENDAR',
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
      actions: [
        TextButton(
          onPressed: _goToToday,
          child: Text(
            'Today',
            style: GoogleFonts.montserrat(
              color: gold,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _buildPageIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VENUE MANAGEMENT',
          style: GoogleFonts.montserrat(
            color: gold,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Event Place Reservations',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Reservations for Shepherd’s Event Place only.',
          style: GoogleFonts.montserrat(
            color: textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip() {
    final openDays =
        _daysInMonth - _bookedDays.length;

    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _summaryCard(
            label: 'Booked Dates',
            value: '${_bookedDays.length}',
            icon: Icons.event_busy_outlined,
            color: orange,
          ),
          const SizedBox(width: 9),
          _summaryCard(
            label: 'Open Dates',
            value: '$openDays',
            icon: Icons.event_available_outlined,
            color: green,
          ),
          const SizedBox(width: 9),
          _summaryCard(
            label: 'Pending',
            value: '$_pendingCount',
            icon: Icons.pending_actions_outlined,
            color: violet,
          ),
          const SizedBox(width: 9),
          _summaryCard(
            label: 'Reschedule',
            value: '$_needsRescheduleCount',
            icon: Icons.event_repeat_outlined,
            color: blue,
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

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gold.withOpacity(0.38),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_monthNames[_displayedMonth.month - 1]} '
                      '${_displayedMonth.year}',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_monthReservations.length} reservation'
                      '${_monthReservations.length == 1 ? '' : 's'}',
                      style: GoogleFonts.montserrat(
                        color: textMuted,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: 7,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 28,
            ),
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  _weekdays[index],
                  style: GoogleFonts.montserrat(
                    color: gold,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          GridView.builder(
            itemCount:
                _leadingBlankCount + _daysInMonth,
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 42,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemBuilder: (context, index) {
              if (index < _leadingBlankCount) {
                return const SizedBox();
              }

              final day =
                  index - _leadingBlankCount + 1;

              return _buildCalendarDay(day);
            },
          ),
          const SizedBox(height: 8),
          const Divider(color: border),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _calendarLegend(
                color: gold,
                label: 'Selected',
              ),
              const SizedBox(width: 14),
              _calendarLegend(
                color: orange,
                label: 'Booked',
              ),
              const SizedBox(width: 14),
              _calendarLegend(
                color: green,
                label: 'Available',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(int day) {
    final DateTime date = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      day,
    );

    final bool selected =
        _sameDate(date, _selectedDate);
    final bool booked = _bookedDays.contains(day);
    final bool today =
        _sameDate(date, DateTime.now());
    final int requestCount =
        _activeDateCount(date);
    final int confirmedCount =
        _dateStatusCount(date, 'confirmed');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _selectDay(day);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected
              ? gold
              : booked
                  ? orange.withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? gold
                : today
                    ? blue
                    : Colors.transparent,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.montserrat(
                color: selected
                    ? Colors.black
                    : Colors.white,
                fontSize: 9.5,
                fontWeight:
                    selected || booked
                        ? FontWeight.w700
                        : FontWeight.w500,
              ),
            ),
            if (requestCount > 0)
              Positioned(
                right: 3,
                top: 3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 13,
                    minHeight: 13,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.black
                        : confirmedCount > 0
                            ? red
                            : blue,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$requestCount',
                    style: GoogleFonts.montserrat(
                      color: selected
                          ? gold
                          : Colors.white,
                      fontSize: 6.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (booked)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.black
                        : orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _calendarLegend({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: textMuted,
            fontSize: 7.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateCard() {
    final List<_EventReservation> reservations =
        _selectedDateReservations;

    final int pending = reservations
        .where(
          (reservation) =>
              reservation.status == 'pending',
        )
        .length;

    final int confirmed = reservations
        .where(
          (reservation) =>
              reservation.status == 'confirmed' ||
              reservation.status ==
                  'in preparation',
        )
        .length;

    final int needsReschedule = reservations
        .where(
          (reservation) =>
              reservation.status ==
                  'needs_reschedule',
        )
        .length;

    final int activeRequests = reservations
        .where((reservation) {
          return reservation.status != 'declined' &&
              reservation.status != 'cancelled' &&
              reservation.status != 'completed';
        })
        .length;

    final bool locked = confirmed > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: locked
              ? red.withOpacity(0.5)
              : border,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 49,
            height: 56,
            decoration: BoxDecoration(
              color: (locked ? red : gold)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  '${_selectedDate.day}',
                  style: GoogleFonts.playfairDisplay(
                    color: locked ? red : gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _monthNames[_selectedDate.month - 1]
                      .substring(0, 3)
                      .toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: textMuted,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  locked
                      ? 'Date Locked'
                      : activeRequests == 0
                          ? 'Date Available'
                          : '$activeRequests Request'
                              '${activeRequests == 1 ? '' : 's'}',
                  style: GoogleFonts.montserrat(
                    color: locked
                        ? red
                        : activeRequests == 0
                            ? green
                            : Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _selectedDateCountChip(
                      label: 'Pending $pending',
                      color: orange,
                    ),
                    _selectedDateCountChip(
                      label: 'Confirmed $confirmed',
                      color: green,
                    ),
                    if (needsReschedule > 0)
                      _selectedDateCountChip(
                        label:
                            'Reschedule $needsReschedule',
                        color: blue,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  locked
                      ? 'No additional event-place booking can be confirmed on this date.'
                      : activeRequests == 0
                          ? 'No active event-place request on this date.'
                          : 'Multiple pending requests allowed until one is confirmed.',
                  style: GoogleFonts.montserrat(
                    color: textMuted,
                    fontSize: 8.8,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            locked
                ? Icons.lock_outline_rounded
                : Icons.event_available_outlined,
            color: locked ? red : green,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _selectedDateCountChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.35),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          color: color,
          fontSize: 7.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildReservationSection(
    List<_EventReservation> reservations,
  ) {
    const tabs = [
      'Upcoming',
      'All',
      'Past',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Reservations',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${reservations.length} shown',
              style: GoogleFonts.montserrat(
                color: textMuted,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tabs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final tab = tabs[index];
              final selected =
                  _selectedTab == tab;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = tab;
                  });
                },
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected ? gold : cardColor,
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          selected ? gold : border,
                    ),
                  ),
                  child: Text(
                    tab,
                    style: GoogleFonts.montserrat(
                      color: selected
                          ? Colors.black
                          : textMuted,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (reservations.isEmpty)
          _buildEmptyReservations()
        else
          ...reservations.map(
            _buildReservationCard,
          ),
      ],
    );
  }

  Widget _buildReservationCard(
    _EventReservation reservation,
  ) {
    final request = reservation.request;
    final statusColor =
        _statusColor(reservation.status);
    final needsAction =
        reservation.status == 'pending' &&
        _canUpdateReservation;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _openReservationDetails(reservation),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: statusColor.withOpacity(0.24),
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
                    width: 46,
                    height: 54,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.11),
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          '${request.eventDate.day}',
                          style:
                              GoogleFonts.playfairDisplay(
                            color: gold,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          _monthNames[
                                  request.eventDate.month - 1]
                              .substring(0, 3)
                              .toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: textMuted,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
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
                    Icons.schedule_outlined,
                    request.eventTime,
                  ),
                  _infoPill(
                    Icons.people_alt_outlined,
                    request.expectedGuests,
                  ),
                  _infoPill(
                    Icons.inventory_2_outlined,
                    request.packageName,
                  ),
                ],
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  Text(
                    request.packagePrice,
                    style: GoogleFonts.playfairDisplay(
                      color: gold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
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
      ),
    );
  }

  Widget _infoPill(
    IconData icon,
    String text,
  ) {
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
            color: gold,
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
          const BoxConstraints(maxWidth: 105),
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

  Widget _buildEmptyReservations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 26,
        horizontal: 18,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: green,
            size: 39,
          ),
          const SizedBox(height: 10),
          Text(
            'No reservations',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Change month or select another filter.',
            style: GoogleFonts.montserrat(
              color: textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  void _openReservationDetails(
    _EventReservation reservation,
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
                            _canUpdateReservation) ...[
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
                        if (_canDeleteReservation) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final bool confirmed =
                                    await _confirmDeleteReservation(
                                  reservation,
                                );

                                if (!confirmed) return;

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                await _deleteReservation(
                                  reservation,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: Text(
                                'Delete Event Reservation',
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

  Widget _buildAvailabilityCard() {
    final booked = _bookedDays.length;
    final open = _daysInMonth - booked;
    final utilization =
        booked / _daysInMonth;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: green.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: green.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: green,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Availability',
                      style:
                          GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_monthNames[_displayedMonth.month - 1]} '
                      '${_displayedMonth.year}',
                      style: GoogleFonts.montserrat(
                        color: textMuted,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(utilization * 100).round()}%',
                style: GoogleFonts.playfairDisplay(
                  color: orange,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: utilization,
              minHeight: 8,
              backgroundColor: cardColor2,
              valueColor:
                  const AlwaysStoppedAnimation(orange),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$booked booked date'
            '${booked == 1 ? '' : 's'} · '
            '$open open date'
            '${open == 1 ? '' : 's'}',
            style: GoogleFonts.montserrat(
              color: textMuted,
              fontSize: 9,
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
      case 'needs_reschedule':
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
      case 'needs_reschedule':
        return 'Needs Reschedule';
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
}
