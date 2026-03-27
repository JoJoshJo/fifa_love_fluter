import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = 'https://your-placeholder-project.supabase.co';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static SupabaseClient get client => Supabase.instance.client;
}
