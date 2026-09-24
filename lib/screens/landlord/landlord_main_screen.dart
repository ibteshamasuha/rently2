import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import 'landlord_home_screen.dart';
import 'landlord_notices_screen.dart';
import 'landlord_requests_screen.dart';
import 'my_apartments_screen.dart';
import '../../widgets/in_app_notification_popup.dart';

class LandlordMainScreen extends StatefulWidget {
  final UserModel currentUser;

  const LandlordMainScreen({super.key, required this.currentUser});

  @override
  State<LandlordMainScreen> createState() => _LandlordMainScreenState();
}

class _LandlordMainScreenState extends State<LandlordMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      LandlordHomeScreen(
        currentUser: widget.currentUser,
        onNavigateTab: (idx) => setState(() => _currentIndex = idx),
      ),
      MyApartmentsScreen(currentUser: widget.currentUser),
      LandlordRequestsScreen(currentUser: widget.currentUser),
      LandlordNoticesScreen(currentUser: widget.currentUser),
      ProfileScreen(user: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InAppNotificationPopup(
      currentUser: widget.currentUser,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: GenXPalette.cameoWhite, width: 1)),
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
                icon: Icon(Icons.apartment_outlined),
                selectedIcon: Icon(Icons.apartment_rounded, color: Colors.white),
                label: 'Properties',
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
    ),
  );
}
}
