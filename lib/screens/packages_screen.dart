import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shepherds_app/screens/reservation_screen.dart';

class PackagesScreen extends StatefulWidget {
  final ValueChanged<CateringPackage>? onContinue;

  const PackagesScreen({
    super.key,
    this.onContinue,
  });

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  static const Color gold = Color(0xFFD89B08);
  static const Color background = Color(0xFF090A0A);

  int selectedPackageIndex = 0;
  int? expandedPackageIndex;

  static const List<CateringPackage> packages = [
    CateringPackage(
      name: 'Classic Package',
      price: '₱12,000',
      capacity: 'Up to 100 pax',
      imagePath: 'assets/images/light_catering.jpg',
      shortDescription:
          'Simple and affordable catering for smaller gatherings and short events.',
      recommendedFor:
          'Meetings, seminars, intimate birthdays, office events, and simple celebrations.',
      inclusions: [
        '2-course set menu',
        'Rice and one beverage option',
        'Basic buffet setup',
        'Service staff assistance',
        'Basic cleanup after service',
      ],
      menuDetails: [
        'Choice of 2 main dishes',
        'Rice included',
        'One standard beverage',
        'Dessert available as add-on',
      ],
      serviceDetails: [
        'Basic food setup and service',
        'Limited service crew based on guest count',
        'Standard serving equipment',
        'Basic cleanup of catering area',
      ],
      importantNotes: [
        'Best for shorter and simpler events',
        'Tables, linens, and decorations quoted separately',
        'Additional menu items increase final price',
        'Reservation remains pending until approved',
      ],
    ),
    CateringPackage(
      name: 'Premium Package',
      price: '₱24,000',
      capacity: 'Up to 200 pax',
      imagePath: 'assets/images/full_catering.jpg',
      isPopular: true,
      shortDescription:
          'Complete buffet catering with service staff, setup, tables, and linens.',
      recommendedFor:
          'Weddings, birthdays, reunions, baptisms, and large family celebrations.',
      inclusions: [
        'Buffet spread with 3 viands',
        'Steamed rice, drinks, and dessert',
        'Professional service staff',
        'Buffet setup and cleanup',
        'Tables and basic linens',
        'Serving utensils and food warmers',
      ],
      menuDetails: [
        'Choice of chicken, pork, beef, or fish viands',
        'Rice and one dessert selection',
        'One standard beverage option',
        'Menu changes subject to quotation',
      ],
      serviceDetails: [
        'Food preparation and buffet arrangement',
        'Service crew during agreed event hours',
        'Basic table and buffet-area setup',
        'Post-event buffet cleanup',
      ],
      importantNotes: [
        'Final price depends on confirmed guest count',
        'Transportation fees may apply outside service area',
        'Decorations and venue rental are not automatically included',
        'Reservation remains pending until approved',
      ],
    ),
    CateringPackage(
      name: 'Grand Package',
      price: '₱42,000',
      capacity: 'Up to 300 pax',
      imagePath: 'assets/images/premium_catering.jpg',
      shortDescription:
          'Premium full-service package for large events requiring complete coordination.',
      recommendedFor:
          'Grand weddings, corporate functions, debuts, anniversaries, and major celebrations.',
      inclusions: [
        'Full buffet with 5 viands',
        'Appetizers and dessert bar',
        'Rice and beverage selections',
        'Complete tableware',
        'Event staff and coordinator',
        'Full buffet setup and cleanup',
      ],
      menuDetails: [
        'Choice of 5 premium viands',
        'Appetizer selection',
        'Dessert bar options',
        'Multiple beverage choices',
        'Custom menu consultation',
      ],
      serviceDetails: [
        'Dedicated event coordinator',
        'Expanded professional service team',
        'Complete buffet styling and tableware',
        'Full catering-area setup and cleanup',
      ],
      importantNotes: [
        'Final quotation depends on menu and event requirements',
        'Venue, styling, and special equipment may cost extra',
        'Transportation fees may apply',
        'Reservation remains pending until approved',
      ],
    ),
  ];

