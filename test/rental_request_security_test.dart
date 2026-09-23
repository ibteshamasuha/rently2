import 'package:flutter_test/flutter_test.dart';

/// Simulation of Firestore Security Rules logic for Rental Requests
class FirestoreRentalRequestsRulesSimulator {
  static bool evaluateRead({
    required String? authUid,
    required String? authRole,
    required String resourceTenantId,
    required String resourceLandlordId,
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';

    if (!isSignedIn) return false;
    return resourceTenantId == authUid || resourceLandlordId == authUid || isAdmin;
  }

  static bool evaluateCreate({
    required String? authUid,
    required String? authRole,
    required String requestTenantId,
    required String requestLandlordId,
    required String requestStatus,
    required String? actualApartmentLandlordId, // null if apartment doesn't exist in DB
  }) {
    final isSignedIn = authUid != null;
    final isAdmin = isSignedIn && authRole == 'admin';
    final isTenant = isSignedIn && (authRole == 'tenant' || authRole == 'both');

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
}

void main() {
  const tenantAUid = 'tenant_A_uid_111';
  const tenantBUid = 'tenant_B_uid_222';
  const landlordAUid = 'landlord_A_uid_333';
  const landlordBUid = 'landlord_B_uid_444';
  const aptAId = 'apt_A_owned_by_landlord_A';
  const aptBId = 'apt_B_owned_by_landlord_B';

  group('Rental Request Security & Authorization Tests', () {
    // 1. Tenant A -> own request
    test('1. Tenant A can read and create their own rental request', () {
      final canCreate = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
      );
      expect(canCreate, isTrue, reason: 'Tenant A must be allowed to create their own request');

      final canRead = FirestoreRentalRequestsRulesSimulator.evaluateRead(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
      );
      expect(canRead, isTrue, reason: 'Tenant A must be allowed to read their own request');
    });

    // 2. Tenant A -> Tenant B's request
    test('2. Tenant A accessing Tenant B request is DENIED', () {
      final canReadTenantBRequest = FirestoreRentalRequestsRulesSimulator.evaluateRead(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantBUid,
        resourceLandlordId: landlordAUid,
      );
      expect(canReadTenantBRequest, isFalse, reason: 'Tenant A must NOT be able to view Tenant B request');

      final canCancelTenantBRequest = FirestoreRentalRequestsRulesSimulator.evaluateUpdate(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantBUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'pending',
        requestTenantId: tenantBUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptAId,
        requestStatus: 'cancelled',
      );
      expect(canCancelTenantBRequest, isFalse, reason: 'Tenant A must NOT be able to modify Tenant B request');
    });

    // 3. Landlord A -> request for Landlord A's apartment
    test('3. Landlord A can read and manage requests for Landlord A apartment', () {
      final canRead = FirestoreRentalRequestsRulesSimulator.evaluateRead(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
      );
      expect(canRead, isTrue, reason: 'Landlord A must be able to view requests for their apartment');

      final canApprove = FirestoreRentalRequestsRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptAId,
        requestStatus: 'approved',
      );
      expect(canApprove, isTrue, reason: 'Landlord A must be able to approve requests for their apartment');
    });

    // 4. Landlord A -> request for Landlord B's apartment
    test('4. Landlord A accessing request for Landlord B apartment is DENIED', () {
      final canRead = FirestoreRentalRequestsRulesSimulator.evaluateRead(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordBUid,
      );
      expect(canRead, isFalse, reason: 'Landlord A must NOT see rental requests for Landlord B apartment');
    });

    // 5. Landlord A -> approve Landlord B's request
    test('5. Landlord A approving Landlord B request is DENIED', () {
      final canApprove = FirestoreRentalRequestsRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordBUid,
        resourceApartmentId: aptBId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordBUid,
        requestApartmentId: aptBId,
        requestStatus: 'approved',
      );
      expect(canApprove, isFalse, reason: 'Landlord A must NOT be able to approve requests for Landlord B apartment');
    });

    // 6. Tenant A -> create request pretending to be Tenant B
    test('6. Tenant A creating request pretending to be Tenant B is DENIED', () {
      final canSpoof = FirestoreRentalRequestsRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantBUid, // Attempting to spoof Tenant B
        requestLandlordId: landlordAUid,
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
      );
      expect(canSpoof, isFalse, reason: 'Tenant A must NOT be able to create a request under Tenant B UID');
    });

    // Bonus: Test apartmentId tampering prevention
    test('7. Tampering with apartmentId or landlordId during update is DENIED', () {
      final canChangeAptId = FirestoreRentalRequestsRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptBId, // Attempted tampering
        requestStatus: 'approved',
      );
      expect(canChangeAptId, isFalse, reason: 'apartmentId must be immutable');
    });
  });
}
