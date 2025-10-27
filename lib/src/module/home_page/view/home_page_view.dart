import 'package:first_round_task/src/module/home_page/api/home_page_api.dart';
import 'package:first_round_task/src/module/home_page/provider/home_page_provider.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() async {
    final notifier = ref.read(homePageNotifierProvider.notifier);
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore) {
      setState(() => _isLoadingMore = true);
      await notifier.loadMoreQuotes();
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homePageNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Famous Quotes",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: state.when(
        data: (data) {
          final quotes = data.quotes ?? [];
          if (quotes.isEmpty) {
            return const Center(child: Text("No quotes found"));
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(homePageNotifierProvider.notifier).refreshQuotes();
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: quotes.length + 1,
              itemBuilder: (context, index) {
                // 🔄 Show loader at bottom when loading more
                if (index == quotes.length) {
                  return _isLoadingMore
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : const SizedBox.shrink();
                }

                final q = quotes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '“${q.quote ?? ''}”',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '- ${q.author ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          // Check if it's a 403 error and navigate to login
          if (e is ApiException && e.code == 403) {
            // Use WidgetsBinding to navigate after the current frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please login again.'),
                ),
              );
            });
          }

          // Return error UI
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '❌ Error: $e',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Retry by refreshing the provider
                    ref.read(homePageNotifierProvider.notifier).refreshQuotes();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
