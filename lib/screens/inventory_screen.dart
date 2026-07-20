import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/admin_theme.dart';
import '../widgets/admin_drawer.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() =>
      _InventoryScreenState();
}

class _InvItem {
  const _InvItem({
    required this.documentId,
    required this.name,
    required this.category,
    required this.qty,
    required this.min,
    required this.unit,
    required this.lastChecked,
  });

  final String documentId;
  final String name;
  final String category;
  final int qty;
  final int min;
  final String unit;
  final String lastChecked;

  String get status {
    if (qty <= 0) return 'Missing';
    if (qty < min) return 'Low';
    return 'Good';
  }

  factory _InvItem.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data = document.data();

    return _InvItem(
      documentId: document.id,
      name: _readText(data['name'], 'Unnamed Item'),
      category: _readText(data['category'], 'Other'),
      qty: _readInteger(data['quantity'] ?? data['qty']),
      min: _readInteger(
        data['minimumQuantity'] ??
            data['minimum'] ??
            data['min'],
      ),
      unit: _readText(data['unit'], 'pcs'),
      lastChecked: _formatCheckedDate(
        data['lastCheckedAt'] ??
            data['updatedAt'] ??
            data['createdAt'],
      ),
    );
  }

  static String _readText(
    dynamic value,
    String fallback,
  ) {
    final String text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInteger(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatCheckedDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Not recorded';

    final DateTime now = DateTime.now();
    final bool today =
        date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (today) return 'Today';

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

    return '${months[date.month - 1]} ${date.day}';
  }
}

