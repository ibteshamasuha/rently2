import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import 'explore_apartments_screen.dart';
import 'my_rental_requests_screen.dart';
import 'tenant_maintenance_screen.dart';
import 'tenant_notices_screen.dart';
import 'tenant_rent_records_screen.dart';

class TenantMainScreen extends StatefulWidget {
  final UserModel currentUser;

  const TenantMainScreen({super.key, required this.currentUser});

  @override
  State<TenantMainScreen> createState() => _TenantMainScreenState();
}

class _TenantMainScreenState extends State<TenantMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ExploreApartmentsScreen(
        currentUser: widget.currentUser,
        onTabSelected: (idx) => setState(() => _currentIndex = idx),
      ),
      MyRentalRequestsScreen(currentUser: widget.currentUser),
      TenantMaintenanceScreen(currentUser: widget.currentUser),
      TenantRentRecordsScreen(currentUser: widget.currentUser),
      const TenantNoticesScreen(),
      ProfileScreen(user: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const primaryDark = Color(0xFF38454D); // Midnight Blue N480-7

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            indicatorColor: primaryDark,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today_rounded, color: Colors.white),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.build_outlined),
                selectedIcon: Icon(Icons.build_rounded, color: Colors.white),
                label: 'Repairs',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: Colors.white),
                label: 'Rent',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign_rounded, color: Colors.white),
                label: 'Notices',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: Colors.white),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
