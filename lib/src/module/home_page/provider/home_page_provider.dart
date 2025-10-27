import 'dart:async';

import 'package:first_round_task/src/module/home_page/model/home_page_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/home_page_api.dart';


final homePageNotifierProvider =
    AsyncNotifierProvider<HomePageNotifier, QuoteModel>(
      () => HomePageNotifier(),
    );

class HomePageNotifier extends AsyncNotifier<QuoteModel> {
  int _skip = 0;
  final int _limit = 10;
  bool _hasMore = true;

  @override
  FutureOr<QuoteModel> build() async {
    return await _fetchQuotes(reset: true);
  }

  /// 🔹 Private fetch function
  Future<QuoteModel> _fetchQuotes({bool reset = false}) async {
    if (reset) {
      _skip = 0;
      _hasMore = true;
    }

    if (!_hasMore) {
      // No more data to load
      return state.value ?? QuoteModel(quotes: []);
    }

    try {
      final data = await HomePageApi.getDashboardData(
        limit: _limit,
        skip: _skip,
      );

      // Update skip and check if there are more pages
      _skip += _limit;
      if (_skip >= (data.total ?? 0)) _hasMore = false;

      // Combine old + new quotes
      if (reset || state.value?.quotes == null) {
        return data;
      } else {
        final oldQuotes = state.value!.quotes ?? [];
        final newQuotes = [...oldQuotes, ...?data.quotes];
        return QuoteModel(
          quotes: newQuotes,
          total: data.total,
          skip: data.skip,
          limit: data.limit,
        );
      }
    } on ApiException {
      // Pass error to UI
      rethrow;
    } catch (e) {
      // Unexpected error
      throw Exception("Something went wrong: $e");
    }
  }

  /// 🔄 Refresh quotes (pull-to-refresh)
  Future<void> refreshQuotes() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchQuotes(reset: true));
  }

  /// 📜 Load next page (pagination)
  Future<void> loadMoreQuotes() async {
    if (state.isLoading || !_hasMore) return;
    state = AsyncValue.data(await _fetchQuotes());
  }
}
