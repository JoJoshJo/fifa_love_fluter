import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = 'https://xzzsursuurcsrlmjwrwh.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6enN1cnN1dXJjc3JsbWp3cndoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5NzEwOTUsImV4cCI6MjA4NzU0NzA5NX0.6b8XMyLRaukKu0xO4cNokrwXNw_qGaDwdhLg9ej08DY';
  
  static SupabaseClient get client => Supabase.instance.client;
}
