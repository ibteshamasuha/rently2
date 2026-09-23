import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/rental_request_model.dart';
import '../../models/user_model.dart';
import '../../services/rental_request_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class MyRentalRequestsScreen extends StatelessWidget {
  final UserModel currentUser;

  const MyRentalRequestsScreen({super.key, required this.currentUser});

  Widget _buildImageWithFallback(String? url, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    const fallbackColors = [Color(0xFF2C3E2D), Color(0xFF1B281C)];
    if (url == null || url.isEmpty) {
      return Container(
        height: height,
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: fallbackColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: const Center(
          child: Icon(Icons.home_work_rounded, color: Colors.white54, size: 28),
        ),
      );
    }

    return Image.network(
      url,
      height: height,
      width: width,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: height,
          width: width,
          color: const Color(0xFFECEAE5),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D2330)),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: fallbackColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: const Center(
            child: Icon(Icons.apartment_rounded, color: Colors.white60, size: 28),
          ),
        );
      },
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.headset_mic_rounded, color: Color(0xFF1D2330)),
            SizedBox(width: 8),
            Text('Support Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Our team is ready to help you with your rental applications and bookings.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF555953)),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 16, color: Color(0xFF1D2330)),
                SizedBox(width: 8),
                Text('support@rently.app', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 16, color: Color(0xFF1D2330)),
                SizedBox(width: 8),
                Text('+880 1700-000000', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF1D2330), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRequestDetailsModal(BuildContext context, RentalRequestModel req) {
    final dateStr = req.createdAt != null
        ? DateFormat('MMMM d, y • h:mm a').format(req.createdAt!)
        : 'Recent';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      req.apartmentTitle ?? 'Apartment #${req.apartmentId}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: req.status),
                ],
              ),
              const SizedBox(height: 12),
              Text('Submitted: $dateStr', style: const TextStyle(fontSize: 13, color: Color(0xFF7A7E79))),
              const SizedBox(height: 8),
              Text('Landlord ID: ${req.landlordId}', style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79))),
              if (req.message != null && req.message!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFECEAE5)),
                  ),
                  child: Text(
                    'Note: "${req.message}"',
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF1A1D1A)),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D2330),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestService = RentalRequestService();
    final firstName = currentUser.name.trim().isNotEmpty
        ? currentUser.name.trim().split(' ').first
        : 'Alex';

    const thumbnailSample1 =
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=400&q=80';
    const thumbnailSample2 =
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=400&q=80';
    const thumbnailSample3 =
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=400&q=80';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header matching Screen 3: Back, More options, Avatar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    if (Navigator.canPop(context))
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFECEAE5)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF1A1D1A)),
                        ),
                      )
                    else
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFECEAE5)),
                        ),
                        child: const Icon(Icons.bookmark_outline_rounded, size: 20, color: Color(0xFF1D2330)),
                      ),
                    const Spacer(),
                    // Options button (...)
                    InkWell(
                      onTap: () => _showSupportDialog(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFECEAE5)),
                        ),
                        child: const Icon(Icons.more_horiz_rounded, size: 20, color: Color(0xFF1A1D1A)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // User Avatar
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D2330),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Text(
                  'My Bookings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1A),
                    letterSpacing: -0.4,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Stream of Rental Requests
              StreamBuilder<List<RentalRequestModel>>(
                stream: requestService.getTenantRequests(currentUser.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF1D2330)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Center(
                        child: Text(
                          'Error loading bookings: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  final requests = snapshot.data ?? [];

                  if (requests.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Column(
                        children: [
                          const EmptyStateWidget(
                            icon: Icons.calendar_month_outlined,
                            title: 'No Bookings Yet',
                            message: 'You have not submitted any rental applications yet. Explore our listings to book visits or rent.',
                          ),
                          const SizedBox(height: 20),
                          _buildNeedHelpCard(context),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  }

                  // First request is displayed in the Upcoming featured card
                  final upcomingReq = requests.first;
                  final pastRequests = requests.length > 1 ? requests.sublist(1) : <RentalRequestModel>[];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Upcoming" Section Title
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                        child: Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Upcoming Card (matching Screen 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildUpcomingCard(context, upcomingReq, thumbnailSample1),
                      ),

                      const SizedBox(height: 24),

                      // "Past Bookings" Section Title
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                        child: Text(
                          'Past Bookings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1D1A),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Past Bookings List
                      if (pastRequests.isNotEmpty)
                        ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pastRequests.length,
                          itemBuilder: (context, index) {
                            final req = pastRequests[index];
                            final thumb = index.isEven ? thumbnailSample2 : thumbnailSample3;
                            return _buildPastBookingCard(context, req, thumb);
                          },
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: _buildSamplePastBooking(
                            context,
                            title: 'Skyline Apartment Downtown',
                            date: '10 May 2024',
                            time: '11:00 AM',
                            imageUrl: thumbnailSample2,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // "Need Help?" Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: _buildNeedHelpCard(context),
                      ),

                      const SizedBox(height: 36),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Upcoming featured card matching Screen 3
  Widget _buildUpcomingCard(BuildContext context, RentalRequestModel req, String imageUrl) {
    final dateStr = req.createdAt != null
        ? DateFormat('d MMM yyyy, E').format(req.createdAt!)
        : '21 May 2024, Tue';
    final timeStr = req.createdAt != null
        ? DateFormat('hh:mm a').format(req.createdAt!)
        : '12:00 PM';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFE9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Thumbnail
            Container(
              height: 105,
              width: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageWithFallback(imageUrl),
            ),
            const SizedBox(width: 14),

            // Right Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge on top
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      StatusBadge(status: req.status.isNotEmpty ? req.status : 'Upcoming'),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    req.apartmentTitle ?? 'Modern Villa in Beverly Hills',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF7A7E79)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Time
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF7A7E79)),
                      const SizedBox(width: 5),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // View Details link
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => _showRequestDetailsModal(context, req),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D2330),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF1D2330)),
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
    );
  }

  // Past Booking Card from real data
  Widget _buildPastBookingCard(BuildContext context, RentalRequestModel req, String imageUrl) {
    final dateStr = req.createdAt != null
        ? DateFormat('d MMM yyyy').format(req.createdAt!)
        : 'Past booking';
    final timeStr = req.createdAt != null
        ? DateFormat('hh:mm a').format(req.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFE9)),
      ),
      child: InkWell(
        onTap: () => _showRequestDetailsModal(context, req),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImageWithFallback(imageUrl),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.apartmentTitle ?? 'Apartment #${req.apartmentId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF7A7E79)),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79)),
                        ),
                      ],
                    ),
                    if (timeStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF7A7E79)),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8E89), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Graceful sample past booking when only 1 active booking exists
  Widget _buildSamplePastBooking(
    BuildContext context, {
    required String title,
    required String date,
    required String time,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFE9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImageWithFallback(imageUrl),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF7A7E79)),
                      const SizedBox(width: 4),
                      Text(date, style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79))),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF7A7E79)),
                      const SizedBox(width: 4),
                      Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF7A7E79))),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A8E89), size: 20),
          ],
        ),
      ),
    );
  }

  // "Need Help?" Card matching Screen 3 bottom card
  Widget _buildNeedHelpCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E5DD)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D1A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Our support team is here to assist you with your queries.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _showSupportDialog(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFDDD9D0)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Headset Icon inside rounded card
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.headset_mic_outlined, size: 26, color: Color(0xFF1A1D1A)),
          ),
        ],
      ),
    );
  }
}
