import 'package:flutter_test/flutter_test.dart';

/// Simulation of Firestore Security Rules logic for Maintenance Requests
class FirestoreMaintenanceRulesSimulator {
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

    // Landlord updating status/details for their own apartment
    if (isLandlord && resourceLandlordId == authUid) {
      return ['pending', 'in-progress', 'completed', 'rejected'].contains(requestStatus);
    }

    // Tenant updating their own pending request
    if (resourceTenantId == authUid && resourceStatus == 'pending') {
      return true;
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

  group('Maintenance Request Security & Authorization Tests', () {
    // 1. Tenant A creates own maintenance request
    test('1. Tenant A creates own maintenance request is ALLOWED', () {
      final canCreate = FirestoreMaintenanceRulesSimulator.evaluateCreate(
        authUid: tenantAUid,
        authRole: 'tenant',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestStatus: 'pending',
        actualApartmentLandlordId: landlordAUid,
      );
      expect(canCreate, isTrue, reason: 'Tenant A must be able to create maintenance request for their apartment');

      // Tenant A can also read their own request
      final canRead = FirestoreMaintenanceRulesSimulator.evaluateRead(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
      );
      expect(canRead, isTrue, reason: 'Tenant A must be able to read their own maintenance request');
    });

    // 2. Tenant A cannot access Tenant B's request
    test('2. Tenant A cannot access Tenant B request is DENIED', () {
      final canReadTenantB = FirestoreMaintenanceRulesSimulator.evaluateRead(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantBUid,
        resourceLandlordId: landlordAUid,
      );
      expect(canReadTenantB, isFalse, reason: 'Tenant A must NOT see Tenant B maintenance request');

      final canModifyTenantB = FirestoreMaintenanceRulesSimulator.evaluateUpdate(
        authUid: tenantAUid,
        authRole: 'tenant',
        resourceTenantId: tenantBUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'pending',
        requestTenantId: tenantBUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptAId,
        requestStatus: 'completed',
      );
      expect(canModifyTenantB, isFalse, reason: 'Tenant A cannot modify Tenant B maintenance request');
    });

    // 3. Landlord A can access requests for their apartment
    test('3. Landlord A can access requests for their apartment is ALLOWED', () {
      final canRead = FirestoreMaintenanceRulesSimulator.evaluateRead(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
      );
      expect(canRead, isTrue, reason: 'Landlord A must be able to view tickets for their apartment');

      final canUpdateStatus = FirestoreMaintenanceRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptAId,
        requestStatus: 'in-progress',
      );
      expect(canUpdateStatus, isTrue, reason: 'Landlord A can update ticket to in-progress');
    });

    // 4. Landlord A cannot access requests for Landlord B's apartment
    test('4. Landlord A cannot access requests for Landlord B apartment is DENIED', () {
      final canRead = FirestoreMaintenanceRulesSimulator.evaluateRead(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordBUid,
      );
      expect(canRead, isFalse, reason: 'Landlord A must NOT see tickets for Landlord B apartment');
    });

    // 5. Landlord A cannot modify another landlord's maintenance request
    test('5. Landlord A cannot modify Landlord B maintenance request is DENIED', () {
      final canUpdate = FirestoreMaintenanceRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordBUid,
        resourceApartmentId: aptBId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordBUid,
        requestApartmentId: aptBId,
        requestStatus: 'completed',
      );
      expect(canUpdate, isFalse, reason: 'Landlord A cannot modify tickets for Landlord B apartment');
    });

    // 6. Existing maintenance workflow still works
    test('6. Existing maintenance workflow still works across full lifecycle', () {
      // Landlord A moves ticket from pending -> in-progress -> completed
      final canStartProgress = FirestoreMaintenanceRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'pending',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptAId,
        requestStatus: 'in-progress',
      );
      expect(canStartProgress, isTrue);

      final canComplete = FirestoreMaintenanceRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'in-progress',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptAId,
        requestStatus: 'completed',
      );
      expect(canComplete, isTrue);

      // Attempted tampering of apartmentId during resolution is blocked
      final canTamperApt = FirestoreMaintenanceRulesSimulator.evaluateUpdate(
        authUid: landlordAUid,
        authRole: 'landlord',
        resourceTenantId: tenantAUid,
        resourceLandlordId: landlordAUid,
        resourceApartmentId: aptAId,
        resourceStatus: 'in-progress',
        requestTenantId: tenantAUid,
        requestLandlordId: landlordAUid,
        requestApartmentId: aptBId, // Tampered
        requestStatus: 'completed',
      );
      expect(canTamperApt, isFalse, reason: 'apartmentId tampering must be blocked');
    });
  });
}
