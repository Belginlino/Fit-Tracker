class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase Project URL
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dsbcyzjmcjpvbmpbxiex.supabase.co',
  );

  /// Your Supabase anon/public API Key
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzYmN5emptY2pwdmJtcGJ4aWV4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1MzE1MjAsImV4cCI6MjEwNTEwNzUyMH0.z8KtSiAkTksTO8MpN23LL-BvF5B39MMlIe3GTm-g8r8',
  );

  /// Storage bucket for progress photos
  static const String photosBucket = 'progress-photos';

  static bool get isConfigured =>
      url != 'YOUR_SUPABASE_URL_HERE' && anonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
}
