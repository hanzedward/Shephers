import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'reservation_screen.dart';


class _AvailabilityPackage {
  const _AvailabilityPackage({
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

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  static const Color gold = Color(0xFFD5A021);
  static const Color background = Color(0xFF080A0B);
  static const Color cardColor = Color(0xFF111416);
  static const Color cardColor2 = Color(0xFF171B1D);
  static const Color border = Color(0xFF292D2F);
  static const Color textMuted = Color(0xFFA8A8A2);
  static const Color availableGreen = Color(0xFF58B844);
  static const Color unavailableRed = Color(0xFFE25A4F);

  static const List<String> timeSlots = [
    'Morning',
    'Afternoon',
    'Evening',
    'Full Day',
  ];

  static const List<_AvailabilityPackage> packageOptions = [
    _AvailabilityPackage(
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
    _AvailabilityPackage(
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
    _AvailabilityPackage(
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

  late DateTime selectedDate;
  String? selectedTime;
  bool checking = false;
  String? errorMessage;
  int _availabilityRequestId = 0;

  Map<String, bool> slotAvailability = {
    'Morning': false,
    'Afternoon': false,
    'Evening': false,
    'Full Day': false,
  };

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();
    selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAvailability(selectedDate);
    });
  }

  Future<void> _loadAvailability(DateTime date) async {
    final int requestId = ++_availabilityRequestId;

    setState(() {
      checking = true;
      selectedTime = null;
      errorMessage = null;
    });

    try {
      final FirebaseFirestore database =
          FirebaseFirestore.instance;
      final String dateKey = _dateKey(date);

      final List<String> lockIds = [
        '${dateKey}_morning',
        '${dateKey}_afternoon',
        '${dateKey}_evening',
        '${dateKey}_full_day',
      ];

      final List<
          DocumentSnapshot<Map<String, dynamic>>> locks =
          await Future.wait(
        lockIds.map(
          (String lockId) => database
              .collection('venue_schedule_locks')
              .doc(lockId)
              .get(),
        ),
      );

      final Set<String> bookedSlots = <String>{};

      if (locks[0].exists) bookedSlots.add('Morning');
      if (locks[1].exists) bookedSlots.add('Afternoon');
      if (locks[2].exists) bookedSlots.add('Evening');
      if (locks[3].exists) bookedSlots.add('Full Day');

      final bool fullDayBooked =
          bookedSlots.contains('Full Day');

      final Map<String, bool> availability = {
        'Morning':
            !fullDayBooked &&
                !bookedSlots.contains('Morning'),
        'Afternoon':
            !fullDayBooked &&
                !bookedSlots.contains('Afternoon'),
        'Evening':
            !fullDayBooked &&
                !bookedSlots.contains('Evening'),
        'Full Day': bookedSlots.isEmpty,
      };

      if (!mounted ||
          requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        slotAvailability = availability;
        checking = false;
      });
    } on FirebaseException catch (error) {
      if (!mounted ||
          requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        checking = false;
        errorMessage =
            error.message ?? 'Could not load availability.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Availability check failed: '
            '${error.message ?? error.code}',
          ),
          backgroundColor: unavailableRed,
        ),
      );
    } catch (error) {
      if (!mounted ||
          requestId != _availabilityRequestId) {
        return;
      }

      setState(() {
        checking = false;
        errorMessage = 'Could not load availability.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Availability check failed: $error',
          ),
          backgroundColor: unavailableRed,
        ),
      );
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });

    _loadAvailability(date);
  }

  void _selectTime(String time) {
    if (checking || slotAvailability[time] != true) return;

    setState(() {
      selectedTime = time;
    });
  }

  Future<void> _continueToReservation() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an available time.'),
          backgroundColor: Color(0xFF242627),
        ),
      );
      return;
    }

    final _AvailabilityPackage? selectedPackage =
        await _choosePackage();

    if (selectedPackage == null || !mounted) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationScreen(
          packageName: selectedPackage.name,
          packagePrice: selectedPackage.price,
          packageImage: selectedPackage.imagePath,
          packageGuests: selectedPackage.capacity,
          packageInclusions: selectedPackage.inclusions,
          packageSelected: true,
          initialDate: selectedDate,
          initialTime: selectedTime,
          initialLocation: "Shepherd's Event Place",
        ),
      ),
    );

    if (mounted) {
      _loadAvailability(selectedDate);
    }
  }

  Future<_AvailabilityPackage?> _choosePackage() {
    return showModalBottomSheet<_AvailabilityPackage>(
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
                              '${_formatDate(selectedDate)} · $selectedTime',
                              style: GoogleFonts.montserrat(
                                color: gold,
                                fontSize: 8.8,
                                fontWeight: FontWeight.w700,
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
                    itemCount: packageOptions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final _AvailabilityPackage package =
                          packageOptions[index];

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
                                            Icons.restaurant_menu,
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
  }

  bool get hasAvailableTime {
    return slotAvailability.values.any((bool available) => available);
  }

  String _dateKey(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.maybePop(context);
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Venue Availability',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'RESERVATION SCHEDULING',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Text(
            'VENUE SCHEDULING',
            style: GoogleFonts.montserrat(
              color: gold,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.35,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Check Event Place Availability',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Choose a date, review live time slots, then continue.',
            style: GoogleFonts.montserrat(
              color: textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),

          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: gold.withOpacity(0.38),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: gold,
                  onPrimary: Colors.black,
                  surface: cardColor,
                  onSurface: Colors.white,
                ),
                datePickerTheme: const DatePickerThemeData(
                  backgroundColor: cardColor,
                  headerBackgroundColor: cardColor,
                  headerForegroundColor: Colors.white,
                  weekdayStyle: TextStyle(
                    color: gold,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  dayStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  yearStyle: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: firstDate,
                lastDate: DateTime(now.year + 2, 12, 31),
                onDateChanged: _selectDate,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: cardColor2,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  checking
                      ? Icons.hourglass_top_rounded
                      : hasAvailableTime
                          ? Icons.check_circle
                          : Icons.cancel,
                  color: checking
                      ? gold
                      : hasAvailableTime
                          ? availableGreen
                          : unavailableRed,
                  size: 24,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        checking
                            ? 'Loading available times...'
                            : errorMessage ??
                                (hasAvailableTime
                                    ? 'Available times shown below.'
                                    : 'No available times for this date.'),
                        style: GoogleFonts.montserrat(
                          color: textMuted,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                if (checking)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: gold,
                    ),
                  )
                else if (errorMessage != null)
                  IconButton(
                    onPressed: () =>
                        _loadAvailability(selectedDate),
                    tooltip: 'Retry',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: gold,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Available Time Slots',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendDot(
                color: availableGreen,
                label: 'Available',
              ),
              SizedBox(width: 14),
              _LegendDot(
                color: unavailableRed,
                label: 'Booked',
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final String time in timeSlots) ...[
            _TimeSlotCard(
              label: time,
              available: slotAvailability[time] == true,
              selected: selectedTime == time,
              loading: checking,
              onTap: () => _selectTime(time),
            ),
            const SizedBox(height: 9),
          ],

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardColor2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: gold,
                  size: 18,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Pending and confirmed event-place bookings '
                    'reserve their selected time slots.',
                    style: GoogleFonts.montserrat(
                      color: textMuted,
                      fontSize: 8.8,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed:
                  selectedTime == null || checking
                      ? null
                      : _continueToReservation,
              icon: const Icon(Icons.arrow_forward, size: 19),
              label: const Text('Choose Package & Continue'),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                disabledBackgroundColor:
                    const Color(0xFF5F4A18),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({
    required this.label,
    required this.available,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool available;
  final bool selected;
  final bool loading;
  final VoidCallback onTap;

  static const Color gold = Color(0xFFD5A021);
  static const Color availableGreen = Color(0xFF58B844);
  static const Color unavailableRed = Color(0xFFE25A4F);
  static const Color cardColor2 = Color(0xFF171B1D);
  static const Color border = Color(0xFF292D2F);

  @override
  Widget build(BuildContext context) {
    final bool enabled = available && !loading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF3A2B06)
                : cardColor2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? gold
                  : loading
                      ? border
                      : available
                          ? availableGreen.withOpacity(0.55)
                          : unavailableRed.withOpacity(0.45),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: selected
                      ? gold
                      : available
                          ? const Color(0xFF123B24)
                          : const Color(0xFF481C1C),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.access_time,
                  color: selected
                      ? Colors.black
                      : available
                          ? availableGreen
                          : unavailableRed,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: loading
                        ? Colors.white38
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: gold,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      available ? 'Available' : 'Booked',
                      style: TextStyle(
                        color: available
                            ? availableGreen
                            : unavailableRed,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : available
                              ? Icons.circle_outlined
                              : Icons.block,
                      color: selected
                          ? gold
                          : available
                              ? availableGreen
                              : unavailableRed,
                      size: 20,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
