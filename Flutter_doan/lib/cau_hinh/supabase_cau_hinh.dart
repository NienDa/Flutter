class SupabaseCauHinh {
  /// URL của dự án Supabase.
  /// Có thể truyền bằng --dart-define=SUPABASE_URL=...
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hczzslleqblzmrzweoon.supabase.co',
  );

  /// ANON/PUBLISHABLE KEY của dự án Supabase.
  /// Có thể truyền bằng --dart-define=SUPABASE_ANON_KEY=...
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjenpzbGxlcWJsem1yendlb29uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxMjYwOTQsImV4cCI6MjA5NTcwMjA5NH0.fg3SSNSYPjjIw3NOHI-ktEgvABH8ZdKDxOXl9W7Vf34',
  );
}