class _InventoryScreenState
    extends State<InventoryScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedFilter = 'All Items';
  String _selectedCategory = 'All Categories';
  String _sortMode = 'Name';

  List<_InvItem> _items = const [];

  String _role = 'none';

  bool get _canAddOrEdit =>
      _role == 'owner' || _role == 'manager';

  bool get _canAdjustStock =>
      _role == 'owner' ||
      _role == 'manager' ||
      _role == 'staff';

  bool get _canDeleteItem => _role == 'owner';

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

  static const List<String> _filters = [
    'All Items',
    'Good Condition',
    'Needs Attention',
    'Missing / Out',
  ];

  List<String> get _categories {
    final List<String> categories = _items
        .map((item) => item.category)
        .toSet()
        .toList()
      ..sort();

    return [
      'All Categories',
      ...categories,
    ];
  }

  List<_InvItem> get _visibleItems {
    final String query =
        _searchController.text.trim().toLowerCase();

    final List<_InvItem> filtered =
        _items.where((item) {
      final bool statusMatches =
          _selectedFilter == 'All Items' ||
          (_selectedFilter == 'Good Condition' &&
              item.status == 'Good') ||
          (_selectedFilter == 'Needs Attention' &&
              item.status == 'Low') ||
          (_selectedFilter == 'Missing / Out' &&
              item.status == 'Missing');

      final bool categoryMatches =
          _selectedCategory == 'All Categories' ||
              item.category == _selectedCategory;

      final bool searchMatches =
          query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.category
                  .toLowerCase()
                  .contains(query) ||
              item.unit.toLowerCase().contains(query) ||
              item.status.toLowerCase().contains(query);

      return statusMatches &&
          categoryMatches &&
          searchMatches;
    }).toList();

    switch (_sortMode) {
      case 'Lowest Stock':
        filtered.sort(
          (a, b) => a.qty.compareTo(b.qty),
        );
        break;
      case 'Needs Attention':
        filtered.sort(
          (a, b) => _statusRank(a.status)
              .compareTo(_statusRank(b.status)),
        );
        break;
      case 'Category':
        filtered.sort(
          (a, b) =>
              a.category.compareTo(b.category),
        );
        break;
      case 'Name':
      default:
        filtered.sort(
          (a, b) => a.name.compareTo(b.name),
        );
    }

    return filtered;
  }

  int _statusRank(String status) {
    switch (status) {
      case 'Missing':
        return 0;
      case 'Low':
        return 1;
      case 'Good':
      default:
        return 2;
    }
  }

  int _statusCount(String status) {
    return _items
        .where((item) => item.status == status)
        .length;
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('inventory_items')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildLoadError(snapshot.error);
        }

        if (!snapshot.hasData) {
          return _buildLoadingScreen();
        }

        _items = snapshot.data!.docs
            .map(_InvItem.fromDocument)
            .toList();

        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = 'All Categories';
        }

        final List<_InvItem> visible =
            _visibleItems;

        return Scaffold(
      backgroundColor: AT.background,
      appBar: AppBar(
        backgroundColor: AT.background,
        elevation: 0,
        title: const AdminPageHeader(
          title: 'Inventory',
          subtitle:
              'Track props, equipment, and supplies',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Inventory',
      ),
      floatingActionButton: _canAddOrEdit
          ? FloatingActionButton.small(
              backgroundColor: AT.gold,
              foregroundColor: Colors.black,
              elevation: 3,
              tooltip: 'Add inventory item',
              onPressed: _openAddItemSheet,
              child: const Icon(
                Icons.add_rounded,
                size: 20,
              ),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          color: AT.gold,
          backgroundColor: AT.card,
          onRefresh: () async {
            await FirebaseFirestore.instance
                .collection('inventory_items')
                .get();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              72,
            ),
            children: [
              _buildStats(),
              const SizedBox(height: 8),
              _buildSearchField(),
              const SizedBox(height: 8),
              _buildFilterBar(),
              const SizedBox(height: 8),
              _buildControlRow(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${visible.length} item'
                      '${visible.length == 1 ? '' : 's'}',
                      style: AT.body(
                        size: 12,
                        color: Colors.white,
                        w: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'Tap item for details',
                    style: AT.body(
                      size: 8.5,
                      color: AT.textFaint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (visible.isEmpty)
                _buildEmptyState()
              else
                ...visible.map(
                  _inventoryCard,
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
          title: 'Inventory',
          subtitle: 'Loading live inventory',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Inventory',
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
          title: 'Inventory',
          subtitle: 'Unable to load inventory',
        ),
      ),
      drawer: const AdminDrawer(
        current: 'Inventory',
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
              w: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          MiniStatCard(
            label: 'Total Items',
            value: '${_items.length}',
            sub: 'Tracked entries',
            icon: Icons.inventory_2_outlined,
            color: AT.info,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Low Stock',
            value: '${_statusCount('Low')}',
            sub: 'Needs attention',
            icon: Icons.warning_amber_outlined,
            color: AT.warn,
            valueColor: AT.warn,
          ),
          const SizedBox(width: 10),
          MiniStatCard(
            label: 'Missing / Out',
            value: '${_statusCount('Missing')}',
            sub: 'Replace immediately',
            icon: Icons.error_outline,
            color: AT.err,
            valueColor: AT.err,
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
            'Search item, category, unit, or status',
        hintStyle: AT.body(
          size: 10,
          color: AT.textFaint,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AT.gold,
          size: 17,
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
                  size: 17,
                ),
              ),
        filled: true,
        fillColor: AT.card,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
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

  Widget _buildFilterBar() {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final String filter = _filters[index];
          final bool active =
              _selectedFilter == filter;
          final int count = switch (filter) {
            'Good Condition' =>
              _statusCount('Good'),
            'Needs Attention' =>
              _statusCount('Low'),
            'Missing / Out' =>
              _statusCount('Missing'),
            _ => _items.length,
          };

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
                horizontal: 11,
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
                '$filter  $count',
                style: AT.body(
                  size: 8.6,
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

  Widget _buildControlRow() {
    return Row(
      children: [
        Expanded(
          child: _compactDropdown(
            value: _selectedCategory,
            icon: Icons.category_outlined,
            items: _categories,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedCategory = value;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _compactDropdown(
            value: _sortMode,
            icon: Icons.sort_rounded,
            items: const [
              'Name',
              'Category',
              'Lowest Stock',
              'Needs Attention',
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _sortMode = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _compactDropdown({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AT.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AT.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AT.card2,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AT.gold,
            size: 17,
          ),
          style: AT.body(
            size: 8.7,
            color: Colors.white,
            w: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: AT.gold,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _inventoryCard(_InvItem item) {
    final Color color =
        statusColor(item.status);
    final double level = item.min <= 0
        ? 1
        : (item.qty / item.min).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openItemDetails(item),
          borderRadius: BorderRadius.circular(9),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(
              9,
              8,
              8,
              8,
            ),
            decoration: BoxDecoration(
              color: AT.card,
              borderRadius:
                  BorderRadius.circular(9),
              border: Border.all(
                color: color.withOpacity(0.22),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            color.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _categoryIcon(item.category),
                        color: color,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: AT.body(
                              size: 9.8,
                              color: Colors.white,
                              w: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${item.category} · '
                            'Checked ${item.lastChecked}',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: AT.body(
                              size: 7.2,
                              color: AT.textFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.status,
                        style: AT.body(
                          size: 6.8,
                          color: color,
                          w: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${item.qty} ${item.unit}',
                              style: AT.body(
                                size: 11.8,
                                color: color,
                                w: FontWeight.w800,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '  / min ${item.min}',
                              style: AT.body(
                                size: 7.2,
                                color: AT.textFaint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _quantityButton(
                      icon: Icons.remove_rounded,
                      onTap: !_canAdjustStock || item.qty <= 0
                          ? null
                          : () => _changeQuantity(
                                item,
                                -1,
                              ),
                    ),
                    const SizedBox(width: 4),
                    _quantityButton(
                      icon: Icons.add_rounded,
                      onTap: _canAdjustStock
                          ? () => _changeQuantity(
                                item,
                                1,
                              )
                          : null,
                    ),
                    if (item.status != 'Good') ...[
                      const SizedBox(width: 5),
                      SizedBox(
                        height: 28,
                        child: TextButton(
                          onPressed: _canAdjustStock
                              ? () => _openRestockSheet(item)
                              : null,
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 7,
                            ),
                            foregroundColor:
                                item.status == 'Missing'
                                    ? AT.err
                                    : AT.gold,
                          ),
                          child: Text(
                            item.status == 'Missing'
                                ? 'Replace'
                                : 'Restock',
                            style: AT.body(
                              size: 7.5,
                              color:
                                  item.status == 'Missing'
                                      ? AT.err
                                      : AT.gold,
                              w: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: level,
                    minHeight: 3,
                    backgroundColor: AT.card2,
                    valueColor:
                        AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: 28,
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: AT.gold,
          disabledForegroundColor: AT.textFaint,
          side: const BorderSide(
            color: AT.border2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
        ),
        child: Icon(
          icon,
          size: 15,
        ),
      ),
    );
  }

  Future<void> _changeQuantity(
    _InvItem item,
    int change,
  ) async {
    if (!_canAdjustStock) {
      _showAccessDenied('Stock updates require team access.');
      return;
    }

    try {
      final DocumentReference<Map<String, dynamic>> reference =
          FirebaseFirestore.instance
              .collection('inventory_items')
              .doc(item.documentId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(reference);

          if (!snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Inventory item no longer exists.',
            );
          }

          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};

          final int current = _readInt(
            data['quantity'] ?? data['qty'],
          );
          final int minimum = _readInt(
            data['minimumQuantity'] ??
                data['minimum'] ??
                data['min'],
          );
          final int updated =
              (current + change).clamp(0, 999999).toInt();

          transaction.update(reference, {
            'quantity': updated,
            'status': _storedStatus(updated, minimum),
            'lastCheckedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showDatabaseError(
        'Stock update failed',
        error,
      );
    }
  }

  void _openItemDetails(_InvItem item) {
    final Color color =
        statusColor(item.status);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            18 +
                MediaQuery.of(context)
                    .viewPadding
                    .bottom,
          ),
          decoration: const BoxDecoration(
            color: AT.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 42,
                      decoration: BoxDecoration(
                        color:
                            color.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _categoryIcon(item.category),
                        color: color,
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
                            item.name,
                            style: AT.title(
                              size: 17,
                            ),
                          ),
                          const SizedBox(height: 5),
                          StatusBadge(
                            item.status,
                            color: color,
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
                const SizedBox(height: 12),
                _detailSection(
                  children: [
                    _detailRow(
                      'Category',
                      item.category,
                    ),
                    _detailRow(
                      'Current Stock',
                      '${item.qty} ${item.unit}',
                      valueColor: color,
                    ),
                    _detailRow(
                      'Minimum Stock',
                      '${item.min} ${item.unit}',
                    ),
                    _detailRow(
                      'Last Checked',
                      item.lastChecked,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _canAddOrEdit
                              ? () {
                                  Navigator.pop(
                                    sheetContext,
                                  );
                                  _openEditItemSheet(item);
                                }
                              : null,
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 17,
                          ),
                          label: Text(
                            'Edit Item',
                            style: AT.body(
                              size: 9.5,
                              color: Colors.white,
                              w: FontWeight.w700,
                            ),
                          ),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                Colors.white,
                            side: const BorderSide(
                              color: AT.border2,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _canAdjustStock
                              ? () {
                                  Navigator.pop(
                                    sheetContext,
                                  );
                                  _openRestockSheet(item);
                                }
                              : null,
                          icon: const Icon(
                            Icons.add_box_outlined,
                            size: 17,
                          ),
                          label: Text(
                            'Update Stock',
                            style: AT.body(
                              size: 9.5,
                              color: Colors.black,
                              w: FontWeight.w700,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: AT.gold,
                            foregroundColor:
                                Colors.black,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: _canDeleteItem
                        ? () async {
                            final bool confirmed =
                                await _confirmDeleteItem(item);

                            if (!confirmed) return;

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }

                            await _deleteItem(item);
                          }
                        : null,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 17,
                    ),
                    label: Text(
                      'Delete Item',
                      style: AT.body(
                        size: 9.5,
                        color: AT.err,
                        w: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AT.err,
                      side: const BorderSide(
                        color: AT.err,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailSection({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AT.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AT.border,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AT.body(
                size: 8.7,
                color: AT.textMuted,
                w: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AT.body(
                size: 9.5,
                color:
                    valueColor ?? Colors.white,
                w: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddItemSheet() async {
    if (!_canAddOrEdit) {
      _showAccessDenied('Adding items requires manager or owner access.');
      return;
    }

    await _openItemForm();
  }

  Future<void> _openEditItemSheet(
    _InvItem item,
  ) async {
    if (!_canAddOrEdit) {
      _showAccessDenied('Editing items requires manager or owner access.');
      return;
    }

    await _openItemForm(item: item);
  }

  Future<void> _openItemForm({
    _InvItem? item,
  }) async {
    if (!_canAddOrEdit) {
      _showAccessDenied('Item changes require manager or owner access.');
      return;
    }

    final GlobalKey<FormState> formKey =
        GlobalKey<FormState>();

    final TextEditingController nameController =
        TextEditingController(
      text: item?.name ?? '',
    );
    final TextEditingController quantityController =
        TextEditingController(
      text: item?.qty.toString() ?? '',
    );
    final TextEditingController minimumController =
        TextEditingController(
      text: item?.min.toString() ?? '',
    );
    String category =
        item?.category ?? 'Furniture';
    String unit = item?.unit ?? 'pcs';

    final bool? saved =
        await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(context).size.height *
                          0.9,
                ),
                decoration: const BoxDecoration(
                  color: AT.card,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: Form(
                  key: formKey,
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      24,
                    ),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius:
                                BorderRadius.circular(
                              4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item == null
                                  ? 'Add Inventory Item'
                                  : 'Edit Inventory Item',
                              style: AT.title(
                                size: 19,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(
                              sheetContext,
                              false,
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        controller: nameController,
                        label: 'ITEM NAME',
                        hint: 'Enter item name',
                        icon:
                            Icons.inventory_2_outlined,
                      ),
                      _formDropdown(
                        value: category,
                        label: 'CATEGORY',
                        icon: Icons.category_outlined,
                        items: const [
                          'Furniture',
                          'Tableware',
                          'Decor',
                          'Equipment',
                          'Supplies',
                          'Other',
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _formField(
                              controller:
                                  quantityController,
                              label: 'CURRENT STOCK',
                              hint: '0',
                              icon: Icons.numbers_outlined,
                              keyboardType:
                                  TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _formField(
                              controller:
                                  minimumController,
                              label: 'MINIMUM STOCK',
                              hint: '0',
                              icon:
                                  Icons.warning_amber_outlined,
                              keyboardType:
                                  TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      _formDropdown(
                        value: unit,
                        label: 'UNIT',
                        icon: Icons.straighten_outlined,
                        items: const [
                          'pcs',
                          'sets',
                          'unit',
                          'boxes',
                          'packs',
                          'meters',
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setSheetState(() {
                            unit = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!(formKey.currentState
                                    ?.validate() ??
                                false)) {
                              return;
                            }

                            final int quantity = int.parse(
                              quantityController.text.trim(),
                            );
                            final int minimum = int.parse(
                              minimumController.text.trim(),
                            );
                            final String name =
                                nameController.text.trim();

                            final Map<String, dynamic> data = {
                              'name': name,
                              'nameLower': name.toLowerCase(),
                              'category': category,
                              'quantity': quantity,
                              'minimumQuantity': minimum,
                              'unit': unit,
                              'status': _storedStatus(
                                quantity,
                                minimum,
                              ),
                              'lastCheckedAt':
                                  FieldValue.serverTimestamp(),
                              'updatedAt':
                                  FieldValue.serverTimestamp(),
                            };

                            try {
                              if (item == null) {
                                data['createdAt'] =
                                    FieldValue.serverTimestamp();

                                await FirebaseFirestore.instance
                                    .collection('inventory_items')
                                    .add(data);
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('inventory_items')
                                    .doc(item.documentId)
                                    .update(data);
                              }

                              if (!sheetContext.mounted) return;

                              Navigator.pop(
                                sheetContext,
                                true,
                              );
                            } on FirebaseException catch (error) {
                              if (!sheetContext.mounted) return;

                              ScaffoldMessenger.of(sheetContext)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Save failed: '
                                    '${error.message ?? error.code}',
                                  ),
                                  backgroundColor: AT.err,
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            item == null
                                ? Icons.add_rounded
                                : Icons.save_outlined,
                            size: 17,
                          ),
                          label: Text(
                            item == null
                                ? 'Add Item'
                                : 'Save Changes',
                            style: AT.body(
                              size: 10.5,
                              color: Colors.black,
                              w: FontWeight.w700,
                            ),
                          ),
                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor: AT.gold,
                            foregroundColor:
                                Colors.black,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    quantityController.dispose();
    minimumController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null
                ? 'Inventory item added.'
                : 'Inventory item updated.',
          ),
        ),
      );
    }
  }

  Future<void> _openRestockSheet(
    _InvItem item,
  ) async {
    if (!_canAdjustStock) {
      _showAccessDenied('Stock updates require team access.');
      return;
    }

    final TextEditingController controller =
        TextEditingController(
      text: item.min > item.qty
          ? '${item.min - item.qty}'
          : '1',
    );

    final int? amount =
        await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.74),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              24,
            ),
            decoration: const BoxDecoration(
              color: AT.card,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius:
                            BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Update ${item.name}',
                    style: AT.title(
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Current stock: ${item.qty} ${item.unit}',
                    style: AT.body(
                      size: 9.5,
                      color: AT.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _formField(
                    controller: controller,
                    label: 'QUANTITY TO ADD',
                    hint: 'Enter quantity',
                    icon: Icons.add_box_outlined,
                    keyboardType:
                        TextInputType.number,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final int? value =
                            int.tryParse(
                          controller.text.trim(),
                        );

                        if (value == null ||
                            value <= 0) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Enter valid quantity.',
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pop(
                          sheetContext,
                          value,
                        );
                      },
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 17,
                      ),
                      label: Text(
                        'Update Stock',
                        style: AT.body(
                          size: 10.5,
                          color: Colors.black,
                          w: FontWeight.w700,
                        ),
                      ),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor: AT.gold,
                        foregroundColor:
                            Colors.black,
                        elevation: 0,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    controller.dispose();

    if (amount == null) return;

    try {
      final DocumentReference<Map<String, dynamic>> reference =
          FirebaseFirestore.instance
              .collection('inventory_items')
              .doc(item.documentId);

      await FirebaseFirestore.instance.runTransaction(
        (transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(reference);

          if (!snapshot.exists) {
            throw FirebaseException(
              plugin: 'cloud_firestore',
              message: 'Inventory item no longer exists.',
            );
          }

          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};

          final int current = _readInt(
            data['quantity'] ?? data['qty'],
          );
          final int minimum = _readInt(
            data['minimumQuantity'] ??
                data['minimum'] ??
                data['min'],
          );
          final int updated = current + amount;

          transaction.update(reference, {
            'quantity': updated,
            'status': _storedStatus(updated, minimum),
            'lastCheckedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$amount ${item.unit} added.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showDatabaseError(
        'Restock failed',
        error,
      );
    }
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters:
            keyboardType == TextInputType.number
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                  ]
                : null,
        style: AT.body(
          size: 10.5,
          color: Colors.white,
        ),
        decoration: _inputDecoration(
          label: label,
          hint: hint,
          icon: icon,
        ),
        validator: (value) {
          final String text =
              value?.trim() ?? '';

          if (text.isEmpty) {
            return 'Required field.';
          }

          if (keyboardType ==
                  TextInputType.number &&
              int.tryParse(text) == null) {
            return 'Enter whole number.';
          }

          return null;
        },
      ),
    );
  }

  Widget _formDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AT.card2,
      style: AT.body(
        size: 10.5,
        color: Colors.white,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: label,
        icon: icon,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AT.gold,
        size: 17,
      ),
      labelStyle: AT.body(
        size: 8,
        color: AT.gold,
        w: FontWeight.w700,
      ),
      hintStyle: AT.body(
        size: 9.5,
        color: AT.textFaint,
      ),
      filled: true,
      fillColor: AT.card2,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AT.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AT.gold,
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AT.err,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AT.err,
          width: 1.2,
        ),
      ),
    );
  }

  Future<bool> _confirmDeleteItem(
    _InvItem item,
  ) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AT.card,
          title: const Text(
            'Delete inventory item?',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            '${item.name} will be permanently removed.',
            style: const TextStyle(
              color: AT.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
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

    return result ?? false;
  }

  Future<void> _deleteItem(
    _InvItem item,
  ) async {
    if (!_canDeleteItem) {
      _showAccessDenied('Deleting items requires owner access.');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inventory_items')
          .doc(item.documentId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Inventory item deleted.',
          ),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showDatabaseError(
        'Delete failed',
        error,
      );
    }
  }

  void _showDatabaseError(
    String title,
    FirebaseException error,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title: ${error.message ?? error.code}',
        ),
        backgroundColor: AT.err,
      ),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _storedStatus(
    int quantity,
    int minimum,
  ) {
    if (quantity <= 0) return 'missing';
    if (quantity < minimum) return 'low';
    return 'good';
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AT.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: AT.gold,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            'No inventory items found',
            style: AT.title(
              size: 17,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add first item using gold + button.',
            textAlign: TextAlign.center,
            style: AT.body(
              size: 9,
              color: AT.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Furniture':
        return Icons.chair_outlined;
      case 'Tableware':
        return Icons.dinner_dining_outlined;
      case 'Decor':
        return Icons.auto_awesome_outlined;
      case 'Equipment':
        return Icons.build_outlined;
      case 'Supplies':
        return Icons.inventory_outlined;
      default:
        return Icons.category_outlined;
    }
  }

}
