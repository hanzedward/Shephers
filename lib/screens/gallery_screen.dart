import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'reservation_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() =>
      _GalleryScreenState();
}

class _GalleryItem {
  const _GalleryItem({
    required this.imagePath,
    required this.category,
    required this.title,
  });

  final String imagePath;
  final String category;
  final String title;
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const Color gold = Color(0xFFD5A021);
  static const Color background = Color(0xFF080A0B);
  static const Color cardColor = Color(0xFF111416);
  static const Color cardColor2 = Color(0xFF171B1D);
  static const Color border = Color(0xFF292D2F);
  static const Color textMuted = Color(0xFFA8A8A2);

  static const List<String> _categories = [
    'All',
    'Weddings',
    'Corporate',
    'Birthdays',
    'Debuts',
    'Baptisms',
  ];

  static const List<_GalleryItem> _galleryItems = [
    _GalleryItem(
      imagePath: 'assets/images/gallery_1.jpg',
      category: 'Weddings',
      title: 'Elegant Wedding Reception',
    ),
    _GalleryItem(
      imagePath: 'assets/images/gallery_2.jpg',
      category: 'Corporate',
      title: 'Corporate Celebration',
    ),
    _GalleryItem(
      imagePath: 'assets/images/gallery_3.jpg',
      category: 'Birthdays',
      title: 'Birthday Celebration',
    ),
    _GalleryItem(
      imagePath: 'assets/images/gallery_1.jpg',
      category: 'Debuts',
      title: 'Debut Reception',
    ),
    _GalleryItem(
      imagePath: 'assets/images/gallery_2.jpg',
      category: 'Baptisms',
      title: 'Baptism Gathering',
    ),
    _GalleryItem(
      imagePath: 'assets/images/gallery_3.jpg',
      category: 'Weddings',
      title: 'Wedding Banquet',
    ),
  ];

  String _selectedCategory = 'All';

  List<_GalleryItem> get _visibleItems {
    if (_selectedCategory == 'All') {
      return _galleryItems;
    }

    return _galleryItems
        .where(
          (item) =>
              item.category == _selectedCategory,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<_GalleryItem> visibleItems =
        _visibleItems;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TopBackBar(
                onBack: () {
                  Navigator.maybePop(context);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _buildTitleSection(),
            ),
            SliverToBoxAdapter(
              child: _buildCategoryButtons(),
            ),
            if (visibleItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  14,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final _GalleryItem item =
                          visibleItems[index];

                      return _buildGalleryPhoto(
                        item,
                        visibleItems,
                        index,
                      );
                    },
                    childCount: visibleItems.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                    childAspectRatio: 0.72,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _buildCallToAction(context),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        26,
        20,
        18,
      ),
      child: Column(
        children: [
          Text(
            'Event Gallery',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 1,
                color: gold,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: gold,
                  size: 14,
                ),
              ),
              Container(
                width: 34,
                height: 1,
                color: gold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Memorable moments from\nevents we've catered",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButtons() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String category = _categories[index];
          final bool selected =
              category == _selectedCategory;

          return OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  selected ? gold : cardColor,
              foregroundColor:
                  selected ? Colors.black : Colors.white70,
              side: BorderSide(
                color:
                    selected ? gold : Colors.white24,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
            child: Text(
              category,
              style: GoogleFonts.montserrat(
                fontSize: 8,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGalleryPhoto(
    _GalleryItem item,
    List<_GalleryItem> visibleItems,
    int index,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () {
          _openImagePreview(
            items: visibleItems,
            initialIndex: index,
          );
        },
        borderRadius: BorderRadius.circular(9),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: border,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      color: cardColor2,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: gold,
                        size: 28,
                      ),
                    );
                  },
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x99000000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 7,
                  right: 7,
                  bottom: 7,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          color: gold,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 7,
                  right: 7,
                  child: Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white70,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
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
              Icons.photo_library_outlined,
              color: gold,
              size: 44,
            ),
            const SizedBox(height: 11),
            Text(
              'No photos found',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Choose another category.',
              style: GoogleFonts.montserrat(
                color: textMuted,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImagePreview({
    required List<_GalleryItem> items,
    required int initialIndex,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (dialogContext) {
        return _GalleryPreviewDialog(
          items: items,
          initialIndex: initialIndex,
        );
      },
    );
  }

  Widget _buildCallToAction(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.symmetric(horizontal: 16),
      padding:
          const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0AA28),
            Color(0xFFB97A09),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Create Your Own Memories?',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let us bring the same care and quality to your next event.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 9,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 190,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ReservationScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.event_outlined,
                size: 17,
              ),
              label: const Text('Plan Your Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    const Color(0xFFB27805),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                textStyle: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryPreviewDialog extends StatefulWidget {
  const _GalleryPreviewDialog({
    required this.items,
    required this.initialIndex,
  });

  final List<_GalleryItem> items;
  final int initialIndex;

  @override
  State<_GalleryPreviewDialog> createState() =>
      _GalleryPreviewDialogState();
}

class _GalleryPreviewDialogState
    extends State<_GalleryPreviewDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  static const Color gold = Color(0xFFD5A021);

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _GalleryItem currentItem =
        widget.items[_currentIndex];

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      backgroundColor: const Color(0xFF0C0E0F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height:
            MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                10,
                7,
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
                          currentItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentItem.category.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: gold,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1}/'
                    '${widget.items.length}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white54,
                      fontSize: 8.5,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Color(0xFF292D2F),
              height: 1,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final _GalleryItem item =
                      widget.items[index];

                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.asset(
                          item.imagePath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const Center(
                              child: Icon(
                                Icons
                                    .image_not_supported_outlined,
                                color: gold,
                                size: 48,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                13,
              ),
              child: Text(
                'Swipe for more photos · Pinch to zoom',
                style: GoogleFonts.montserrat(
                  color: Colors.white54,
                  fontSize: 8.5,
                ),
              ),
            ),
          ],
        ),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 10),
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
            tooltip: 'Back',
          ),
          const SizedBox(width: 2),
          const Text(
            'Back',
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
