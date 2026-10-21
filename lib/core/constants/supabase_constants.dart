import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi Supabase URL & Anon Key
/// Membaca konfigurasi dari .env (via flutter_dotenv) atau String.fromEnvironment (--dart-define)
class SupabaseConstants {
  SupabaseConstants._();

  static String get url =>
      dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://cyjsjvhubmwhoewkvrez.supabase.co',
      );

  static String get anonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN5anNqdmh1Ym13aG9ld2t2cmV6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIxMjkyNTEsImV4cCI6MjEwNzcwNTI1MX0.cGsFNCnesIWWtP5bq9O4Wr5decG7fnnZk6gXaOd4qiA',
      );
}

