import '../entities/package_entity.dart';
import '../entities/credit_transaction_entity.dart';
import '../entities/payment_entity.dart';
import '../entities/relationship_entity.dart';

abstract class IPackageRepository {
  Future<List<PackageEntity>> getPackagesByTrainerId(String trainerId);
  Future<List<ClientPackageEntity>> getClientPackages(String clientId);
  Future<ClientPackageEntity?> getActivePackageForClient(String clientId);
  Future<List<PaymentEntity>> getPendingPaymentsForTrainer(String trainerId);
  Future<List<PaymentEntity>> getAllPayments();
  Future<void> createPackage(PackageEntity package);
  Future<void> requestPackagePurchase(String clientId, String packageId, String transactionRef);
  Future<void> verifyPayment(String paymentId, bool approve, {String? reason});
  
  // Relationship & Consultation Requests
  Future<RelationshipEntity?> getRelationship(String clientId, String trainerId);
  Future<List<RelationshipEntity>> getPendingRelationshipsForTrainer(String trainerId);
  Future<List<RelationshipEntity>> getAcceptedClientsForTrainer(String trainerId);
  Future<void> requestConsultation({
    required String clientId,
    required String trainerId,
    required String goals,
    required String notes,
  });
  Future<void> acceptConsultation(String relationshipId);
  Future<void> rejectConsultation(String relationshipId, String reason);
}
