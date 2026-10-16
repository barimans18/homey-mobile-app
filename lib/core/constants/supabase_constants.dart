/// Konfigurasi Supabase URL & Anon Key
/// Bisa di-override melalui String.fromEnvironment saat build atau run:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConstants {
  SupabaseConstants._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cyjsjvhubmwhoewkvrez.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5anNqdmh1Ym13aG9ld2t2cmV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxMjkyNTEsImV4cCI6MjEwNzcwNTI1MX0.cGsFNCnesIWWtP5bq9O4Wr5decG7fnnZk6gXaOd4qiA',
  );
}
