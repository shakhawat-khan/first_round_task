import 'package:first_round_task/src/provider/global_provider.dart';
import 'package:first_round_task/src/theme/light_theme/light_theme.dart';
import 'package:first_round_task/src/utils/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      scaffoldMessengerKey: snackbarKey,
      routerConfig: ref.watch(goRouterProvider),
      title: 'First Round Project',
      theme: lightTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
