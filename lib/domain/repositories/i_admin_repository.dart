abstract class IAdminRepository {
  Future<Map<String, bool>> getFeatureFlags();
  Future<void> setFeatureFlag(String key, bool value);
  Future<void> setTrainerVerification(String trainerId, bool isVerified);
  Future<void> setUserStatus(String userId, String status);
}
