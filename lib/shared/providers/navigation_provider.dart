import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks which tab is active in MainScreen
final currentTabProvider = StateProvider<int>((ref) => 0);

// When a new match is made, holds the match data to auto-open in Chat
final selectedMatchProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);
