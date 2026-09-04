// Environment and Supabase Backend Configuration

enum AppEnvironment { development, staging, production }

class AppConfig {
  static AppEnvironment environment = AppEnvironment.development;

  // Live Supabase Credentials
  static String supabaseUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ijorgyevmznjbawhddil.supabase.co',
  );

  static String supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlqb3JneWV2bXpuamJhd2hkZGlsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgxODU0MDYsImV4cCI6MjEwMzc2MTQwNn0.sy5h4FmL6DVcjYd12l03bPe9EuWUKinWF0gox-J0v3s',
  );

  // Storage Buckets
  static const String progressPhotosBucket = 'progress-photos';
  static const String trainerCertificatesBucket = 'trainer-certificates';
  static const String paymentReceiptsBucket = 'payment-receipts';

  // Demo / Dev Mode Flag: Enables DemoRoleHUD in development, disables in production
  static bool get isDemoHudEnabled => environment == AppEnvironment.development;

  // Whether backend Supabase client is initialized with live credentials
  static bool get isLiveBackendAvailable =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('xyzcompany') &&
      supabaseAnonKey.length > 30;

  static void initialize({
    AppEnvironment env = AppEnvironment.development,
    String? url,
    String? anonKey,
  }) {
    environment = env;
    if (url != null) supabaseUrl = url;
    if (anonKey != null) supabaseAnonKey = anonKey;
  }
}
