import '../supabase/supabase_config.dart';

class UrlHelper {
  /// Resolves a full public URL for a given image path or URL.
  /// 
  /// - If the input is already a full URL (starts with http), it's returned as-is.
  /// - If the input is a bare filename with no path (no '/'), it returns empty to
  ///   avoid constructing a broken Supabase URL for non-existent files.
  /// - If the input is a storage path (contains '/'), it resolves it via Supabase Storage.
  static String resolveImageUrl(String? path, {String bucket = 'avatars'}) {
    if (path == null || path.isEmpty) return '';
    
    // 1. If it's already a full URL, return it
    if (path.startsWith('http')) {
      return path;
    }

    // 2. If it's a bare filename with no directory (e.g., 'mock_brazil.jpg'),
    //    it's not a valid storage path — return empty to avoid a 400 error.
    if (!path.contains('/')) {
      return '';
    }
    
    // 3. Otherwise, resolve via Supabase Storage
    try {
      return SupabaseConfig.client.storage
          .from(bucket)
          .getPublicUrl(path);
    } catch (_) {
      return '';
    }
  }
}
