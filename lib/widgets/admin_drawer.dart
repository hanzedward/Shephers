import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/catering_requests_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/event_place_screen.dart';
import '../screens/inquiries_display_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/schedules_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/admin_theme.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.current,
  });

  final String current;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 300,
      backgroundColor: AT.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: Text(
                      'MANAGEMENT',
                      style: TextStyle(
                        color: AT.textFaint,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  _item(
                    context,
                    title: 'Dashboard',
                    subtitle: 'System overview',
                    icon: Icons.dashboard_outlined,
                    screen: const DashboardScreen(),
                  ),
                  _item(
                    context,
                    title: 'Catering Requests',
                    subtitle: 'Review catering bookings',
                    icon: Icons.room_service_outlined,
                    screen: const CateringRequestsScreen(),
                  ),
                  _item(
                    context,
                    title: 'Event Place',
                    subtitle: 'Venue reservations',
                    icon: Icons.apartment_outlined,
                    screen: const EventPlaceScreen(),
                  ),
                  _item(
                    context,
                    title: 'Inquiries',
                    subtitle: 'Customer messages',
                    icon: Icons.mark_email_unread_outlined,
                    screen: const InquiriesDisplayScreen(),
                  ),
                  _item(
                    context,
                    title: 'Schedules',
                    subtitle: 'Events and preparation',
                    icon: Icons.calendar_month_outlined,
                    screen: const SchedulesScreen(),
                  ),
                  _item(
                    context,
                    title: 'Inventory',
                    subtitle: 'Equipment and supplies',
                    icon: Icons.inventory_2_outlined,
                    screen: const InventoryScreen(),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AT.border),
                  const SizedBox(height: 6),
                  _item(
                    context,
                    title: 'Settings',
                    subtitle: 'Account preferences',
                    icon: Icons.settings_outlined,
                    screen: const SettingsScreen(),
                  ),
                ],
              ),
            ),
            _buildExitButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user == null
          ? null
          : FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ?? <String, dynamic>{};

        final String name =
            (data['name'] ?? 'Team Member').toString().trim();
        final String role =
            (data['role'] ?? 'staff').toString().trim().toLowerCase();

        final String roleLabel = role == 'owner'
            ? 'OWNER PORTAL'
            : role == 'manager'
                ? 'MANAGER PORTAL'
                : 'STAFF PORTAL';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 17),
          decoration: const BoxDecoration(
            color: AT.card,
            border: Border(
              bottom: BorderSide(color: AT.border),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AT.gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AT.gold.withOpacity(0.4),
                  ),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AT.gold,
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Team Member' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      roleLabel,
                      style: AT.body(
                        size: 7.5,
                        color: AT.gold,
                        w: FontWeight.w700,
                      ).copyWith(letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: AT.textMuted,
                ),
                tooltip: 'Close menu',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    final bool selected = current == title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AT.gold.withOpacity(0.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            final NavigatorState navigator =
                Navigator.of(context);

            navigator.pop();

            if (selected) return;

            navigator.pushReplacement(
              MaterialPageRoute(
                builder: (_) => screen,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? AT.gold.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: selected
                        ? AT.gold
                        : AT.card,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? Colors.black
                        : AT.gold,
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
                        style: AT.body(
                          size: 11,
                          color: selected
                              ? AT.gold
                              : Colors.white,
                          w: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AT.body(
                          size: 8.5,
                          color: AT.textFaint,
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
                      ? AT.gold
                      : AT.textFaint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExitButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AT.border),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();

            if (!context.mounted) return;

            Navigator.of(context).popUntil(
              (route) => route.isFirst,
            );
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Logout to Customer App'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AT.err,
            side: const BorderSide(color: AT.err),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
