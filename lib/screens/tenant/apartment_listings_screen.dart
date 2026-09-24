import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/apartment_model.dart';
import '../../models/user_model.dart';
import '../../services/apartment_service.dart';
import '../../theme/app_theme.dart';
import 'apartment_details_screen.dart';

class ApartmentListingsScreen extends StatefulWidget {
  final UserModel currentUser;

  const ApartmentListingsScreen({super.key, required this.currentUser});

  @override
  State<ApartmentListingsScreen> createState() => _ApartmentListingsScreenState();
}

class _ApartmentListingsScreenState extends State<ApartmentListingsScreen> {
  final _apartmentService = ApartmentService();
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 0);

  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Available', 'Rented'
  final Set<String> _favoriteIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      appBar: AppBar(
        title: const Text('Apartments'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar (Screen 8)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: GenXPalette.cameoWhite),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search by location, price...',
                  hintStyle: const TextStyle(color: GenXPalette.textMuted, fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: GenXPalette.textMuted, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                ),
              ),
            ),
          ),

          // Filter Chips: [All], [Available], [Rented] (Screen 8)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Available'),
                const SizedBox(width: 8),
                _buildFilterChip('Rented'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Stream of Apartments
          Expanded(
            child: StreamBuilder<List<ApartmentModel>>(
              stream: _apartmentService.getAllApartments(),
              builder: (context, snapshot) {
                final apartments = snapshot.data ?? [];

                // Apply Search & Filter
                final filtered = apartments.where((apt) {
                  final matchQuery = apt.title.toLowerCase().contains(_searchQuery) ||
                      apt.location.toLowerCase().contains(_searchQuery) ||
                      apt.rent.toString().contains(_searchQuery);
                  if (!matchQuery) return false;

                  if (_selectedFilter == 'Available') return apt.isAvailable;
                  if (_selectedFilter == 'Rented') return apt.isRented || apt.isPending;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off_rounded, size: 48, color: GenXPalette.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No apartments match your search',
                          style: TextStyle(color: GenXPalette.textMuted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final apt = filtered[index];
                    return _buildApartmentCard(apt);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GenXPalette.midnightBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GenXPalette.midnightBlue : GenXPalette.cameoWhite,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : GenXPalette.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildApartmentCard(ApartmentModel apt) {
    final photo = apt.images.isNotEmpty ? apt.images.first : null;
    final isFav = _favoriteIds.contains(apt.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GenXPalette.cameoWhite),
        boxShadow: [
          BoxShadow(
            color: GenXPalette.midnightBlue.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApartmentDetailsScreen(
                apartment: apt,
                currentUser: widget.currentUser,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo on left
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: photo != null
                    ? Image.network(
                        photo,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 96,
                          height: 96,
                          color: GenXPalette.cameoWhite,
                          child: const Icon(Icons.apartment_rounded, color: GenXPalette.midnightBlue),
                        ),
                      )
                    : Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: GenXPalette.midnightBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.apartment_rounded, size: 36, color: GenXPalette.midnightBlue),
                      ),
              ),

              const SizedBox(width: 14),

              // Details on right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            apt.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: GenXPalette.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status badge (Available/Pending)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: apt.isAvailable
                                ? GenXPalette.vineLeaf.withValues(alpha: 0.12)
                                : GenXPalette.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            apt.isAvailable ? 'Available' : 'Pending',
                            style: TextStyle(
                              color: apt.isAvailable ? GenXPalette.vineLeaf : GenXPalette.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: GenXPalette.textMuted),
                        const SizedBox(width: 2),
                        Text(
                          apt.location,
                          style: const TextStyle(fontSize: 12, color: GenXPalette.textMuted),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Price
                    Text(
                      '${_currencyFormat.format(apt.rent)} / month',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: GenXPalette.midnightBlue,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Specs row + favorite heart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bed_outlined, size: 14, color: GenXPalette.textMuted),
                            const SizedBox(width: 3),
                            Text('${apt.bedrooms}', style: const TextStyle(fontSize: 11.5, color: GenXPalette.textMuted)),
                            const SizedBox(width: 8),
                            const Icon(Icons.shower_outlined, size: 14, color: GenXPalette.textMuted),
                            const SizedBox(width: 3),
                            Text('${apt.bathrooms}', style: const TextStyle(fontSize: 11.5, color: GenXPalette.textMuted)),
                            const SizedBox(width: 8),
                            const Icon(Icons.crop_square_rounded, size: 14, color: GenXPalette.textMuted),
                            const SizedBox(width: 3),
                            Text('${apt.areaSqFt} sq ft', style: const TextStyle(fontSize: 11.5, color: GenXPalette.textMuted)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFav) {
                                _favoriteIds.remove(apt.id);
                              } else {
                                _favoriteIds.add(apt.id);
                              }
                            });
                          },
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav ? Colors.red : GenXPalette.textMuted,
                          ),
                        ),
                      ],
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
}
