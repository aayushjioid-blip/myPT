import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/package_entity.dart';
import '../../../domain/entities/credit_transaction_entity.dart';
import '../../../domain/entities/relationship_entity.dart';
import '../../../domain/entities/payment_entity.dart';
import '../../../domain/repositories/i_package_repository.dart';
import '../../models/package_model.dart';
import '../../models/client_package_model.dart';
import '../../models/payment_model.dart';

class SupabasePackageRepository implements IPackageRepository {
  final SupabaseClient _client;

  SupabasePackageRepository(this._client);

  @override
  Future<List<PackageEntity>> getPackagesByTrainerId(String trainerId) async {
    try {
      final res = await _client
          .from('packages')
          .select('*')
          .eq('trainer_id', trainerId)
          .eq('is_active', true);

      return (res as List).map((json) => PackageModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [
        const PackageEntity(
          id: '30000000-0000-0000-0000-000000000001',
          trainerId: '00000000-0000-0000-0000-000000000002',
          name: '10 PT Sessions Starter Pack',
          description: 'Comprehensive 1-on-1 coaching, nutrition guidance, and bi-weekly body scans.',
          sessions: 10,
          price: 499.00,
          validityDays: 45,
        ),
        const PackageEntity(
          id: '30000000-0000-0000-0000-000000000002',
          trainerId: '00000000-0000-0000-0000-000000000002',
          name: '20 PT Elite Transformation',
          description: 'Full transformation program with 3x weekly training, mobility routines, and app support.',
          sessions: 20,
          price: 899.00,
          validityDays: 90,
        ),
      ];
    }
  }

  @override
  Future<List<ClientPackageEntity>> getClientPackages(String clientId) async {
    try {
      final res = await _client
          .from('client_packages')
          .select('*')
          .eq('client_id', clientId)
          .order('created_at', ascending: false);

      return (res as List).map((json) => ClientPackageModel.fromJson(json).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ClientPackageEntity?> getActivePackageForClient(String clientId) async {
    try {
      final res = await _client
          .from('client_packages')
          .select('*')
          .eq('client_id', clientId)
          .eq('status', 'ACTIVE')
          .gt('remaining_sessions', 0)
          .order('activated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return ClientPackageModel.fromJson(res).toEntity();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<RelationshipEntity?> getRelationship(String clientId, String trainerId) async {
    try {
      final res = await _client
          .from('relationships')
          .select('*')
          .eq('client_id', clientId)
          .eq('trainer_id', trainerId)
          .maybeSingle();

      if (res != null) {
        return RelationshipEntity(
          id: res['id'].toString(),
          clientId: res['client_id'].toString(),
          trainerId: res['trainer_id'].toString(),
          status: res['status']?.toString() == 'ACCEPTED' ? RelationshipStatus.accepted : RelationshipStatus.requested,
          approvedForPackages: res['approved_for_packages'] ?? false,
          notes: res['notes']?.toString() ?? '',
          createdAt: res['created_at'] != null ? DateTime.parse(res['created_at'].toString()) : DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> requestConsultation({
    required String clientId,
    required String trainerId,
    required String goals,
    required String notes,
  }) async {
    try {
      await _client.from('consultation_requests').insert({
        'client_id': clientId,
        'trainer_id': trainerId,
        'goals': goals,
        'notes': notes,
        'status': 'REQUESTED',
      });

      await _client.from('relationships').upsert({
        'client_id': clientId,
        'trainer_id': trainerId,
        'status': 'REQUESTED',
        'approved_for_packages': false,
        'notes': goals,
      });
    } catch (_) {}
  }

  @override
  Future<List<RelationshipEntity>> getPendingRelationshipsForTrainer(String trainerId) async {
    try {
      final res = await _client
          .from('relationships')
          .select('*')
          .eq('trainer_id', trainerId)
          .eq('status', 'REQUESTED');

      return (res as List).map<RelationshipEntity>((r) {
        return RelationshipEntity(
          id: r['id'].toString(),
          clientId: r['client_id'].toString(),
          trainerId: r['trainer_id'].toString(),
          status: RelationshipStatus.requested,
          approvedForPackages: r['approved_for_packages'] ?? false,
          notes: r['notes']?.toString() ?? '',
          createdAt: r['created_at'] != null ? DateTime.parse(r['created_at'].toString()) : DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<RelationshipEntity>> getAcceptedClientsForTrainer(String trainerId) async {
    try {
      final res = await _client
          .from('relationships')
          .select('*')
          .eq('trainer_id', trainerId)
          .eq('status', 'ACCEPTED');

      return (res as List).map<RelationshipEntity>((r) {
        return RelationshipEntity(
          id: r['id'].toString(),
          clientId: r['client_id'].toString(),
          trainerId: r['trainer_id'].toString(),
          status: RelationshipStatus.accepted,
          approvedForPackages: r['approved_for_packages'] ?? true,
          notes: r['notes']?.toString() ?? '',
          createdAt: r['created_at'] != null ? DateTime.parse(r['created_at'].toString()) : DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> acceptConsultation(String relationshipId) async {
    try {
      await _client.from('relationships').update({
        'status': 'ACCEPTED',
        'approved_for_packages': true,
      }).eq('id', relationshipId);
    } catch (_) {}
  }

  @override
  Future<void> rejectConsultation(String relationshipId, String reason) async {
    try {
      await _client.from('relationships').update({
        'status': 'REJECTED',
        'notes': reason,
      }).eq('id', relationshipId);
    } catch (_) {}
  }

  @override
  Future<void> requestPackagePurchase(String clientId, String packageId, String transactionRef) async {
    try {
      final pkg = await _client.from('packages').select('*').eq('id', packageId).single();

      final cpRes = await _client.from('client_packages').insert({
        'client_id': clientId,
        'trainer_id': pkg['trainer_id'],
        'package_id': packageId,
        'total_sessions': pkg['sessions'],
        'remaining_sessions': 0, // 0 CREDITS BEFORE VERIFICATION
        'price_paid': pkg['price'],
        'status': 'PENDING_PAYMENT',
      }).select().single();

      await _client.from('payments').insert({
        'client_id': clientId,
        'trainer_id': pkg['trainer_id'],
        'package_id': packageId,
        'client_package_id': cpRes['id'],
        'amount': pkg['price'],
        'payment_method': 'UPI',
        'transaction_ref': transactionRef,
        'status': 'PENDING_VERIFICATION',
      });
    } catch (_) {}
  }

  @override
  Future<List<PaymentEntity>> getPendingPaymentsForTrainer(String trainerId) async {
    try {
      final res = await _client
          .from('payments')
          .select('*')
          .eq('trainer_id', trainerId)
          .eq('status', 'PENDING_VERIFICATION');

      return (res as List).map<PaymentEntity>((p) => PaymentModel.fromJson(p).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<PaymentEntity>> getAllPayments() async {
    try {
      final res = await _client.from('payments').select('*').order('created_at', ascending: false);
      return (res as List).map<PaymentEntity>((p) => PaymentModel.fromJson(p).toEntity()).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> verifyPayment(String paymentId, bool approve, {String? reason}) async {
    try {
      if (approve) {
        await _client.rpc('verify_and_activate_package_payment', params: {
          'p_payment_id': paymentId,
          'p_verified_by': _client.auth.currentUser?.id,
        });
      } else {
        await _client.from('payments').update({
          'status': 'REJECTED',
          'rejection_reason': reason,
        }).eq('id', paymentId);
      }
    } catch (_) {}
  }

  @override
  Future<void> createPackage(PackageEntity package) async {
    try {
      await _client.from('packages').insert({
        'trainer_id': package.trainerId,
        'name': package.name,
        'description': package.description,
        'sessions': package.sessions,
        'price': package.price,
        'validity_days': package.validityDays,
        'is_active': true,
      });
    } catch (_) {}
  }
}
