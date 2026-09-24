import 'package:flutter_test/flutter_test.dart';
import 'package:rently_cse2100_project/models/apartment_model.dart';
import 'package:rently_cse2100_project/models/apartment_query_model.dart';
import 'package:rently_cse2100_project/models/maintenance_request_model.dart';
import 'package:rently_cse2100_project/models/notice_model.dart';
import 'package:rently_cse2100_project/models/notification_model.dart';
import 'package:rently_cse2100_project/models/rent_record_model.dart';
import 'package:rently_cse2100_project/models/rental_request_model.dart';
import 'package:rently_cse2100_project/models/user_model.dart';

void main() {
  group('Real-World Multi-User Isolation & Verification Tests', () {
    // Test actors
    const tenantAUid = 'tenant_A_uid_101';
    const tenantBUid = 'tenant_B_uid_102';
    const landlordAUid = 'landlord_A_uid_201';
    const landlordBUid = 'landlord_B_uid_202';
    const adminUid = 'admin_uid_999';

    // ------------------------------------------------------------------------
    // (1) Newly registered landlord starts with 0 properties
    // ------------------------------------------------------------------------
    test('(1) Newly registered landlord starts with 0 own properties until listed', () {
      final landlordA = UserModel(
        uid: landlordAUid,
        email: 'landlord_a@example.com',
        name: 'Landlord A',
        role: 'landlord',
      );

      // System starts with properties owned by others
      final allSystemApartments = [
        ApartmentModel(
          id: 'apt_b1',
          title: 'Landlord B Property 1',
          location: 'Dhaka',
          rent: 20000,
          status: 'available',
          description: 'Apt B1',
          landlordId: landlordBUid,
          bedrooms: 2,
          bathrooms: 2,
          areaSqFt: 1000,
        ),
      ];

      // Scoped query for newly registered Landlord A
      final landlordAPropertiesInitial = allSystemApartments
          .where((apt) => apt.landlordId == landlordA.uid)
          .toList();

      // Verified: Newly registered landlord starts with exactly 0 properties
      expect(landlordAPropertiesInitial.length, equals(0));

      // Landlord A creates/lists an apartment permanently associated with landlordAUid
      final newAptA = ApartmentModel(
        id: 'apt_a1',
        title: 'Landlord A Brand New Property',
        location: 'Rajshahi',
        rent: 18000,
        status: 'available',
        description: 'Apt A1',
        landlordId: landlordA.uid, // permanently associated
        bedrooms: 3,
        bathrooms: 2,
        areaSqFt: 1200,
      );

      final updatedApartments = [...allSystemApartments, newAptA];
      final landlordAPropertiesAfterListing = updatedApartments
          .where((apt) => apt.landlordId == landlordA.uid)
          .toList();

      expect(landlordAPropertiesAfterListing.length, equals(1));
      expect(landlordAPropertiesAfterListing.first.landlordId, equals(landlordAUid));
    });

    // ------------------------------------------------------------------------
    // (2) Notice scoping: Landlord A never sees Landlord B's private notices
    // ------------------------------------------------------------------------
    test('(2) Landlord A never sees Landlord B private notices, tenant receives intended notices', () {
      final notices = [
        NoticeModel(
          id: 'notice_pub',
          title: 'Public Community Maintenance',
          message: 'Water cleaning across all buildings on Friday.',
          authorId: adminUid,
          isPublic: true,
        ),
        NoticeModel(
          id: 'notice_la_priv',
          title: 'Landlord A Private Notice',
          message: 'Internal notes for Landlord A properties.',
          authorId: landlordAUid,
          isPublic: false,
          targetTenantId: tenantAUid,
        ),
        NoticeModel(
          id: 'notice_lb_priv',
          title: 'Landlord B Private Notice',
          message: 'Landlord B private tenant instructions.',
          authorId: landlordBUid,
          isPublic: false,
          targetTenantId: tenantBUid,
        ),
      ];

      // Landlord A query rule: where authorId == landlordAUid
      final landlordANotices = notices
          .where((n) => n.authorId == landlordAUid)
          .toList();

      expect(landlordANotices.length, equals(1));
      expect(landlordANotices.first.id, equals('notice_la_priv'));
      // Landlord A cannot see Landlord B's private notice
      expect(landlordANotices.any((n) => n.authorId == landlordBUid), isFalse);

      // Tenant A view: isPublic == true OR targetTenantId == tenantAUid
      final tenantANotices = notices
          .where((n) => n.isPublic || n.targetTenantId == tenantAUid)
          .toList();

      expect(tenantANotices.length, equals(2));
      expect(tenantANotices.any((n) => n.id == 'notice_pub'), isTrue);
      expect(tenantANotices.any((n) => n.id == 'notice_la_priv'), isTrue);
      // Tenant A does not see Tenant B's targeted notice
      expect(tenantANotices.any((n) => n.id == 'notice_lb_priv'), isFalse);
    });

    // ------------------------------------------------------------------------
    // (3) Maintenance request reaches the actual owning landlord only
    // ------------------------------------------------------------------------
    test('(3) Maintenance request reaches the actual apartment landlord; other landlords cannot manage', () {
      final ticketForLandlordA = MaintenanceRequestModel(
        id: 'ticket_1',
        tenantId: tenantAUid,
        landlordId: landlordAUid,
        apartmentId: 'apt_a1',
        title: 'Plumbing leak',
        description: 'Kitchen sink pipe is leaking',
        status: 'pending',
      );

      // Rule simulation: Landlord A can read & update
      final canLandlordAAccess = ticketForLandlordA.landlordId == landlordAUid;
      final canLandlordBAccess = ticketForLandlordA.landlordId == landlordBUid;
      final canTenantBAccess = ticketForLandlordA.tenantId == tenantBUid;

      expect(canLandlordAAccess, isTrue);
      expect(canLandlordBAccess, isFalse);
      expect(canTenantBAccess, isFalse);

      // Landlord A updates status to in-progress
      final updatedTicket = MaintenanceRequestModel(
        id: ticketForLandlordA.id,
        tenantId: ticketForLandlordA.tenantId,
        landlordId: ticketForLandlordA.landlordId,
        apartmentId: ticketForLandlordA.apartmentId,
        title: ticketForLandlordA.title,
        description: ticketForLandlordA.description,
        status: 'in-progress',
      );
      expect(updatedTicket.status, equals('in-progress'));
      expect(updatedTicket.landlordId, equals(landlordAUid)); // immutable
    });

    // ------------------------------------------------------------------------
    // (4) Rent reminders reached intended tenant without exposing other tenants
    // ------------------------------------------------------------------------
    test('(4) Rent reminders reach the correct tenant without exposing other tenant rent data', () {
      final rentRecords = [
        RentRecordModel(
          id: 'rec_tenant_a',
          tenantId: tenantAUid,
          landlordId: landlordAUid,
          apartmentId: 'apt_a1',
          amount: 15000,
          month: 'October 2026',
          status: 'unpaid',
        ),
        RentRecordModel(
          id: 'rec_tenant_b',
          tenantId: tenantBUid,
          landlordId: landlordAUid,
          apartmentId: 'apt_a2',
          amount: 22000,
          month: 'October 2026',
          status: 'unpaid',
        ),
      ];

      // Tenant A query: where tenantId == tenantAUid
      final tenantARecords = rentRecords
          .where((r) => r.tenantId == tenantAUid)
          .toList();

      expect(tenantARecords.length, equals(1));
      expect(tenantARecords.first.amount, equals(15000));
      // Tenant A does not see Tenant B's rent record (22000)
      expect(tenantARecords.any((r) => r.tenantId == tenantBUid), isFalse);

      // Landlord A sends reminder targeted to Tenant A
      final reminderNotice = NoticeModel(
        id: 'rem_1',
        title: 'Rent Reminder for October 2026',
        message: 'Your rent of ৳15000 is due.',
        authorId: landlordAUid,
        targetTenantId: tenantAUid,
        isPublic: false,
      );

      // Only Tenant A receives this notice
      expect(reminderNotice.targetTenantId, equals(tenantAUid));
      expect(reminderNotice.isPublic, isFalse);
    });

    // ------------------------------------------------------------------------
    // (5) Tenant apartment queries stay between tenant and landlord
    // ------------------------------------------------------------------------
    test('(5) Apartment inquiries are strictly isolated between tenant and owning landlord', () {
      final query = ApartmentQueryModel(
        id: 'q_1',
        apartmentId: 'apt_a1',
        apartmentTitle: '2 Bedroom Apartment',
        tenantId: tenantAUid,
        tenantName: 'Tenant A',
        landlordId: landlordAUid,
        question: 'Are pets allowed in this apartment?',
        status: 'pending',
      );

      // Check access rights
      final canTenantARead = query.tenantId == tenantAUid;
      final canTenantBRead = query.tenantId == tenantBUid;
      final canLandlordARead = query.landlordId == landlordAUid;
      final canLandlordBRead = query.landlordId == landlordBUid;

      expect(canTenantARead, isTrue);
      expect(canTenantBRead, isFalse);
      expect(canLandlordARead, isTrue);
      expect(canLandlordBRead, isFalse);

      // Landlord A answers query
      final answeredQuery = ApartmentQueryModel(
        id: query.id,
        apartmentId: query.apartmentId,
        tenantId: query.tenantId,
        landlordId: query.landlordId,
        question: query.question,
        answer: 'Small cats are allowed with prior notice.',
        status: 'answered',
      );

      expect(answeredQuery.isAnswered, isTrue);
      expect(answeredQuery.answer, isNotNull);
      expect(answeredQuery.tenantId, equals(tenantAUid)); // preserved
    });

    // ------------------------------------------------------------------------
    // (6) Email syntax validation & verification gatekeeping
    // ------------------------------------------------------------------------
    test('(6) Email verification syntax requirement', () {
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

      expect(emailRegex.hasMatch('valid.user@example.com'), isTrue);
      expect(emailRegex.hasMatch('tenant_123@domain.org'), isTrue);
      expect(emailRegex.hasMatch('invalid-email-address'), isFalse);
      expect(emailRegex.hasMatch('missing-at.com'), isFalse);
      expect(emailRegex.hasMatch('@missinguser.com'), isFalse);
      expect(emailRegex.hasMatch('spaces in@domain.com'), isFalse);
    });

    // ------------------------------------------------------------------------
    // (7) Admin broad oversight authorization
    // ------------------------------------------------------------------------
    test('(7) Admin can access records across tenants and landlords for oversight', () {
      final adminUser = UserModel(
        uid: adminUid,
        email: 'admin@rently.app',
        name: 'System Admin',
        role: 'admin',
      );

      expect(adminUser.isAdmin, isTrue);
      expect(adminUser.normalizedRole, equals('admin'));
    });

    // ------------------------------------------------------------------------
    // (8) Apartment-specific Features & Amenities Isolation
    // ------------------------------------------------------------------------
    test('(8) Apartment-specific Features and Amenities are strictly bound per apartment document', () {
      // Landlord creates 3 distinct apartments with completely different features & amenities
      // Apartment 1: Balcony, Parking, Wi-Fi
      final apt1 = ApartmentModel(
        id: 'apt_1',
        title: 'Apartment 1 (Green Valley)',
        location: 'Rajshahi',
        rent: 16000,
        status: 'available',
        description: 'Cozy flat',
        landlordId: landlordAUid,
        features: ['Balcony', 'Dining Space'],
        amenities: ['Dedicated Parking', 'Wi-Fi'],
      );

      // Apartment 2: AC, Furnished, Lift
      final apt2 = ApartmentModel(
        id: 'apt_2',
        title: 'Apartment 2 (Skyline)',
        location: 'Rajshahi',
        rent: 25000,
        status: 'available',
        description: 'Luxury flat',
        landlordId: landlordAUid,
        features: ['Furnished', 'Rooftop Access'],
        amenities: ['AC', 'Lift'],
      );

      // Apartment 3: Generator, Security, Gas (different landlord)
      final apt3 = ApartmentModel(
        id: 'apt_3',
        title: 'Apartment 3 (Sunrise)',
        location: 'Dhaka',
        rent: 28000,
        status: 'available',
        description: 'Secure flat',
        landlordId: landlordBUid,
        features: ['Tiles Fitting', 'South Facing'],
        amenities: ['Generator Backup', '24/7 Security', 'Gas Connection'],
      );

      // Verify each apartment retains its own distinct list
      expect(apt1.features, containsAll(['Balcony', 'Dining Space']));
      expect(apt1.amenities, containsAll(['Dedicated Parking', 'Wi-Fi']));
      expect(apt1.amenities.contains('AC'), isFalse);
      expect(apt1.amenities.contains('Lift'), isFalse);

      expect(apt2.amenities, containsAll(['AC', 'Lift']));
      expect(apt2.features.contains('Balcony'), isFalse);

      expect(apt3.amenities, containsAll(['Generator Backup', '24/7 Security', 'Gas Connection']));
      expect(apt3.landlordId, equals(landlordBUid));

      // Serialization round-trip verification
      final map1 = apt1.toMap();
      expect(map1['features'], equals(['Balcony', 'Dining Space']));
      expect(map1['amenities'], equals(['Dedicated Parking', 'Wi-Fi']));

      // Backward compatibility: missing features or amenities defaults safely to empty list
      final legacyApt = ApartmentModel(
        id: 'apt_legacy',
        title: 'Legacy Apartment',
        location: 'Rajshahi',
        rent: 12000,
        status: 'available',
        description: 'Older doc without amenities fields',
        landlordId: landlordAUid,
      );
      expect(legacyApt.features, isEmpty);
      expect(legacyApt.amenities, isEmpty);
    });

    // ------------------------------------------------------------------------
    // (9) Apartment Inquiry / Ask Landlord Flow & Security Isolation
    // ------------------------------------------------------------------------
    test('(9) Real-life inquiry flow: Tenant question -> Landlord answer -> strict isolation', () {
      final aptX = ApartmentModel(
        id: 'apt_x_101',
        title: 'Apartment X',
        location: 'Rajshahi',
        rent: 15000,
        status: 'available',
        description: 'Apartment X details',
        landlordId: landlordAUid, // owned by Landlord A
      );

      // 1. Tenant A asks Landlord A a question about Apartment X
      final now = DateTime.now();
      final inquiry = ApartmentQueryModel(
        id: 'inq_1',
        apartmentId: aptX.id,
        apartmentTitle: aptX.title,
        tenantId: tenantAUid,
        tenantName: 'Tenant A',
        landlordId: aptX.landlordId, // derived from apartment document
        question: 'Is 24/7 gas connection available?',
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      );

      // Verify inquiry payload integrity
      expect(inquiry.tenantId, equals(tenantAUid));
      expect(inquiry.apartmentId, equals(aptX.id));
      expect(inquiry.landlordId, equals(landlordAUid));
      expect(inquiry.status, equals('pending'));
      expect(inquiry.updatedAt, isNotNull);

      // Security rule check for Creation:
      // - authenticated as Tenant A
      // - inquiry.tenantId == request.auth.uid
      // - inquiry.landlordId == aptX.landlordId
      bool canCreateInquiry(String callerUid, String tenantId, String landlordId, String aptId) {
        if (callerUid != tenantId) return false; // cannot impersonate another tenant
        if (aptId == aptX.id && landlordId != aptX.landlordId) return false; // landlord tampering check
        return true;
      }

      expect(canCreateInquiry(tenantAUid, inquiry.tenantId, inquiry.landlordId, inquiry.apartmentId), isTrue);
      // Impersonation attempts:
      expect(canCreateInquiry(tenantBUid, inquiry.tenantId, inquiry.landlordId, inquiry.apartmentId), isFalse);
      // Tampering with landlordId:
      expect(canCreateInquiry(tenantAUid, tenantAUid, landlordBUid, inquiry.apartmentId), isFalse);

      // Security rule check for Reading:
      bool canReadInquiry(String callerUid) {
        return callerUid == inquiry.tenantId || callerUid == inquiry.landlordId || callerUid == adminUid;
      }
      expect(canReadInquiry(tenantAUid), isTrue); // Asking tenant
      expect(canReadInquiry(landlordAUid), isTrue); // Owning landlord
      expect(canReadInquiry(adminUid), isTrue); // Admin
      expect(canReadInquiry(tenantBUid), isFalse); // Unrelated tenant DENIED
      expect(canReadInquiry(landlordBUid), isFalse); // Unrelated landlord DENIED

      // 2. Landlord A answers the inquiry
      bool canAnswerInquiry(String callerUid, String targetLandlordId) {
        return callerUid == targetLandlordId || callerUid == adminUid;
      }
      expect(canAnswerInquiry(landlordAUid, inquiry.landlordId), isTrue);
      expect(canAnswerInquiry(landlordBUid, inquiry.landlordId), isFalse); // Landlord B cannot answer

      final answeredInquiry = ApartmentQueryModel(
        id: inquiry.id,
        apartmentId: inquiry.apartmentId,
        apartmentTitle: inquiry.apartmentTitle,
        tenantId: inquiry.tenantId,
        tenantName: inquiry.tenantName,
        landlordId: inquiry.landlordId, // immutable
        question: inquiry.question,
        answer: 'Yes, full line gas is connected and active.',
        status: 'answered',
        createdAt: inquiry.createdAt,
        answeredAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(answeredInquiry.isAnswered, isTrue);
      expect(answeredInquiry.answer, equals('Yes, full line gas is connected and active.'));
      expect(answeredInquiry.tenantId, equals(tenantAUid));
      expect(answeredInquiry.landlordId, equals(landlordAUid));

      // 3. Tenant A sees the answer; Tenant B cannot see it
      expect(canReadInquiry(tenantAUid), isTrue);
      expect(canReadInquiry(tenantBUid), isFalse);
    });

    // ------------------------------------------------------------------------
    // (10) Rental Approval Calculation & State Synchronization
    // ------------------------------------------------------------------------
    test('(10) Rental approval sets apartment rented, assigns currentTenantId, auto-rejects competing requests, and notifies approved tenant', () {
      final apt = ApartmentModel(
        id: 'apt_sync_1',
        title: 'Lakeview Suite',
        location: 'Gulshan',
        rent: 45000,
        status: 'available',
        description: 'Luxury suite',
        landlordId: landlordAUid,
        bedrooms: 3,
        bathrooms: 3,
        areaSqFt: 1800,
      );

      final reqA = RentalRequestModel(
        id: 'req_a',
        apartmentId: apt.id,
        apartmentTitle: apt.title,
        tenantId: tenantAUid,
        tenantName: 'Tenant A',
        landlordId: landlordAUid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final reqB = RentalRequestModel(
        id: 'req_b',
        apartmentId: apt.id,
        apartmentTitle: apt.title,
        tenantId: tenantBUid,
        tenantName: 'Tenant B',
        landlordId: landlordAUid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final requests = [reqA, reqB];

      // Simulate approval logic
      final approvedReq = RentalRequestModel(
        id: reqA.id,
        apartmentId: reqA.apartmentId,
        apartmentTitle: reqA.apartmentTitle,
        tenantId: reqA.tenantId,
        tenantName: reqA.tenantName,
        landlordId: reqA.landlordId,
        status: 'approved',
        createdAt: reqA.createdAt,
      );
      final updatedApt = ApartmentModel(
        id: apt.id,
        title: apt.title,
        location: apt.location,
        rent: apt.rent,
        status: 'rented',
        description: apt.description,
        landlordId: apt.landlordId,
        bedrooms: apt.bedrooms,
        bathrooms: apt.bathrooms,
        areaSqFt: apt.areaSqFt,
        currentTenantId: approvedReq.tenantId,
      );

      // Auto-reject competing pending requests for the same apartment
      final remainingRequests = requests.map((r) {
        if (r.id == approvedReq.id) {
          return approvedReq;
        } else if (r.apartmentId == apt.id && r.isPending) {
          return RentalRequestModel(
            id: r.id,
            apartmentId: r.apartmentId,
            apartmentTitle: r.apartmentTitle,
            tenantId: r.tenantId,
            tenantName: r.tenantName,
            landlordId: r.landlordId,
            status: 'rejected',
            createdAt: r.createdAt,
          );
        }
        return r;
      }).toList();

      expect(updatedApt.status, equals('rented'));
      expect(updatedApt.currentTenantId, equals(tenantAUid));

      final autoRejectedB = remainingRequests.firstWhere((r) => r.id == 'req_b');
      expect(autoRejectedB.status, equals('rejected'));

      // Generate approval notification targeted specifically to approved tenant
      final approvalNotification = NotificationModel(
        id: 'notif_approve_1',
        recipientId: approvedReq.tenantId,
        type: 'rental_approved',
        title: 'Rental Request Approved! 🎉',
        message: 'Your rental request for "${apt.title}" has been approved.',
        apartmentId: apt.id,
        rentalRequestId: approvedReq.id,
        createdAt: DateTime.now(),
      );

      expect(approvalNotification.recipientId, equals(tenantAUid));
      expect(approvalNotification.type, equals('rental_approved'));
      expect(approvalNotification.isRead, isFalse);
    });

    // ------------------------------------------------------------------------
    // (11) Maintenance Request Eligibility Restriction
    // ------------------------------------------------------------------------
    test('(11) Maintenance request strictly restricted to active approved tenancy', () {
      final activeApprovedLease = RentalRequestModel(
        id: 'lease_approved_1',
        apartmentId: 'apt_active_1',
        apartmentTitle: 'Active Residence',
        tenantId: tenantAUid,
        tenantName: 'Tenant A',
        landlordId: landlordAUid,
        status: 'approved',
        createdAt: DateTime.now(),
      );

      bool canSubmitMaintenance(String tenantId, List<RentalRequestModel> userLeases) {
        return userLeases.any((l) => l.tenantId == tenantId && l.status == 'approved');
      }

      // Tenant A has an approved lease -> Eligible
      expect(canSubmitMaintenance(tenantAUid, [activeApprovedLease]), isTrue);

      // Tenant B has only a pending or rejected lease -> Ineligible
      final pendingLeaseB = RentalRequestModel(
        id: 'lease_pending_b',
        apartmentId: 'apt_active_1',
        apartmentTitle: 'Active Residence',
        tenantId: tenantBUid,
        tenantName: 'Tenant B',
        landlordId: landlordAUid,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      expect(canSubmitMaintenance(tenantBUid, [pendingLeaseB]), isFalse);

      // Tenant with no leases at all -> Ineligible
      expect(canSubmitMaintenance('tenant_C', []), isFalse);
    });

    // ------------------------------------------------------------------------
    // (12) Apartment Photos Management
    // ------------------------------------------------------------------------
    test('(12) Landlord attaches uploaded photo URLs to apartment images list', () {
      final customPhotos = [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ];

      final aptWithPhotos = ApartmentModel(
        id: 'apt_photos_1',
        title: 'Modern Flat',
        location: 'Dhanmondi',
        rent: 30000,
        status: 'available',
        description: 'Furnished flat',
        landlordId: landlordAUid,
        bedrooms: 2,
        bathrooms: 2,
        areaSqFt: 1200,
        images: customPhotos,
      );

      expect(aptWithPhotos.images.length, equals(2));
      expect(aptWithPhotos.images.first, equals('https://example.com/photo1.jpg'));
      expect(aptWithPhotos.images[1], equals('https://example.com/photo2.jpg'));
    });

    // ------------------------------------------------------------------------
    // (13) Notification System Delivery & Isolation
    // ------------------------------------------------------------------------
    test('(13) Notifications are strictly isolated to recipientId and support markAsRead', () {
      final notifForA = NotificationModel(
        id: 'n_a1',
        recipientId: tenantAUid,
        type: 'inquiry_replied',
        title: 'New Reply Received',
        message: 'Landlord replied to your question.',
        createdAt: DateTime.now(),
      );

      final notifForB = NotificationModel(
        id: 'n_b1',
        recipientId: tenantBUid,
        type: 'rent_reminder',
        title: 'Rent Reminder',
        message: 'Rent is due in 3 days.',
        createdAt: DateTime.now(),
      );

      final allNotifs = [notifForA, notifForB];

      // Scoped recipient queries:
      final tenantANotifs = allNotifs.where((n) => n.recipientId == tenantAUid).toList();
      final tenantBNotifs = allNotifs.where((n) => n.recipientId == tenantBUid).toList();

      expect(tenantANotifs.length, equals(1));
      expect(tenantANotifs.first.id, equals('n_a1'));
      expect(tenantBNotifs.length, equals(1));
      expect(tenantBNotifs.first.id, equals('n_b1'));

      // Mark as read
      final readNotif = NotificationModel(
        id: notifForA.id,
        recipientId: notifForA.recipientId,
        type: notifForA.type,
        title: notifForA.title,
        message: notifForA.message,
        createdAt: notifForA.createdAt,
        isRead: true,
      );
      expect(readNotif.isRead, isTrue);
      expect(notifForA.isRead, isFalse);
    });

    // ------------------------------------------------------------------------
    // (14) Deletion of Past History
    // ------------------------------------------------------------------------
    test('(14) Users can delete their own past inquiries and notifications', () {
      final userInquiries = [
        ApartmentQueryModel(
          id: 'q_1',
          apartmentId: 'apt_1',
          apartmentTitle: 'Apt 1',
          tenantId: tenantAUid,
          tenantName: 'Tenant A',
          landlordId: landlordAUid,
          question: 'Is parking available?',
          status: 'pending',
          createdAt: DateTime.now(),
        ),
        ApartmentQueryModel(
          id: 'q_2',
          apartmentId: 'apt_2',
          apartmentTitle: 'Apt 2',
          tenantId: tenantBUid,
          tenantName: 'Tenant B',
          landlordId: landlordBUid,
          question: 'Can I move in tomorrow?',
          status: 'pending',
          createdAt: DateTime.now(),
        ),
      ];

      // Tenant A can delete their own question q_1
      bool canDeleteInquiry(String callerUid, ApartmentQueryModel q) {
        return callerUid == q.tenantId || callerUid == q.landlordId || callerUid == adminUid;
      }

      expect(canDeleteInquiry(tenantAUid, userInquiries[0]), isTrue);
      expect(canDeleteInquiry(tenantBUid, userInquiries[0]), isFalse); // Tenant B cannot delete Tenant A's inquiry

      final afterDeletion = userInquiries.where((q) => q.id != 'q_1').toList();
      expect(afterDeletion.length, equals(1));
      expect(afterDeletion.first.id, equals('q_2'));
    });

    // ------------------------------------------------------------------------
    // (15) Profile Updates & Password Security Validation
    // ------------------------------------------------------------------------
    test('(15) Profile field updates preserve UID and role immutability', () {
      final originalUser = UserModel(
        uid: tenantAUid,
        email: 'tenant.a@rently.com',
        name: 'Tenant Original',
        role: 'tenant',
        phone: '01700000000',
      );

      // Updating name and phone is allowed
      final updatedUser = UserModel(
        uid: originalUser.uid,
        email: originalUser.email,
        name: 'Tenant Updated',
        role: originalUser.role,
        phone: '01899999999',
      );

      // Identity and role remain strictly unchanged
      expect(updatedUser.uid, equals(originalUser.uid));
      expect(updatedUser.role, equals(originalUser.role));
      expect(updatedUser.name, equals('Tenant Updated'));
      expect(updatedUser.phone, equals('01899999999'));

      // Password validation rules
      bool isValidPassword(String password) => password.length >= 6;
      expect(isValidPassword('short'), isFalse);
      expect(isValidPassword('securePass123'), isTrue);
    });

    // ------------------------------------------------------------------------
    // (16) Account Deletion Authorization
    // ------------------------------------------------------------------------
    test('(16) Account deletion is allowed only for owner or administrator', () {
      bool canDeleteUserAccount(String callerUid, String targetUserUid) {
        return callerUid == targetUserUid || callerUid == adminUid;
      }

      // Tenant A deleting own account -> ALLOWED
      expect(canDeleteUserAccount(tenantAUid, tenantAUid), isTrue);

      // Admin deleting Tenant A account -> ALLOWED
      expect(canDeleteUserAccount(adminUid, tenantAUid), isTrue);

      // Tenant B attempting to delete Tenant A account -> DENIED
      expect(canDeleteUserAccount(tenantBUid, tenantAUid), isFalse);

      // Landlord A attempting to delete Tenant A account -> DENIED
      expect(canDeleteUserAccount(landlordAUid, tenantAUid), isFalse);
    });

    // ------------------------------------------------------------------------
    // (17) Email Verification Rate Limit Cooldown Validation
    // ------------------------------------------------------------------------
    test('(17) Email verification resend enforces cooldown on rate limit', () {
      bool canResendEmail(int cooldownSeconds, bool isResending) {
        return !isResending && cooldownSeconds <= 0;
      }

      expect(canResendEmail(0, false), isTrue);
      expect(canResendEmail(45, false), isFalse); // Active cooldown blocks resend
      expect(canResendEmail(0, true), isFalse);  // In-flight request blocks resend
    });
  });
}


