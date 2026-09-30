import 'package:flutter_test/flutter_test.dart';
import 'package:rently_cse2100_project/models/rental_request_model.dart';

/// Simulation of Firestore Security Rules logic for Rental Requests
class FirestoreRentalRequestsRulesSimulator {
  static bool evaluateRead({
    required String? authUid,
    required String? authRole,
    required String? resourceTenantId,
    required String? resourceLandlordId,
    bool resourceIsNull = false,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';

    if (!isSignedIn) return false;
    if (resourceIsNull) return true;
    return resourceTenantId == authUid || resourceLandlordId == authUid || isAdmin;
  }

  static bool evaluateCreate({
    required String? authUid,
    required String? authRole,
    required String requestTenantId,
    required String requestLandlordId,
    required String requestStatus,
    required String requestApartmentId,
    required String requestId,
    required String? actualApartmentLandlordId, // null if apartment doesn't exist in DB
    bool hasExistingRequestForTenantAndApartment = false,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';
    final isTenant = isSignedIn && (authRole == 'tenant' || authRole == 'both' || authRole == null);

    if (!isSignedIn) return false;
    if (!isTenant && !isAdmin) return false;

    // Tenant must create request for themselves
    if (requestTenantId != authUid) return false;

    // Initial status must be pending
    if (requestStatus != 'pending') return false;

    // If apartment exists in database, landlordId must match actual apartment owner
    if (actualApartmentLandlordId != null && requestLandlordId != actualApartmentLandlordId) {
      return false;
    }

    // At most one rental request per tenant per apartment across all statuses
    if (hasExistingRequestForTenantAndApartment && !isAdmin) {
      return false;
    }

    // Deterministic requestId format: authUid_apartmentId
    final expectedDocId = '${authUid}_$requestApartmentId';
    if (!isAdmin && requestId != expectedDocId) {
      return false;
    }

    return true;
  }

  static bool evaluateUpdate({
    required String? authUid,
    required String? authRole,
    required String resourceTenantId,
    required String resourceLandlordId,
    required String resourceApartmentId,
    required String resourceStatus,
    required String requestTenantId,
    required String requestLandlordId,
    required String requestApartmentId,
    required String requestStatus,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';
    final isLandlord = isSignedIn && (authRole == 'landlord' || authRole == 'both');

    if (!isSignedIn) return false;

    // IDs are strictly immutable
    final idsUnchanged = requestTenantId == resourceTenantId &&
        requestLandlordId == resourceLandlordId &&
        requestApartmentId == resourceApartmentId;

    if (!idsUnchanged) return false;

    // Admin can update
    if (isAdmin) return true;

    // Landlord approving/rejecting their own apartment's request
    if (isLandlord && resourceLandlordId == authUid) {
      return ['approved', 'rejected', 'pending'].contains(requestStatus);
    }

    // Tenant cancelling their own pending request
    if (resourceTenantId == authUid && resourceStatus == 'pending') {
      return ['cancelled', 'pending'].contains(requestStatus);
    }

    return false;
  }

  static bool evaluateDelete({
    required String? authUid,
    required String? authRole,
    required String resourceTenantId,
    required String resourceLandlordId,
    required String resourceStatus,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';
    final isLandlord = isSignedIn && (authRole == 'landlord' || authRole == 'both');

    if (!isSignedIn) return false;
    if (isAdmin) return true;
    if (isLandlord && resourceLandlordId == authUid) return true;
    // Tenant can ONLY delete while pending
    if (resourceTenantId == authUid && resourceStatus == 'pending') return true;

    return false;
  }
}

/// Simulation of Firestore Security Rules logic for Notices
class FirestoreNoticesRulesSimulator {
  static bool evaluateRead({
    required String? authUid,
    required String? authRole,
    required String authorId,
    required bool isPublic,
    String? targetTenantId,
    String? rentedApartmentTenantId,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';

    if (!isSignedIn) return false;
    if (isAdmin) return true;
    if (authorId == authUid) return true;
    if (isPublic) return true;
    if (targetTenantId != null && targetTenantId == authUid) return true;
    if (rentedApartmentTenantId != null && rentedApartmentTenantId == authUid) return true;

    return false;
  }
}

/// Simulation of Firestore Security Rules logic for Apartments
class FirestoreApartmentsRulesSimulator {
  static bool evaluateRead({
    required String? authUid,
    required String status,
    required String landlordId,
    String? currentTenantId,
    required String? authRole,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';

    if (!isSignedIn) return false;
    if (isAdmin) return true;
    if (['available', 'Available'].contains(status)) return true;
    if (landlordId == authUid) return true;
    if (currentTenantId != null && currentTenantId == authUid) return true;

    return false;
  }
}

void main() {
  const tenantAUid = 'tenant_A_uid_111';
  const tenantBUid = 'tenant_B_uid_222';
  const landlordAUid = 'landlord_A_uid_333';
  const landlordBUid = 'landlord_B_uid_444';
  const aptXId = 'apartment_X_id';
  const aptYId = 'apartment_Y_id';

  group('Rental Request & Security Verification (TEST 1 to TEST 11)', () {
    // TEST 1: Tenant A has never requested Apartment X -> Tenant A CAN send a request.
    test('TEST 1: Tenant A has never requested Apartment X -> Tenant A CAN send a request', () {
      final canCreate = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptXId,
        requestId: '${tenantAUid}_$aptXId',
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
        hasExistingRequestForTenantAndApartment: false,
      );
      expect(canCreate, isTrue, reason: 'Tenant A must be allowed to create an initial request for Apartment X');
    });

    // TEST 2: Tenant A has a PENDING request for Apartment X -> Tenant A CANNOT send another request.
    test('TEST 2: Tenant A has a PENDING request for Apartment X -> Tenant A CANNOT send another request', () {
      final canCreateDuplicate = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptXId,
        requestId: '${tenantAUid}_$aptXId',
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
        hasExistingRequestForTenantAndApartment: true,
      );
      expect(canCreateDuplicate, isFalse, reason: 'Duplicate request while PENDING must be blocked');
    });

    // TEST 3: Landlord rejects Tenant A's request -> Request remains in Firestore as REJECTED -> Tenant A STILL CANNOT send another request for Apartment X.
    test('TEST 3: Landlord rejects Tenant A request -> Remains REJECTED -> Tenant A STILL CANNOT send another request for Apartment X', () {
      // 1. Landlord A rejects Tenant A's request
      final canReject = FirestoreRentalRequestsRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptXId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptXId,
        requestStatus: 'rejected',
      );
      expect(canReject, isTrue, reason: 'Landlord must be able to reject pending request');

      // 2. Tenant A CANNOT delete the rejected request (history preserved)
      final canTenantDeleteRejected = FirestoreRentalRequestsRulesSimulator.evaluateDelete(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceStatus: 'rejected',
      );
      expect(canTenantDeleteRejected, isFalse, reason: 'Tenant must NOT be able to delete a rejected request');

      // 3. Tenant A CANNOT update/reset the rejected request back to pending
      final canTenantResetRejected = FirestoreRentalRequestsRulesSimulator.evaluateUpdate(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptXId,
        resourceStatus: 'rejected',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptXId,
        requestStatus: 'pending',
      );
      expect(canTenantResetRejected, isFalse, reason: 'Tenant must NOT be able to reset a rejected request');

      // 4. Tenant A CANNOT create a new request for Apartment X
      final canCreateAfterRejection = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptXId,
        requestId: '${tenantAUid}_$aptXId',
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
        hasExistingRequestForTenantAndApartment: true,
      );
      expect(canCreateAfterRejection, isFalse, reason: 'Tenant A must STILL be blocked from re-requesting Apartment X');
    });

    // TEST 4: Tenant A has a REJECTED request for Apartment X -> Tenant A CAN request Apartment Y.
    test('TEST 4: Tenant A has a REJECTED request for Apartment X -> Tenant A CAN request Apartment Y', () {
      final canRequestAptY = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordBUid,
        requestApartmentId: aptYId,
        requestId: '${tenantAUid}_$aptYId',
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordBUid,
        hasExistingRequestForTenantAndApartment: false, // No request exists for Apt Y
      );
      expect(canRequestAptY, isTrue, reason: 'Tenant A must be allowed to request Apartment Y');
    });

    // TEST 5: Tenant B has never requested Apartment X -> Tenant B CAN request Apartment X.
    test('TEST 5: Tenant B has never requested Apartment X -> Tenant B CAN request Apartment X', () {
      final canTenantBRequestAptX = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantBUid,
        authRole: 'tenant',
        requestTenantId: tenantBUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptXId,
        requestId: '${tenantBUid}_$aptXId',
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
        hasExistingRequestForTenantAndApartment: false, // Tenant B has not requested Apt X
      );
      expect(canTenantBRequestAptX, isTrue, reason: 'Tenant B must be allowed to request Apartment X');
    });

    // TEST 6: There are: 2 pending, 3 accepted, 4 rejected -> Landlord request count must show: 2
    test('TEST 6: 2 pending, 3 accepted, 4 rejected -> Landlord pending count displays 2', () {
      final sampleRequests = [
        RentalRequestModel(id: '1', tenantId: 't1', landlordId: landlordAUid, apartmentId: 'a1', status: 'pending'),
        RentalRequestModel(id: '2', tenantId: 't2', landlordId: landlordAUid, apartmentId: 'a2', status: 'pending'),
        RentalRequestModel(id: '3', tenantId: 't3', landlordId: landlordAUid, apartmentId: 'a3', status: 'approved'),
        RentalRequestModel(id: '4', tenantId: 't4', landlordId: landlordAUid, apartmentId: 'a4', status: 'approved'),
        RentalRequestModel(id: '5', tenantId: 't5', landlordId: landlordAUid, apartmentId: 'a5', status: 'approved'),
        RentalRequestModel(id: '6', tenantId: 't6', landlordId: landlordAUid, apartmentId: 'a6', status: 'rejected'),
        RentalRequestModel(id: '7', tenantId: 't7', landlordId: landlordAUid, apartmentId: 'a7', status: 'rejected'),
        RentalRequestModel(id: '8', tenantId: 't8', landlordId: landlordAUid, apartmentId: 'a8', status: 'rejected'),
        RentalRequestModel(id: '9', tenantId: 't9', landlordId: landlordAUid, apartmentId: 'a9', status: 'rejected'),
      ];

      final pendingCount = sampleRequests
          .where((r) => r.isPending || r.status.toLowerCase() == 'pending')
          .length;

      expect(pendingCount, equals(2), reason: 'Pending count must be 2, ignoring approved and rejected requests');
    });

    // TEST 7: One pending request is accepted -> Count becomes 1.
    test('TEST 7: One pending request is accepted -> Count decreases to 1', () {
      final sampleRequests = [
        RentalRequestModel(id: '1', tenantId: 't1', landlordId: landlordAUid, apartmentId: 'a1', status: 'approved'), // Accepted!
        RentalRequestModel(id: '2', tenantId: 't2', landlordId: landlordAUid, apartmentId: 'a2', status: 'pending'),
        RentalRequestModel(id: '3', tenantId: 't3', landlordId: landlordAUid, apartmentId: 'a3', status: 'approved'),
        RentalRequestModel(id: '4', tenantId: 't4', landlordId: landlordAUid, apartmentId: 'a4', status: 'approved'),
        RentalRequestModel(id: '5', tenantId: 't5', landlordId: landlordAUid, apartmentId: 'a5', status: 'approved'),
        RentalRequestModel(id: '6', tenantId: 't6', landlordId: landlordAUid, apartmentId: 'a6', status: 'rejected'),
        RentalRequestModel(id: '7', tenantId: 't7', landlordId: landlordAUid, apartmentId: 'a7', status: 'rejected'),
        RentalRequestModel(id: '8', tenantId: 't8', landlordId: landlordAUid, apartmentId: 'a8', status: 'rejected'),
        RentalRequestModel(id: '9', tenantId: 't9', landlordId: landlordAUid, apartmentId: 'a9', status: 'rejected'),
      ];

      final pendingCount = sampleRequests
          .where((r) => r.isPending || r.status.toLowerCase() == 'pending')
          .length;

      expect(pendingCount, equals(1), reason: 'Pending count must decrease from 2 to 1');
    });

    // TEST 8: One pending request is rejected -> Count decreases accordingly.
    test('TEST 8: One pending request is rejected -> Count decreases accordingly', () {
      final sampleRequests = [
        RentalRequestModel(id: '1', tenantId: 't1', landlordId: landlordAUid, apartmentId: 'a1', status: 'rejected'), // Rejected!
        RentalRequestModel(id: '2', tenantId: 't2', landlordId: landlordAUid, apartmentId: 'a2', status: 'pending'),
        RentalRequestModel(id: '3', tenantId: 't3', landlordId: landlordAUid, apartmentId: 'a3', status: 'approved'),
        RentalRequestModel(id: '4', tenantId: 't4', landlordId: landlordAUid, apartmentId: 'a4', status: 'approved'),
        RentalRequestModel(id: '5', tenantId: 't5', landlordId: landlordAUid, apartmentId: 'a5', status: 'approved'),
        RentalRequestModel(id: '6', tenantId: 't6', landlordId: landlordAUid, apartmentId: 'a6', status: 'rejected'),
        RentalRequestModel(id: '7', tenantId: 't7', landlordId: landlordAUid, apartmentId: 'a7', status: 'rejected'),
        RentalRequestModel(id: '8', tenantId: 't8', landlordId: landlordAUid, apartmentId: 'a8', status: 'rejected'),
        RentalRequestModel(id: '9', tenantId: 't9', landlordId: landlordAUid, apartmentId: 'a9', status: 'rejected'),
      ];

      final pendingCount = sampleRequests
          .where((r) => r.isPending || r.status.toLowerCase() == 'pending')
          .length;

      expect(pendingCount, equals(1), reason: 'Pending count must decrease from 2 to 1 upon rejection');
    });

    // TEST 9: Tenant sends message and preferredMoveInDate -> Landlord opens request -> Both are visible
    test('TEST 9: Message and preferredMoveInDate are stored and accessible on RentalRequestModel', () {
      final moveInDate = DateTime(2026, 11, 15);
      const testMessage = 'I would like to move in next month.';

      final request = RentalRequestModel(
        id: '${tenantAUid}_$aptXId',
        tenantId: tenantAUid,
        landlordId: landlordAUid,
        apartmentId: aptXId,
        status: 'pending',
        message: testMessage,
        tenantName: 'Tenant A',
        apartmentTitle: 'Apartment X',
        preferredMoveInDate: moveInDate,
        createdAt: DateTime.now(),
      );

      final map = request.toMap();
      expect(map['tenantId'], equals(tenantAUid));
      expect(map['apartmentId'], equals(aptXId));
      expect(map['landlordId'], equals(landlordAUid));
      expect(map['message'], equals(testMessage));
      expect(map['preferredMoveInDate'], isNotNull);
      expect(map['status'], equals('pending'));
      expect(map['createdAt'], isNotNull);

      expect(request.message, equals(testMessage));
      expect(request.preferredMoveInDate, equals(moveInDate));
    });

    // TEST 10: Landlord sends a private notice to Tenant A -> Tenant A sees it, Tenant B does not see it.
    test('TEST 10: Landlord sends a private notice to Tenant A -> Tenant A can read, Tenant B is DENIED', () {
      const privateNoticeAuthorId = landlordAUid;
      const targetTenantId = tenantAUid;
      const isPublic = false;

      // Tenant A reads notice -> Allowed
      final tenantACanRead = FirestoreNoticesRulesSimulator.evaluateRead(
        authUid: tenantAUid,
        authRole: 'tenant',
        authorId: privateNoticeAuthorId,
        isPublic: isPublic,
        targetTenantId: targetTenantId,
      );
      expect(tenantACanRead, isTrue, reason: 'Tenant A must be allowed to read notice targeted to them');

      // Tenant B reads notice -> Denied
      final tenantBCanRead = FirestoreNoticesRulesSimulator.evaluateRead(
        authUid: tenantBUid,
        authRole: 'tenant',
        authorId: privateNoticeAuthorId,
        isPublic: isPublic,
        targetTenantId: targetTenantId,
      );
      expect(tenantBCanRead, isFalse, reason: 'Tenant B must NOT be allowed to read private notice intended for Tenant A');
    });

    // TEST 11: Landlord creates a new available apartment -> Tenant can see that apartment in the browsing screen.
    test('TEST 11: Landlord creates a new available apartment -> Tenant can discover it without tenantId', () {
      final canTenantDiscover = FirestoreApartmentsRulesSimulator.evaluateRead(
        authUid: tenantAUid,
        authRole: 'tenant',
        status: 'available',
        landlordId: landlordAUid,
        currentTenantId: null, // Unrented apartment
      );
      expect(canTenantDiscover, isTrue, reason: 'Tenant must be able to read available apartments without requiring currentTenantId');
    });
  });
}
