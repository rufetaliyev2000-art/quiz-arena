import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../data/match_history_repository.dart';

final matchHistoryRepositoryProvider = Provider<MatchHistoryRepository>((ref) {
  return MatchHistoryRepository(ref.watch(supabaseClientProvider));
});

final matchHistoryProvider = FutureProvider<List<MatchHistoryEntry>>((ref) async {
  return ref.watch(matchHistoryRepositoryProvider).getHistory();
});
