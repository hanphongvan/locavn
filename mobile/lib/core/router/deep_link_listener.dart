import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_console_log.dart';
import 'app_router.dart';

/// Custom URL scheme used for incoming deep links (reset-password email, …).
const String _httmxdScheme = 'httmxd';

/// Translates `httmxd://reset-password?token=abc` (host-as-path form mandated by
/// backend) into the GoRouter path `/reset-password?token=abc`.
///
/// Returns `null` if [uri] is not a recognised custom-scheme link.
String? translateHttmxdUri(Uri uri) {
  if (uri.scheme != _httmxdScheme) return null;

  // Form 1 — host carries the first path segment (`httmxd://reset-password?token=abc`).
  // Form 2 — empty host with leading slash (`httmxd:///reset-password?token=abc`).
  final segment = uri.host.isNotEmpty ? '/${uri.host}' : '';
  final path = '$segment${uri.path}';
  if (path.isEmpty) return null;

  return uri.hasQuery ? '$path?${uri.query}' : path;
}

/// Subscribes to OS-level deep link events (cold-start + warm) and pushes them
/// through [goRouterProvider]. Cancelled automatically when the provider is disposed.
final deepLinkListenerProvider = Provider<void>((ref) {
  final appLinks = AppLinks();
  StreamSubscription<Uri>? sub;

  Future<void> handleUri(Uri uri) async {
    final path = translateHttmxdUri(uri);
    if (path == null) return;
    final router = ref.read(goRouterProvider);
    debugPrint('[httm_xangdau] DeepLink route → $path');
    router.go(path);
  }

  // Initial link — captured if the app was cold-started by an intent.
  appLinks.getInitialLink().then((uri) {
    if (uri != null) handleUri(uri);
  }).catchError((Object e, StackTrace st) {
    logAppError('DeepLink getInitialLink', e, st);
  });

  // Subsequent links while app is alive.
  sub = appLinks.uriLinkStream.listen(
    handleUri,
    onError: (Object e, StackTrace st) {
      logAppError('DeepLink stream', e, st);
    },
  );

  ref.onDispose(() {
    sub?.cancel();
  });
});
