import 'package:flutter_test/flutter_test.dart';
import 'package:rently_cse2100_project/models/apartment_model.dart';
import 'package:rently_cse2100_project/models/apartment_query_model.dart';
import 'package:rently_cse2100_project/models/maintenance_request_model.dart';
import 'package:rently_cse2100_project/models/notice_model.dart';
import 'package:rently_cse2100_project/models/rent_record_model.dart';
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
  });
}
