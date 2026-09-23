import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import 'landlord_maintenance_screen.dart';
import 'landlord_notices_screen.dart';
import 'landlord_rent_records_screen.dart';
import 'landlord_requests_screen.dart';
import 'my_apartments_screen.dart';

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
      MyApartmentsScreen(currentUser: widget.currentUser),
      LandlordRequestsScreen(currentUser: widget.currentUser),
      LandlordMaintenanceScreen(currentUser: widget.currentUser),
      LandlordRentRecordsScreen(currentUser: widget.currentUser),
      LandlordNoticesScreen(currentUser: widget.currentUser),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Properties',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle),
            label: 'Repairs',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Rent Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
