import '../../domain/entities/package_entity.dart';
import '../../domain/entities/credit_transaction_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/relationship_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/i_package_repository.dart';
import '../mock/mock_data_store.dart';

class MockPackageRepository implements IPackageRepository {
  final MockDataStore _dataStore;

  MockPackageRepository(this._dataStore);

  Set<String> _resolveEquivalentIds(String id) {
    final set = <String>{id};
    for (final t in _dataStore.trainers) {
      if (t.id == id || t.userId == id) {
        set.add(t.id);
        set.add(t.userId);
      }
    }
    for (final u in _dataStore.users) {
      if (u.id == id) {
        set.add(u.id);
      }
    }
    return set;
  }

  String _resolveTrainerId(String id) {
    try {
      final trainer = _dataStore.trainers.firstWhere(
        (t) => t.id == id || t.userId == id,
      );
      return trainer.id;
    } catch (_) {
      return id;
    }
  }

  @override
  Future<List<PackageEntity>> getPackagesByTrainerId(String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    return _dataStore.packages.where((p) => eq.contains(p.trainerId) && p.status == 'ACTIVE').toList();
  }

  @override
  Future<List<ClientPackageEntity>> getClientPackages(String clientId) async {
    final eq = _resolveEquivalentIds(clientId);
    return _dataStore.clientPackages.where((cp) => eq.contains(cp.clientId)).toList();
  }

