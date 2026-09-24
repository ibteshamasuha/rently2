import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import 'explore_apartments_screen.dart';
import 'my_rental_requests_screen.dart';
import 'tenant_notices_screen.dart';

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
      ExploreApartmentsScreen(currentUser: widget.currentUser),
      MyRentalRequestsScreen(currentUser: widget.currentUser),
      TenantNoticesScreen(currentUser: widget.currentUser),
      ProfileScreen(user: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: GenXPalette.cameoWhite, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            elevation: 0,
            backgroundColor: Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            indicatorColor: GenXPalette.midnightBlue,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded, color: Colors.white),
                label: 'Requests',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded, color: Colors.white),
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