  void _continue() {
    final selectedPackage = packages[selectedPackageIndex];

    if (widget.onContinue != null) {
      widget.onContinue!(selectedPackage);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          entry: ReservationEntry.packages,
          packageName: selectedPackage.name,
          packagePrice: selectedPackage.price,
          packageImage: selectedPackage.imagePath,
          packageGuests: selectedPackage.capacity,
          packageInclusions: selectedPackage.inclusions,
          packageSelected: true,
        ),
      ),
    );
  }

  void _selectPackage(int index) {
    setState(() {
      selectedPackageIndex = index;
    });
  }

  void _toggleDetails(int index) {
    setState(() {
      expandedPackageIndex =
          expandedPackageIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
            const _ProgressHeader(),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFF1E1F20),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(19, 17, 19, 12),
                children: [
                  Text(
                    'Choose Your Catering Package',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 22,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Compare guest capacity, menu coverage, service support, and important package conditions before continuing.',
                    style: TextStyle(
                      color: Color(0xFFC7C7C7),
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildInformationNotice(),
                  const SizedBox(height: 12),
                  for (int index = 0; index < packages.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PackageCard(
                        package: packages[index],
                        selected: selectedPackageIndex == index,
                        expanded: expandedPackageIndex == index,
                        onSelect: () => _selectPackage(index),
                        onToggleDetails: () => _toggleDetails(index),
                      ),
                    ),
                  const SizedBox(height: 4),
                  _buildPriceNotice(),
                ],
              ),
            ),
            _ContinueButton(
              packageName: packages[selectedPackageIndex].name,
              onPressed: _continue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151718),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2B2D2E),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: gold,
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Starting prices shown below. Final quotation depends on guest count, menu changes, event location, transportation, equipment, and special requests.',
              style: TextStyle(
                color: Color(0xFFC8C8C8),
                fontSize: 9.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceNotice() {
    final selected = packages[selectedPackageIndex];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF151718),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gold.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT SELECTION',
            style: TextStyle(
              color: gold,
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            selected.name,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${selected.price} starting price • ${selected.capacity}',
            style: const TextStyle(
              color: Color(0xFFC7C7C7),
              fontSize: 9.5,
            ),
          ),
        ],
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(17, 18, 17, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _ProgressStep(
              icon: Icons.inventory_2_outlined,
              label: 'Choose\nPackage',
              active: true,
            ),
          ),
          Expanded(
            flex: 4,
            child: _ProgressLine(active: true),
          ),
          Expanded(
            flex: 3,
            child: _ProgressStep(
              icon: Icons.event_note_outlined,
              label: 'Event Details',
            ),
          ),
          Expanded(
            flex: 4,
            child: _ProgressLine(),
          ),
          Expanded(
            flex: 3,
            child: _ProgressStep(
              icon: Icons.fact_check_outlined,
              label: 'Review & Submit',
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
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD89B08);

    return Column(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? const Color(0xFF3A2B06)
                : const Color(0xFF222425),
            border: Border.all(
              color: active
                  ? gold
                  : const Color(0xFF444748),
              width: 1.3,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active
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
            color: active
                ? Colors.white
                : const Color(0xFFB8B8B8),
            fontSize: 8.3,
            height: 1.22,
            fontWeight: active
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

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.selected,
    required this.expanded,
    required this.onSelect,
    required this.onToggleDetails,
  });

  final CateringPackage package;
  final bool selected;
  final bool expanded;
  final VoidCallback onSelect;
  final VoidCallback onToggleDetails;

  static const Color gold = Color(0xFFD89B08);
  static const Color cardColor = Color(0xFFF8F6F1);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? gold
              : const Color(0xFFD3D0C9),
          width: selected ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onSelect,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: 104,
                      height: 150,
                      child: Image.asset(
                        package.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            color: const Color(0xFFE5DED0),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.restaurant_menu,
                              color: gold,
                              size: 36,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        0,
                        5,
                        3,
                        4,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  package.name,
                                  style: GoogleFonts.playfairDisplay(
                                    color: const Color(0xFF302D29),
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              _SelectionCircle(
                                selected: selected,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            package.price,
                            style: const TextStyle(
                              color: gold,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            package.capacity,
                            style: const TextStyle(
                              color: Color(0xFF656565),
                              fontSize: 9.5,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            package.shortDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF4E4A45),
                              fontSize: 9,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InformationLine(
                            icon: Icons.celebration_outlined,
                            text: package.recommendedFor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (package.isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ),
              color: const Color(0xFFFFF1CC),
              child: const Text(
                'MOST POPULAR — COMPLETE SERVICE AND SETUP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8C6500),
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          InkWell(
            onTap: onToggleDetails,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 11,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFDEDAD2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: gold,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      expanded
                          ? 'Hide package details'
                          : 'View complete package details',
                      style: const TextStyle(
                        color: Color(0xFF4E4A45),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: gold,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) _ExpandedPackageDetails(package: package),
        ],
      ),
    );
  }
}

class _ExpandedPackageDetails extends StatelessWidget {
  const _ExpandedPackageDetails({
    required this.package,
  });

  final CateringPackage package;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 4, 13, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF8),
        border: Border(
          top: BorderSide(
            color: Color(0xFFEEE5D5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailGroup(
            title: 'PACKAGE INCLUSIONS',
            icon: Icons.check_circle_outline,
            items: package.inclusions,
          ),
          const SizedBox(height: 13),
          _DetailGroup(
            title: 'MENU INFORMATION',
            icon: Icons.restaurant_menu,
            items: package.menuDetails,
          ),
          const SizedBox(height: 13),
          _DetailGroup(
            title: 'SERVICE COVERAGE',
            icon: Icons.groups_outlined,
            items: package.serviceDetails,
          ),
          const SizedBox(height: 13),
          _DetailGroup(
            title: 'IMPORTANT NOTES',
            icon: Icons.info_outline,
            items: package.importantNotes,
            warning: true,
          ),
        ],
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({
    required this.title,
    required this.icon,
    required this.items,
    this.warning = false,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD89B08);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: warning
                  ? const Color(0xFFB76A2C)
                  : gold,
              size: 15,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: warning
                    ? const Color(0xFF8A4D1E)
                    : const Color(0xFF6D5207),
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  warning
                      ? Icons.circle
                      : Icons.check,
                  color: warning
                      ? const Color(0xFFB76A2C)
                      : gold,
                  size: warning ? 6 : 12,
                ),
                SizedBox(width: warning ? 7 : 5),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF4C4C4C),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InformationLine extends StatelessWidget {
  const _InformationLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.star_outline,
          color: Color(0xFFD89B08),
          size: 13,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF69645E),
              fontSize: 8.3,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({
    required this.selected,
  });

  final bool selected;

  @override
  Widget build(BuildContext context) {
    const Color gold = Color(0xFFD89B08);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? gold
              : Colors.transparent,
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.packageName,
    required this.onPressed,
  });

  final String packageName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF090A0A),
      padding: const EdgeInsets.fromLTRB(19, 8, 19, 14),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFFD89B08),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Continue with $packageName',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CateringPackage {
  const CateringPackage({
    required this.name,
    required this.price,
    required this.capacity,
    required this.imagePath,
    required this.shortDescription,
    required this.recommendedFor,
    required this.inclusions,
    required this.menuDetails,
    required this.serviceDetails,
    required this.importantNotes,
    this.isPopular = false,
  });

  final String name;
  final String price;
  final String capacity;
  final String imagePath;
  final String shortDescription;
  final String recommendedFor;
  final List<String> inclusions;
  final List<String> menuDetails;
  final List<String> serviceDetails;
  final List<String> importantNotes;
  final bool isPopular;
}
