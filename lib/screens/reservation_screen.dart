import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum ReservationEntry {
  direct,
  packages,
}

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({
    super.key,
    this.packageName,
    this.packagePrice,
    this.packageImage,
    this.packageGuests,
    this.packageInclusions,
    this.packageSelected = false,
    this.onSubmit,
    this.initialDate,
    this.initialTime,
    this.initialLocation,
    this.entry = ReservationEntry.direct,
    this.returnToPreviousOnSubmit = false,
  });

  final String? packageName;
  final String? packagePrice;
  final String? packageImage;
  final String? packageGuests;
  final List<String>? packageInclusions;
  final bool packageSelected;
  final ValueChanged<ReservationRequest>? onSubmit;
  final DateTime? initialDate;
  final String? initialTime;
  final String? initialLocation;
  final ReservationEntry entry;
  final bool returnToPreviousOnSubmit;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationPackageOption {
  const _ReservationPackageOption({
    required this.name,
    required this.price,
    required this.image,
    required this.capacity,
    required this.inclusions,
  });

  final String name;
  final String price;
  final String image;
  final String capacity;
  final List<String> inclusions;
}

class _ReservationScreenState extends State<ReservationScreen> {
  static const List<_ReservationPackageOption> _packageOptions = [
    _ReservationPackageOption(
      name: 'Classic Package',
      price: '₱12,000',
      image: 'assets/images/light_catering.jpg',
      capacity: 'Up to 100 pax',
      inclusions: [
        '2-course set menu',
        'Rice and one beverage option',
        'Basic buffet setup',
        'Service staff assistance',
        'Basic cleanup after service',
      ],
    ),
    _ReservationPackageOption(
      name: 'Premium Package',
      price: '₱24,000',
      image: 'assets/images/full_catering.jpg',
      capacity: 'Up to 200 pax',
      inclusions: [
        'Buffet spread with 3 viands',
        'Steamed rice, drinks, and dessert',
        'Professional service staff',
        'Buffet setup and cleanup',
        'Tables and basic linens',
        'Serving utensils and food warmers',
      ],
    ),
    _ReservationPackageOption(
      name: 'Grand Package',
      price: '₱42,000',
      image: 'assets/images/premium_catering.jpg',
      capacity: 'Up to 300 pax',
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

  static const Color gold = Color(0xFFD89B08);
  static const Color background = Color(0xFF090A0A);
  static const Color cardColor = Color(0xFFF8F6F1);
  static const Color fieldColor = Color(0xFFF0ECE3);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ScrollController scrollController = ScrollController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  int currentStep = 0;
  bool acceptedTerms = false;
  bool isSubmitting = false;

  DateTime? selectedDate;
  String selectedTime = 'Afternoon';
  String selectedEventType = 'Birthday';
  String selectedLocation = "Shepherd's Event Place";
  String selectedGuests = '50 - 100';

  late String currentPackageName;
  late String currentPackagePrice;
  late String currentPackageImage;
  late String currentPackageGuests;
  late List<String> currentPackageInclusions;

  ReservationRequest? reviewRequest;

  bool get isCustomerVenue => selectedLocation == "Customer's Venue";

  @override
  void initState() {
    super.initState();

    currentPackageName =
        widget.packageName ?? _packageOptions[1].name;
    currentPackagePrice =
        widget.packagePrice ?? _packageOptions[1].price;
    currentPackageImage =
        widget.packageImage ?? _packageOptions[1].image;
    currentPackageGuests =
        widget.packageGuests ?? _packageOptions[1].capacity;
    currentPackageInclusions = List<String>.from(
      widget.packageInclusions ??
          _packageOptions[1].inclusions,
    );

    selectedGuests = _defaultGuestRange(currentPackageGuests);

    final DateTime now = DateTime.now();
    final DateTime firstAvailable =
        DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );

    final DateTime? incomingDate = widget.initialDate == null
        ? null
        : DateTime(
            widget.initialDate!.year,
            widget.initialDate!.month,
            widget.initialDate!.day,
          );

    selectedDate = incomingDate != null &&
            !incomingDate.isBefore(firstAvailable)
        ? incomingDate
        : null;

    selectedTime = widget.initialTime ?? 'Afternoon';
    selectedLocation =
        widget.initialLocation ?? "Shepherd's Event Place";
  }

  @override
  void dispose() {
    scrollController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBackBar(
              label: widget.returnToPreviousOnSubmit
                  ? widget.initialLocation ==
                          "Shepherd's Event Place"
                      ? 'Back to Event Place'
                      : 'Back to Catering Requests'
                  : widget.entry == ReservationEntry.packages
                      ? 'Back to Packages'
                      : 'Back to Home',
              onBack: () {
                if (currentStep == 1) {
                  setState(() {
                    currentStep = 0;
                  });
                  _scrollToTop();
                  return;
                }

                if (widget.returnToPreviousOnSubmit ||
                    widget.entry == ReservationEntry.packages) {
                  Navigator.of(context).pop();
                  return;
                }

                Navigator.of(context).popUntil(
                  (route) => route.isFirst,
                );
              },
            ),
            _ReservationProgressHeader(currentStep: currentStep),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF1E1F20),
            ),
            Expanded(
              child: currentStep == 0
                  ? _buildDetailsStep()
                  : _buildReviewStep(),
            ),
            currentStep == 0
                ? _buildContinueButton()
                : _buildReviewButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        key: const ValueKey<String>('details'),
        controller: scrollController,
        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        children: [
          Text(
            'Complete Your Reservation',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Choose your package, then fill in event and contact details.',
            style: TextStyle(
              color: Color(0xFFC7C7C7),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _buildPackageCard(),
          const SizedBox(height: 12),
          _buildDateSection(),
          const SizedBox(height: 12),
          _buildEventSection(),
          const SizedBox(height: 12),
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final ReservationRequest request = reviewRequest!;

    return ListView(
      key: const ValueKey<String>('review'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      children: [
        Text(
          'Review Your Reservation',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 22,
            height: 1.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Check every detail before submitting.',
          style: TextStyle(
            color: Color(0xFFC7C7C7),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        _buildPackageCard(),
        const SizedBox(height: 12),
        _reviewSection(
          title: 'Event Details',
          icon: Icons.event_note_outlined,
          children: [
            _reviewRow('Date', _formatDate(request.eventDate)),
            _reviewRow('Time', request.eventTime),
            _reviewRow('Event Type', request.eventType),
            _reviewRow('Expected Guests', request.expectedGuests),
            _reviewRow('Location', request.location),
            if (request.venueAddress.isNotEmpty)
              _reviewRow('Venue Address', request.venueAddress),
          ],
        ),
        const SizedBox(height: 12),
        _reviewSection(
          title: 'Contact Information',
          icon: Icons.person_outline,
          children: [
            _reviewRow('Full Name', request.customerName),
            _reviewRow('Phone Number', request.phoneNumber),
            _reviewRow('Email Address', request.emailAddress),
          ],
        ),
        const SizedBox(height: 12),
        _reviewSection(
          title: 'Special Requests',
          icon: Icons.notes_outlined,
          children: [
            Text(
              request.specialRequests.isEmpty
                  ? 'No special requests'
                  : request.specialRequests,
              style: const TextStyle(
                color: Color(0xFF55514C),
                fontSize: 10.5,
                height: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor: const Color(0xFF8D8D8D),
          ),
          child: CheckboxListTile(
            value: acceptedTerms,
            activeColor: gold,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'I confirm all reservation details are correct. '
              'Booking remains pending until reviewed and approved.',
              style: TextStyle(
                color: Color(0xFFC7C7C7),
                fontSize: 10,
                height: 1.35,
              ),
            ),
            onChanged: isSubmitting
                ? null
                : (value) {
                    setState(() {
                      acceptedTerms = value ?? false;
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildPackageCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: gold, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            height: 182,
            child: Image.asset(
              currentPackageImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE5DED0),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.restaurant_menu,
                    color: gold,
                    size: 38,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentStep == 0
                              ? 'PACKAGE SELECTED'
                              : 'PACKAGE',
                          style: const TextStyle(
                            color: gold,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      if (currentStep == 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    currentPackageName,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFF302D29),
                      fontSize: 18,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    currentPackagePrice,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentPackageGuests,
                    style: const TextStyle(
                      color: Color(0xFF656565),
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(height: 7),
                  for (final String inclusion
                      in currentPackageInclusions.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check,
                            color: gold,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              inclusion,
                              style: const TextStyle(
                                color: Color(0xFF4C4C4C),
                                fontSize: 8.7,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (currentStep == 0) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        onPressed: _openPackagePicker,
                        icon: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 16,
                        ),
                        label: const Text('Change Package'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: gold,
                          side: const BorderSide(color: gold),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPackagePicker() async {
    final _ReservationPackageOption? selected =
        await showModalBottomSheet<_ReservationPackageOption>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.78),
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(sheetContext).size.height * 0.82,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF151718),
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
                    8,
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
                            const Text(
                              'Select package for this reservation.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
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
                  color: Color(0xFF2B2D2F),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      24,
                    ),
                    itemCount: _packageOptions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final _ReservationPackageOption package =
                          _packageOptions[index];

                      final bool current =
                          package.name == currentPackageName;

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
                              color: const Color(0xFF1C1F20),
                              borderRadius:
                                  BorderRadius.circular(13),
                              border: Border.all(
                                color: current
                                    ? gold
                                    : const Color(0xFF303335),
                                width: current ? 1.4 : 1,
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
                                      package.image,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: const Color(
                                            0xFF111314,
                                          ),
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
                                          if (current)
                                            const Icon(
                                              Icons.check_circle,
                                              color: gold,
                                              size: 19,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        package.price,
                                        style: const TextStyle(
                                          color: gold,
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        package.capacity,
                                        style: const TextStyle(
                                          color: Colors.white54,
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
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 7.5,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
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

    if (!mounted || selected == null) return;

    setState(() {
      currentPackageName = selected.name;
      currentPackagePrice = selected.price;
      currentPackageImage = selected.image;
      currentPackageGuests = selected.capacity;
      currentPackageInclusions =
          List<String>.from(selected.inclusions);
      selectedGuests =
          _defaultGuestRange(selected.capacity);
      reviewRequest = null;
    });
  }

  Widget _buildDateSection() {
    return _sectionCard(
      step: '01',
      title: 'Date and Time',
      subtitle: 'Choose preferred event schedule.',
      icon: Icons.calendar_month_outlined,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: _pickDate,
          child: InputDecorator(
            decoration: _inputDecoration(
              label: 'Preferred Date',
              icon: Icons.event_outlined,
            ),
            child: Text(
              selectedDate == null
                  ? 'Choose event date'
                  : _formatDate(selectedDate!),
              style: TextStyle(
                color: selectedDate == null
                    ? const Color(0xFF777777)
                    : const Color(0xFF252525),
                fontSize: 12,
                fontWeight: selectedDate == null
                    ? FontWeight.w400
                    : FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _FieldLabel('Preferred Time'),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final String time in const [
              'Morning',
              'Afternoon',
              'Evening',
              'Full Day',
            ])
              _ChoiceChip(
                label: time,
                selected: selectedTime == time,
                onTap: () {
                  setState(() => selectedTime = time);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventSection() {
    return _sectionCard(
      step: '02',
      title: 'Event Details',
      subtitle: 'Add venue, event type, and guest count.',
      icon: Icons.celebration_outlined,
      children: [
        DropdownButtonFormField<String>(
          value: selectedEventType,
          dropdownColor: Colors.white,
          iconEnabledColor: const Color(0xFF252525),
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            label: 'Event Type',
            icon: Icons.event_available_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Birthday',
              child: Text('Birthday'),
            ),
            DropdownMenuItem(
              value: 'Wedding',
              child: Text('Wedding'),
            ),
            DropdownMenuItem(
              value: 'Debut',
              child: Text('Debut'),
            ),
            DropdownMenuItem(
              value: 'Corporate Event',
              child: Text('Corporate Event'),
            ),
            DropdownMenuItem(
              value: 'Baptism',
              child: Text('Baptism'),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Text('Other'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedEventType = value);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedGuests,
          dropdownColor: Colors.white,
          iconEnabledColor: const Color(0xFF252525),
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          decoration: _inputDecoration(
            label: 'Expected Guests',
            icon: Icons.groups_outlined,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Below 50',
              child: Text('Below 50'),
            ),
            DropdownMenuItem(
              value: '50 - 100',
              child: Text('50 - 100'),
            ),
            DropdownMenuItem(
              value: '101 - 150',
              child: Text('101 - 150'),
            ),
            DropdownMenuItem(
              value: '151 - 200',
              child: Text('151 - 200'),
            ),
            DropdownMenuItem(
              value: '201 - 300',
              child: Text('201 - 300'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedGuests = value);
            }
          },
        ),
        const SizedBox(height: 14),
        const _FieldLabel('Event Location'),
        const SizedBox(height: 7),
        _locationChoice(
          title: "Shepherd's Event Place",
          subtitle: 'Event hall and catering service',
          icon: Icons.apartment_outlined,
        ),
        const SizedBox(height: 8),
        _locationChoice(
          title: "Customer's Venue",
          subtitle: 'Catering delivered to your location',
          icon: Icons.local_shipping_outlined,
        ),
        if (isCustomerVenue) ...[
          const SizedBox(height: 12),
          TextFormField(
            style: const TextStyle(
              color: Color(0xFF252525),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: gold,
            controller: addressController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Complete Venue Address',
              icon: Icons.location_on_outlined,
              hint: 'Street, barangay, city',
            ),
            validator: (value) {
              if (isCustomerVenue &&
                  (value == null || value.trim().isEmpty)) {
                return 'Enter customer venue address.';
              }
              return null;
            },
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: gold,
          controller: notesController,
          minLines: 3,
          maxLines: 4,
          decoration: _inputDecoration(
            label: 'Special Requests',
            icon: Icons.notes_outlined,
            hint: 'Optional',
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _sectionCard(
      step: '03',
      title: 'Contact Information',
      subtitle: 'Enter details used for booking updates.',
      icon: Icons.person_outline,
      children: [
        TextFormField(
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: gold,
          controller: nameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            label: 'Full Name',
            icon: Icons.person_outline,
            hint: 'Enter full name',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter full name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 12,
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
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            hint: '09XXXXXXXXX',
          ),
          validator: (value) {
            final String phone =
                value?.replaceAll(RegExp(r'\D'), '') ?? '';

            if (phone.isEmpty) {
              return 'Enter phone number.';
            }

            if (phone.length < 10 || phone.length > 13) {
              return 'Enter valid phone number.';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          style: const TextStyle(
            color: Color(0xFF252525),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: gold,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: _inputDecoration(
            label: 'Email Address',
            icon: Icons.email_outlined,
            hint: 'your@email.com',
          ),
          validator: (value) {
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
      ],
    );
  }

  Widget _buildContinueButton() {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _continueToReview,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: gold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Continue to Review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewButtons() {
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: isSubmitting ? null : _editDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFF55585A),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  'Edit Details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFF6A521A),
                  backgroundColor: gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Booking',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String step,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD3D0C9),
        ),
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
                  color: const Color(0xFFFFF1CC),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: gold, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF302D29),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF77736D),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                step,
                style: const TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Divider(
            height: 24,
            color: Color(0xFFDEDAD2),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _reviewSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD3D0C9),
        ),
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
                  color: const Color(0xFFFFF1CC),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: gold, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF302D29),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(
            height: 24,
            color: Color(0xFFDEDAD2),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF77736D),
                fontSize: 9.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF35322E),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationChoice({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = selectedLocation == title;

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () {
        setState(() => selectedLocation = title);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF1CC)
              : fieldColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? gold
                : const Color(0xFFD5D0C7),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected
                    ? gold
                    : const Color(0xFFE1DDD5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected
                    ? Colors.white
                    : const Color(0xFF66635F),
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF35322E),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF77736D),
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
            _RadioIndicator(selected: selected),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: gold, size: 19),
      filled: true,
      fillColor: fieldColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF4B4742),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: const TextStyle(
        color: Color(0xFF252525),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF6F6A63),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFB00020),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFD5D0C7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: gold,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(
          color: Color(0xFFD5D0C7),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime firstAvailable =
        DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    final DateTime lastAvailable =
        DateTime(now.year + 2, 12, 31);

    DateTime initialDate =
        selectedDate ?? firstAvailable;

    initialDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );

    if (initialDate.isBefore(firstAvailable)) {
      initialDate = firstAvailable;
    }

    if (initialDate.isAfter(lastAvailable)) {
      initialDate = lastAvailable;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAvailable,
      lastDate: lastAvailable,
      initialDatePickerMode: DatePickerMode.day,
      helpText: 'SELECT EVENT DATE',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: gold,
              onPrimary: Colors.white,
              surface: Color(0xFFF7F1E3),
              onSurface: Color(0xFF252525),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFFF7F1E3),
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || pickedDate == null) return;

    setState(() {
      selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
    });
  }

  void _continueToReview() {
    FocusScope.of(context).unfocus();

    if (selectedDate == null) {
      _showMessage('Choose preferred event date.');
      return;
    }

    final bool isFormValid =
        formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      _showMessage('Complete all required fields.');
      return;
    }

    reviewRequest = ReservationRequest(
      packageName: currentPackageName,
      packagePrice: currentPackagePrice,
      packageImage: currentPackageImage,
      packageCapacity: currentPackageGuests,
      packageInclusions: currentPackageInclusions,
      eventDate: selectedDate!,
      eventTime: selectedTime,
      eventType: selectedEventType,
      expectedGuests: selectedGuests,
      location: selectedLocation,
      venueAddress:
          isCustomerVenue ? addressController.text.trim() : '',
      customerName: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      emailAddress: emailController.text.trim(),
      specialRequests: notesController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      currentStep = 1;
      acceptedTerms = false;
    });

    _scrollToTop();
  }

  void _editDetails() {
    setState(() {
      currentStep = 0;
      acceptedTerms = false;
    });

    _scrollToTop();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.jumpTo(0);
    });
  }

  Future<void> _submitBooking() async {
    if (isSubmitting) return;

    final ReservationRequest? request = reviewRequest;

    if (request == null) {
      _showMessage('Reservation details missing.');
      return;
    }

    if (!acceptedTerms) {
      _showMessage('Confirm reservation details first.');
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await _saveBooking(request);
      widget.onSubmit?.call(request);

      if (!mounted) return;

      setState(() => isSubmitting = false);

      bool dialogClosing = false;

      final bool? finished = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            icon: const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFFFE8A8),
              child: Icon(
                Icons.check,
                color: gold,
                size: 30,
              ),
            ),
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Booking Submitted',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              '${request.packageName}\n'
              '${_formatDate(request.eventDate)} • '
              '${request.eventTime}\n\n'
              'Booking is pending review.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: 130,
                child: ElevatedButton(
                  onPressed: () {
                    if (dialogClosing) return;

                    dialogClosing = true;
                    Navigator.of(dialogContext).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted || finished != true) return;

      if (widget.returnToPreviousOnSubmit) {
        Navigator.of(context).pop();
        return;
      }

      Navigator.of(context).popUntil(
        (route) => route.isFirst,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() => isSubmitting = false);

      _showMessage(
        'Booking failed: ${error.message ?? error.code}',
      );
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() => isSubmitting = false);

      _showMessage(error.message);
    } catch (error) {
      if (!mounted) return;

      setState(() => isSubmitting = false);

      _showMessage('Submission failed: $error');
    }
  }

  Future<void> _saveBooking(ReservationRequest request) async {
    final FirebaseFirestore database =
        FirebaseFirestore.instance;

    final DocumentReference<Map<String, dynamic>>
        bookingReference =
        database.collection('bookings').doc();

    if (request.location != "Shepherd's Event Place") {
      await bookingReference.set({
        ...request.toMap(),
        'bookingId': bookingReference.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final String dateKey = request.eventDateKey;

    final List<String> scheduleIds = [
      _eventScheduleId(dateKey),
      ..._legacyDateLockIds(dateKey),
    ];

    await database.runTransaction((transaction) async {
      for (final String scheduleId in scheduleIds) {
        final DocumentReference<Map<String, dynamic>>
            scheduleReference = database
                .collection('venue_schedule_locks')
                .doc(scheduleId);

        final DocumentSnapshot<Map<String, dynamic>>
            scheduleSnapshot =
            await transaction.get(scheduleReference);

        if (!scheduleSnapshot.exists) continue;

        final Map<String, dynamic> scheduleData =
            scheduleSnapshot.data() ??
                <String, dynamic>{};

        final String scheduleStatus =
            (scheduleData['status'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        final bool blocksDate =
            scheduleStatus == 'confirmed' ||
            scheduleStatus == 'in preparation' ||
            scheduleStatus == 'completed';

        if (blocksDate) {
          throw StateError(
            'This date already has a confirmed event-place reservation. '
            'Select another date.',
          );
        }
      }

      transaction.set(bookingReference, {
        ...request.toMap(),
        'bookingId': bookingReference.id,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    });
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 8,
          margin: const EdgeInsets.fromLTRB(
            14,
            0,
            14,
            14,
          ),
          backgroundColor: const Color(0xFF17191A),
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _defaultGuestRange(String capacity) {
    final String normalized = capacity.toLowerCase();

    if (normalized.contains('300')) return '201 - 300';
    if (normalized.contains('200')) return '151 - 200';
    if (normalized.contains('150')) return '101 - 150';
    if (normalized.contains('100')) return '50 - 100';

    return 'Below 50';
  }
}

class _ReservationProgressHeader extends StatelessWidget {
  const _ReservationProgressHeader({
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final bool reviewing = currentStep == 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            flex: 3,
            child: _ProgressStep(
              icon: Icons.inventory_2_outlined,
              label: 'Choose\nPackage',
              completed: true,
            ),
          ),
          const Expanded(
            flex: 4,
            child: _ProgressLine(active: true),
          ),
          Expanded(
            flex: 3,
            child: _ProgressStep(
              icon: Icons.event_note_outlined,
              label: 'Event Details',
              active: !reviewing,
              completed: reviewing,
            ),
          ),
          Expanded(
            flex: 4,
            child: _ProgressLine(active: reviewing),
          ),
          Expanded(
            flex: 3,
            child: _ProgressStep(
              icon: Icons.fact_check_outlined,
              label: 'Review & Submit',
              active: reviewing,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    this.active = false,
    this.completed = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD89B08);
    final bool highlighted = active || completed;

    return Column(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted
                ? const Color(0xFF3A2B06)
                : const Color(0xFF222425),
            border: Border.all(
              color: highlighted
                  ? gold
                  : const Color(0xFF444748),
              width: 1.3,
            ),
          ),
          child: Icon(
            completed ? Icons.check : icon,
            size: 16,
            color: highlighted
                ? gold
                : const Color(0xFFB0B0B0),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: highlighted
                ? Colors.white
                : const Color(0xFFB8B8B8),
            fontSize: 8.3,
            height: 1.22,
            fontWeight: highlighted
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    this.active = false,
  });

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(top: 15),
      color: active
          ? const Color(0xFFD89B08)
          : const Color(0xFF4B4D4E),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD89B08);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? gold
              : const Color(0xFFF0ECE3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? gold
                : const Color(0xFFD5D0C7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF55514C),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD89B08);

    return Container(
      width: 21,
      height: 21,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: selected
              ? gold
              : const Color(0xFFBFBFBF),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? gold : Colors.transparent,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4E4A45),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class ReservationRequest {
  const ReservationRequest({
    required this.packageName,
    required this.packagePrice,
    required this.packageImage,
    required this.packageCapacity,
    required this.packageInclusions,
    required this.eventDate,
    required this.eventTime,
    required this.eventType,
    required this.expectedGuests,
    required this.location,
    required this.venueAddress,
    required this.customerName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.specialRequests,
    required this.createdAt,
  });

  final String packageName;
  final String packagePrice;
  final String packageImage;
  final String packageCapacity;
  final List<String> packageInclusions;
  final DateTime eventDate;
  final String eventTime;
  final String eventType;
  final String expectedGuests;
  final String location;
  final String venueAddress;
  final String customerName;
  final String phoneNumber;
  final String emailAddress;
  final String specialRequests;
  final DateTime createdAt;

  String get eventDateKey {
    final String month =
        eventDate.month.toString().padLeft(2, '0');
    final String day =
        eventDate.day.toString().padLeft(2, '0');

    return '${eventDate.year}-$month-$day';
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'packagePrice': packagePrice,
      'packageImage': packageImage,
      'packageCapacity': packageCapacity,
      'packageInclusions': packageInclusions,
      'eventDate': eventDate,
      'eventDateKey': eventDateKey,
      'eventTime': eventTime,
      'eventType': eventType,
      'expectedGuests': expectedGuests,
      'location': location,
      'venueAddress': venueAddress,
      'customerName': customerName,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'emailLower': emailAddress.trim().toLowerCase(),
      'specialRequests': specialRequests,
      'createdAt': createdAt,
      'status': 'pending',
    };
  }
}

class _TopBackBar extends StatelessWidget {
  const _TopBackBar({
    required this.label,
    required this.onBack,
  });

  final String label;
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
            tooltip: label,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
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
