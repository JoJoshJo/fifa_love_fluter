import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_config.dart';

class MeRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final res = await _client
        .from('profiles')
        .select('id, name, age, bio, avatar_url, nationality, gender, city, interests, languages, team_supported, countries_to_match, phone_number, is_verified, is_local, verification_status')
        .eq('id', userId)
        .single();
    return res;
  }

  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    await _client.from('profiles').update(updates).eq('id', userId);
  }

  Future<String?> uploadAvatar(String userId, File imageFile) async {
    final ext = imageFile.path.split('.').last;
    final path = '$userId/avatar.$ext';

    await _client.storage.from('avatars').upload(
          path,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );

    final url = _client.storage.from('avatars').getPublicUrl(path);
    return url;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> deleteAccount(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
    await _client.auth.signOut();
  }

  Future<void> submitVerificationRequest({
    required String userId,
    required File idPhoto,
    required File selfie,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // 1. Upload ID Photo
    final idPath = '$userId/verification/id_$timestamp.jpg';
    await _client.storage.from('verification-docs').upload(idPath, idPhoto);
    final idUrl = await _client.storage.from('verification-docs').createSignedUrl(idPath, 604800); // 7 days expiry

    // 2. Upload Selfie
    final selfiePath = '$userId/verification/selfie_$timestamp.jpg';
    await _client.storage.from('verification-docs').upload(selfiePath, selfie);
    final selfieUrl = await _client.storage.from('verification-docs').createSignedUrl(selfiePath, 604800); // 7 days expiry

    // 3. Insert into verification_requests
    await _client.from('verification_requests').insert({
      'user_id': userId,
      'id_photo_url': idUrl,
      'selfie_url': selfieUrl,
      'status': 'pending',
    });

    // 4. Update profile status
    await _client.from('profiles').update({
      'verification_status': 'pending',
    }).eq('id', userId);
  }

  Map<String, dynamic> calculateCompletion(Map<String, dynamic> profile) {
    int score = 0;
    final List<String> missing = [];

    if (profile['avatar_url'] != null) {
      score += 20;
    } else {
      missing.add('Add a profile photo');
    }

    final bio = profile['bio'] as String?;
    if (bio != null && bio.length >= 20) {
      score += 15;
    } else {
      missing.add('Write a bio');
    }

    if (profile['nationality'] != null) {
      score += 10;
    } else {
      missing.add('Set your nationality');
    }

    final interests = profile['interests'] as List?;
    if (interests != null && interests.length >= 3) {
      score += 15;
    } else {
      missing.add('Add at least 3 interests');
    }

    final languages = profile['languages'] as List?;
    if (languages != null && languages.isNotEmpty) {
      score += 10;
    } else {
      missing.add('Add a language');
    }

    if (profile['team_supported'] != null) {
      score += 10;
    } else {
      missing.add('Pick your team');
    }

    final countries = profile['countries_to_match'] as List?;
    if (countries != null && countries.length >= 3) {
      score += 15;
    } else {
      missing.add('Select countries to match');
    }

    if (profile['phone_number'] != null) {
      score += 5;
    } else {
      missing.add('Add phone number');
    }

    return {
      'score': score,
      'missing': missing.take(3).toList(),
    };
  }
}
