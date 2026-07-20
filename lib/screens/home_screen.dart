import 'package:flutter/material.dart';
import 'availability_screen.dart';
import 'inquiry_screen.dart';
import 'staff_login_screen.dart';
import 'chatbot_screen.dart';
import 'package:shepherds_app/screens/gallery_screen.dart';
import 'package:shepherds_app/screens/packages_screen.dart';
import 'package:shepherds_app/screens/reservation_screen.dart';
import 'package:google_fonts/google_fonts.dart';


// Homepage with working navigation shortcuts.
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final ScrollController scrollController = ScrollController();

  static const Color gold = Color(0xFFD5A021);
  static const Color background = Color(0xFF080A0B);
  static const Color cardColor = Color(0xFF111416);
  static const Color cream = Color(0xFFF7F1E3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      drawer: buildMenuDrawer(context),

      // SingleChildScrollView lets the whole homepage move vertically.
      body: SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              buildHeader(context),
              buildHeroSection(context),
              buildStatisticsSection(),
              buildTrustedSection(),
              buildWhyChooseUsSection(),
              buildPackagesSection(context),
              buildServicesSection(context),
              buildStorySection(),
              buildGallerySection(context),
              buildVenueSection(context),
              buildTestimonialsSection(),
              buildCallToActionSection(context),
              buildFooter(),
              const SizedBox(height: 74),
            ],
          ),
        ),
      ),

      // This stays at the bottom like a real mobile application.
      bottomNavigationBar: buildBottomNavigation(context),
    );
  }

  // ============================================================
  // HEADER
  // Shows the logo, business name, and menu button.
  // ============================================================
  Widget buildHeader(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      color: const Color(0xFF0C0E0F),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', width: 38, height: 38),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Shepherd's",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'CATERING & EVENTS',
                style: GoogleFonts.montserrat(
                  color: gold,
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO SECTION
  // Main image, slogan, description, and two visible buttons.
  // ============================================================
  Widget buildHeroSection(BuildContext context) {
    return Container(
      height: 430,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/hero.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 45, 24, 26),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xF2080A0B), Color(0xA8080A0B), Color(0x30080A0B)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Where Every\n', style: GoogleFonts.playfairDisplay()),
                  TextSpan(
                    text: 'Celebration\n',
                    style: GoogleFonts.playfairDisplay(
                      color: gold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  TextSpan(text: 'Tastes Memorable', style: GoogleFonts.playfairDisplay()),
                ],
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.w600,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 300,
              child: Text(
                'From intimate gatherings to grand celebrations, we create exceptional moments with heart, flavor, and elegance.',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 11,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                buildLightButton(
                  'Plan Your Event',
                  Icons.arrow_forward,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReservationScreen(),
                      ),
                    );
                  },
                ),
                buildOutlineButton(
                  'See Packages',
                  Icons.restaurant_menu,
                  onPressed: () {
                    scrollController.animateTo(
                      1150,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // Displays simple fixed business numbers from the website.
  // ============================================================
  Widget buildStatisticsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          buildStatistic('1,200+', 'EVENTS HOSTED'),
          buildDivider(),
          buildStatistic('17+', 'YEARS OF\nEXCELLENCE'),
          buildDivider(),
          buildStatistic('4.9 ★', 'AVERAGE\nRATING'),
        ],
      ),
    );
  }

  Widget buildStatistic(String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.playfairDisplay(
              color: gold,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDivider() {
    return Container(width: 1, height: 42, color: Colors.white24);
  }

  // ============================================================
  // TRUSTED BY
  // Static sample client names that imitate the website strip.
  // ============================================================
  Widget buildTrustedSection() {
    return Container(
      color: cream,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 25),
      child: Column(
        children: [
          buildSmallSectionLabel('WHY CHOOSE SHEPHERD\'S', dark: true),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildMinimalFeature(
                Icons.star_rounded,
                'Consistent\nSatisfaction',
                '4.9★ avg rating\nacross 1,200+\nevents served\nsince 2009.',
              ),
              buildMinimalFeature(
                Icons.restaurant_rounded,
                'High Quality\nIngredients',
                'Fresh, locally\nsourced produce,\nprepped daily\nin-house.',
              ),
              buildMinimalFeature(
                Icons.groups_rounded,
                'Dedicated\nService Staff',
                'A dedicated\ncoordinator and\ncrew handle\nevery event.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMinimalFeature(
    IconData icon,
    String title,
    String description,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF303539),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

        ],
      ),
    );
  }
  Widget buildClient(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.grey.shade700),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF303539),
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(subtitle, style: const TextStyle(color: Color(0xFF737A7F), fontSize: 5)),
      ],
    );
  }

  // ============================================================
  // WHY CHOOSE US
  // Three advantages shown in the original website.
  // ============================================================
  Widget buildWhyChooseUsSection() {
    return buildDarkSection(
      child: Column(
        children: [
          buildSectionHeading('Why Choose Shepherd\'s', 'Thoughtful service in every detail.'),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFeature(Icons.sentiment_satisfied_alt, 'Consistent\nSatisfaction', 'Trusted results for every celebration.'),
              buildFeature(Icons.eco_outlined, 'High Quality\nIngredients', 'Fresh ingredients prepared with care.'),
              buildFeature(Icons.groups_outlined, 'Dedicated\nService Staff', 'A professional team from start to finish.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFeature(IconData icon, String title, String description) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: gold)),
              child: Icon(icon, color: gold, size: 25),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 7.5, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PACKAGES PREVIEW
  // Sends the user to the reservation flow where packages are chosen.
  // ============================================================
  Widget buildPackagesSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
      decoration: const BoxDecoration(
        color: cream,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: gold.withOpacity(0.45),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            buildSmallSectionLabel(
              'CATERING PACKAGES',
              dark: true,
            ),
            const SizedBox(height: 10),
            Text(
              'Choose Your Catering Package',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: Colors.black87,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Explore flexible catering options for intimate gatherings, weddings, birthdays, and grand celebrations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 11,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildPackagePreview(
                  Icons.restaurant_outlined,
                  'Classic Package',
                ),
                buildPackagePreview(
                  Icons.room_service_outlined,
                  'Premium Package',
                ),
                buildPackagePreview(
                  Icons.workspace_premium_outlined,
                  'Grand Package',
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PackagesScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 17,
                ),
                label: const Text(
                  'View Packages',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111416),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small package preview shown on the homepage.
  Widget buildPackagePreview(
    IconData icon,
    String title,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: gold.withOpacity(0.45),
              ),
            ),
            child: Icon(
              icon,
              color: gold,
              size: 25,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICES
  // Two main services: catering and event hall rental.
  // ============================================================
  Widget buildServicesSection(BuildContext context) {
    return buildDarkSection(
      child: Column(
        children: [
          buildSectionHeading(
            'Everything Under One Roof',
            'Food, venue, setup, and service.',
          ),
          const SizedBox(height: 22),
          buildServiceCard(
            icon: Icons.room_service_outlined,
            title: 'Catering Services',
            description:
                'Customizable catering packages for intimate gatherings and large celebrations.',
            button: 'Get a Catering Quote',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InquiryScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          buildServiceCard(
            icon: Icons.celebration_outlined,
            title: 'Event Hall Rental',
            description:
                'A complete event venue with catering, setup, and support for every celebration.',
            button: 'Check Availability',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AvailabilityScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildServiceCard({
    required IconData icon,
    required String title,
    required String description,
    required String button,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: gold,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: onPressed,
                      borderRadius:
                          BorderRadius.circular(8),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              button,
                              style: const TextStyle(
                                color: gold,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: gold,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STORY
  // A visual section that highlights the business history.
  // ============================================================
  Widget buildStorySection() {
    return Container(
      height: 330,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/hero.png'), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black26, Colors.black87]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSmallSectionLabel('OUR STORY'),
            const SizedBox(height: 10),
            Text(
              'Cooking Delicious Food Since 2009',
              style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.15),
            ),
            const SizedBox(height: 12),
            const Text('Years of serving memorable meals and meaningful celebrations.', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GALLERY
  // Three event photos from the website gallery.
  // ============================================================
  Widget buildGallerySection(BuildContext context) {
    return Container(
      color: cream,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 34),
      child: Column(
        children: [
          buildSectionHeading('Events We\'ve Brought to Life', 'A glimpse of celebrations prepared by Shepherd\'s.', dark: true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: buildGalleryImage('assets/images/gallery_1.jpg', 220)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    buildGalleryImage('assets/images/gallery_2.jpg', 105),
                    const SizedBox(height: 10),
                    buildGalleryImage('assets/images/gallery_3.jpg', 105),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          buildDarkButton(
            'View Gallery',
            Icons.photo_library_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GalleryScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildGalleryImage(String path, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(path, height: height, width: double.infinity, fit: BoxFit.cover),
    );
  }

  // ============================================================
  // VENUE
  // Shows the event place and its main features.
  // ============================================================
  Widget buildVenueSection(BuildContext context) {
    return buildDarkSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionHeading('One Space. Every Occasion.', 'A flexible venue for meaningful celebrations.'),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset('assets/images/venue.jpg', width: double.infinity, height: 215, fit: BoxFit.cover),
          ),
          const SizedBox(height: 18),
          Text(
            'Shepherd\'s Event Place',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 9),
          buildAvailabilityIndicator(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              buildVenueTag(Icons.groups_outlined, 'Up to 300 guests'),
              buildVenueTag(Icons.ac_unit_outlined, 'Air-conditioned'),
              buildVenueTag(Icons.restaurant_outlined, 'In-house catering'),
              buildVenueTag(Icons.local_parking_outlined, 'Parking area'),
            ],
          ),
          const SizedBox(height: 20),
          buildLightButton(
            'Check Availability',
            Icons.calendar_month_outlined,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvailabilityScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildAvailabilityIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF123B24),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF44C976).withOpacity(0.55),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Color(0xFF62DC8B),
            size: 15,
          ),
          SizedBox(width: 7),
          Text(
            'AVAILABLE — CHECK YOUR DATE',
            style: TextStyle(
              color: Color(0xFF9EF0B9),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVenueTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, color: gold, size: 16), const SizedBox(width: 7), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 9))],
      ),
    );
  }

  // ============================================================
  // TESTIMONIALS
  // Static review cards. Swiping can be added later.
  // ============================================================
  Widget buildTestimonialsSection() {
    return Container(
      color: cream,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 34),
      child: Column(
        children: [
          buildSectionHeading('What Our Clients Say', 'Real experiences from memorable celebrations.', dark: true),
          const SizedBox(height: 20),
          buildReviewCard('“The food, styling, and staff made our wedding day truly special.”', 'Maria & Daniel', 'Wedding Reception'),
          const SizedBox(height: 12),
          buildReviewCard('“Everything was organized beautifully, and our guests loved the food.”', 'Angela Cruz', 'Birthday Celebration'),
        ],
      ),
    );
  }

  Widget buildReviewCard(String review, String name, String event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('★★★★★', style: TextStyle(color: gold, letterSpacing: 2)),
          const SizedBox(height: 12),
          Text(review, style: GoogleFonts.playfairDisplay(color: Colors.black87, fontSize: 17, fontStyle: FontStyle.italic, height: 1.45)),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          Text(event, style: const TextStyle(color: Colors.black45, fontSize: 10)),
        ],
      ),
    );
  }

  // ============================================================
  // CALL TO ACTION
  // Final promotional area before the footer.
  // ============================================================
  Widget buildCallToActionSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/cta.png'), fit: BoxFit.cover),
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(color: Color(0xB5000000)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Book Your Event & Get a Free Quote', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            const Text('Tell us your date, headcount, and vision. Our team will help you find the right package.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5)),
            const SizedBox(height: 20),
            buildLightButton(
              'Start Your Inquiry',
              Icons.arrow_forward,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InquiryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // Basic business details and social icons.
  // ============================================================
  Widget buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF050607),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
      child: Column(
        children: [
          Image.asset('assets/images/logo.png', width: 62),
          const SizedBox(height: 10),
          Text("Shepherd's", style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('CATERING • EVENTS • CELEBRATIONS', style: TextStyle(color: gold, fontSize: 8, letterSpacing: 1.4)),
          const SizedBox(height: 20),
          const Text('Batangas, Philippines', style: TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.facebook, color: Colors.white70),
              SizedBox(width: 18),
              Icon(Icons.camera_alt_outlined, color: Colors.white70),
              SizedBox(width: 18),
              Icon(Icons.email_outlined, color: Colors.white70),
              SizedBox(width: 18),
              Icon(Icons.phone_outlined, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          const Text('© 2026 Shepherd\'s Catering & Events', style: TextStyle(color: Colors.white38, fontSize: 8)),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // Working shortcuts to main customer screens.
  // ============================================================
  Widget buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF0C0E0F),
      selectedItemColor: gold,
      unselectedItemColor: Colors.white54,
      selectedFontSize: 9,
      unselectedFontSize: 9,
      onTap: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PackagesScreen(),
            ),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReservationScreen(),
            ),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GalleryScreen(),
            ),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatbotScreen(),
            ),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Packages'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Reserve'),
        BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), label: 'Gallery'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Chatbot'),
      ],
    );
  }

  // ============================================================
  // MENU DRAWER
  // Displays the website's main navigation links.
  // ============================================================
  Drawer buildMenuDrawer(BuildContext context) {
    return Drawer(
      width: 310,
      backgroundColor: const Color(0xFF0C0E0F),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF111416),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF292C2E),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 54,
                    height: 54,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Shepherd's",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'CATERING & EVENTS',
                          style: TextStyle(
                            color: gold,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                    ),
                    tooltip: 'Close menu',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 9),
                    child: Text(
                      'QUICK ACCESS',
                      style: TextStyle(
                        color: Color(0xFF8A8D8F),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Return to homepage top',
                    selected: true,
                    onTap: () => _returnHome(context),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Catering Packages',
                    subtitle: 'Compare Classic, Premium, and Grand',
                    onTap: () => _openScreen(
                      context,
                      const PackagesScreen(),
                    ),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.event_available_rounded,
                    title: 'Reserve an Event',
                    subtitle: 'Create a direct reservation',
                    onTap: () => _openScreen(
                      context,
                      const ReservationScreen(),
                    ),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    title: 'Check Venue Availability',
                    subtitle: 'View available dates and time slots',
                    onTap: () => _openScreen(
                      context,
                      const AvailabilityScreen(),
                    ),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    title: 'Event Gallery',
                    subtitle: 'Browse previous celebrations',
                    onTap: () => _openScreen(
                      context,
                      const GalleryScreen(),
                    ),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.mark_email_read_rounded,
                    title: 'Send an Inquiry',
                    subtitle: 'Ask about services, pricing, or events',
                    onTap: () => _openScreen(
                      context,
                      const InquiryScreen(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                    color: Color(0xFF292C2E),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 12, 10, 9),
                    child: Text(
                      'TEAM ACCESS',
                      style: TextStyle(
                        color: Color(0xFF8A8D8F),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _drawerShortcut(
                    context: context,
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Staff / Admin Sign In',
                    subtitle: 'Secure access for staff, admins, and owners',
                    onTap: () => _openScreen(
                      context,
                      const StaffLoginScreen(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151819),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gold.withOpacity(0.25),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: gold,
                          size: 18,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Reservations and inquiries remain pending until reviewed by Shepherd\'s team.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerShortcut({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: selected
            ? gold.withOpacity(0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? gold.withOpacity(0.45)
                    : Colors.transparent,
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
                        : const Color(0xFF1B1E20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? Colors.black
                        : gold,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected
                              ? gold
                              : Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 8.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.chevron_right,
                  color: selected
                      ? gold
                      : Colors.white38,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _returnHome(BuildContext context) {
    Navigator.pop(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.pop(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  // ============================================================
  // REUSABLE DESIGN HELPERS
  // These keep repeated styles short and easy to update.
  // ============================================================
  Widget buildDarkSection({required Widget child}) {
    return Container(
      width: double.infinity,
      color: background,
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 34),
      child: child,
    );
  }

  Widget buildSectionHeading(String title, String subtitle, {bool dark = false}) {
    return Column(
      children: [
        buildSmallSectionLabel('SHEPHERD\'S', dark: dark),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: dark ? Colors.black87 : Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: dark ? Colors.black54 : Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  Widget buildSmallSectionLabel(String text, {bool dark = false}) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: dark ? const Color(0xFF8B6510) : gold,
        fontSize: 8,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget buildLightButton(String text, IconData icon, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: cream,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget buildOutlineButton(String text, IconData icon, {VoidCallback? onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: gold),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget buildDarkButton(String text, IconData icon, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF111416),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