  @override
  Future<ClientPackageEntity?> getActivePackageForClient(String clientId) async {
    final eq = _resolveEquivalentIds(clientId);
    try {
      return _dataStore.clientPackages.firstWhere(
        (cp) => eq.contains(cp.clientId) && cp.status == 'ACTIVE' && cp.remainingSessions > 0,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PaymentEntity>> getPendingPaymentsForTrainer(String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    return _dataStore.payments
        .where((p) => eq.contains(p.trainerId) && p.status == PaymentStatus.pendingVerification)
        .toList();
  }

  @override
  Future<List<PaymentEntity>> getAllPayments() async {
    return List.unmodifiable(_dataStore.payments);
  }

  @override
  Future<void> createPackage(PackageEntity package) async {
    // Insert at beginning of list so newly created packages appear on top
    _dataStore.packages.insert(0, package);
    _dataStore.notifyListeners();
  }

  @override
  Future<void> requestPackagePurchase(String clientId, String packageId, String transactionRef) async {
    final pkg = _dataStore.packages.firstWhere((p) => p.id == packageId);

    // 1. Create Payment in PENDING_VERIFICATION
    final payment = PaymentEntity(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      trainerId: pkg.trainerId,
      packageId: pkg.id,
      amount: pkg.price,
      transactionRef: transactionRef,
      status: PaymentStatus.pendingVerification,
      createdAt: DateTime.now(),
    );
    _dataStore.payments.add(payment);

    // 2. Create Client Package in PENDING_PAYMENT (0 credits unlocked)
    final clientPkg = ClientPackageEntity(
      id: 'cpkg-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      trainerId: pkg.trainerId,
      packageId: pkg.id,
      totalSessions: pkg.sessions,
      completedSessions: 0,
      remainingSessions: 0, // Strict: 0 credits until trainer verifies payment
      validityDays: pkg.validityDays,
      purchaseDate: DateTime.now(),
      status: 'PENDING_PAYMENT',
      paymentId: payment.id,
    );
    _dataStore.clientPackages.add(clientPkg);

    // Trigger Notification for Trainer
    _dataStore.notifications.insert(0, NotificationEntity(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: pkg.trainerId,
      title: 'New Offline Payment Submitted',
      message: 'Client submitted payment verification for ${pkg.name}.',
      type: NotificationType.payment,
      timestamp: DateTime.now(),
    ));

    _dataStore.notifyListeners();
  }

  @override
  Future<void> verifyPayment(String paymentId, bool approve, {String? reason}) async {
    final pIdx = _dataStore.payments.indexWhere((p) => p.id == paymentId);
    if (pIdx == -1) return;

    final payment = _dataStore.payments[pIdx];
    final clientPkgIdx = _dataStore.clientPackages.indexWhere((cp) => cp.paymentId == paymentId);

    if (approve) {
      _dataStore.payments[pIdx] = payment.copyWith(
        status: PaymentStatus.paid,
        verifiedAt: DateTime.now(),
      );

      // Upgrade Client Package from PENDING_PAYMENT to ACTIVE with full sessions
      if (clientPkgIdx != -1) {
        final existing = _dataStore.clientPackages[clientPkgIdx];
        _dataStore.clientPackages[clientPkgIdx] = existing.copyWith(
          status: 'ACTIVE',
          remainingSessions: existing.totalSessions, // Activates exactly 10 credits
          activationDate: DateTime.now(),
          expiryDate: DateTime.now().add(Duration(days: existing.validityDays)),
        );

        // Record Initial Ledger Activation Transaction
        _dataStore.creditTransactions.insert(0, CreditTransactionEntity(
          id: 'tx-act-${DateTime.now().millisecondsSinceEpoch}',
          clientId: existing.clientId,
          clientPackageId: existing.id,
          transactionType: CreditTransactionType.packageActivation,
          deltaCredits: existing.totalSessions,
          balanceAfter: existing.totalSessions,
          createdAt: DateTime.now(),
          createdBy: payment.trainerId,
        ));

        // Notify Client
        _dataStore.notifications.insert(0, NotificationEntity(
          id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
          userId: existing.clientId,
          title: 'Package Activated 🎉',
          message: '${existing.totalSessions} PT session credits have been added to your account!',
          type: NotificationType.payment,
          timestamp: DateTime.now(),
        ));
      }
    } else {
      _dataStore.payments[pIdx] = payment.copyWith(
        status: PaymentStatus.rejected,
        rejectionReason: reason ?? 'Invalid payment reference.',
      );

      if (clientPkgIdx != -1) {
        final existing = _dataStore.clientPackages[clientPkgIdx];
        _dataStore.clientPackages[clientPkgIdx] = existing.copyWith(status: 'CANCELLED');
      }
    }

    _dataStore.notifyListeners();
  }

  @override
  Future<RelationshipEntity?> getRelationship(String clientId, String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    final clEq = _resolveEquivalentIds(clientId);
    try {
      return _dataStore.relationships.firstWhere(
        (r) => clEq.contains(r.clientId) && eq.contains(r.trainerId),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RelationshipEntity>> getPendingRelationshipsForTrainer(String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    return _dataStore.relationships
        .where((r) => eq.contains(r.trainerId) && r.status == RelationshipStatus.requested)
        .toList();
  }

  @override
  Future<List<RelationshipEntity>> getAcceptedClientsForTrainer(String trainerId) async {
    final eq = _resolveEquivalentIds(trainerId);
    return _dataStore.relationships
        .where((r) => eq.contains(r.trainerId) && r.status == RelationshipStatus.accepted)
        .toList();
  }

  @override
  Future<void> requestConsultation({
    required String clientId,
    required String trainerId,
    required String goals,
    required String notes,
  }) async {
    final tid = _resolveTrainerId(trainerId);
    final existingIdx = _dataStore.relationships.indexWhere(
      (r) => r.clientId == clientId && (r.trainerId == trainerId || r.trainerId == tid),
    );

    final rel = RelationshipEntity(
      id: existingIdx != -1
          ? _dataStore.relationships[existingIdx].id
          : 'rel-${DateTime.now().millisecondsSinceEpoch}',
      clientId: clientId,
      trainerId: tid,
      status: RelationshipStatus.requested,
      goals: goals,
      notes: notes,
      createdAt: DateTime.now(),
    );

    if (existingIdx != -1) {
      _dataStore.relationships[existingIdx] = rel;
    } else {
      _dataStore.relationships.add(rel);
    }

    // Trigger In-App Notification for Trainer
    _dataStore.notifications.insert(0, NotificationEntity(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: tid,
      title: 'New Client Consultation Request',
      message: 'Client requested a new training consultation.',
      type: NotificationType.info,
      timestamp: DateTime.now(),
    ));

    _dataStore.notifyListeners();
  }

  @override
  Future<void> acceptConsultation(String relationshipId) async {
    final idx = _dataStore.relationships.indexWhere((r) => r.id == relationshipId);
    if (idx != -1) {
      final existing = _dataStore.relationships[idx];
      _dataStore.relationships[idx] = existing.copyWith(
        status: RelationshipStatus.accepted,
        acceptedAt: DateTime.now(),
      );

      // Trigger In-App Notification for Client
      _dataStore.notifications.insert(0, NotificationEntity(
        id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
        userId: existing.clientId,
        title: 'Consultation Accepted 🎉',
        message: 'Your trainer has accepted your request. You can now purchase packages!',
        type: NotificationType.info,
        timestamp: DateTime.now(),
      ));

      _dataStore.notifyListeners();
    }
  }

  @override
  Future<void> rejectConsultation(String relationshipId, [String reason = 'Trainer unavailable']) async {
    final idx = _dataStore.relationships.indexWhere((r) => r.id == relationshipId);
    if (idx != -1) {
      final existing = _dataStore.relationships[idx];
      _dataStore.relationships[idx] = existing.copyWith(
        status: RelationshipStatus.rejected,
      );
      _dataStore.notifyListeners();
    }
  }
}
