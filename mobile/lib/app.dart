import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/router/deep_link_listener.dart';
import 'shared/theme/app_theme.dart';

class HttmXangdauApp extends ConsumerWidget {
  const HttmXangdauApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe to OS-level deep links (httmxd://...). Side-effect provider —
    // watching here keeps it alive for the whole app lifetime.
    ref.watch(deepLinkListenerProvider);
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'LocaVN',
      theme: AppTheme.light(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
