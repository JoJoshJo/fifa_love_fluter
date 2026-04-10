import '../supabase/supabase_config.dart';
import 'url_helper_stub.dart' if (dart.library.html) 'url_helper_web.dart' as platform;

class UrlHelper {
  /// Resolves a Supabase storage path to a full public URL
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    // Construct the public URL for the 'avatars' bucket
    final baseUrl = SupabaseConfig.supabaseUrl;
    return '$baseUrl/storage/v1/object/public/avatars/$path';
  }

  /// Clears the URL fragment/hash from the browser address bar (Web only)
  static void clearUrlPath() {
    platform.clearUrlPath();
  }
}
