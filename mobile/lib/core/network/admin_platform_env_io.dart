import 'dart:io' show Platform;

/// Non-web: read machine env (handy for `flutter run` from a shell with exports).
String adminApiKeyFromRuntimeEnv() =>
    Platform.environment['HTTPM_ADMIN_API_KEY']?.trim() ?? '';

String adminBearerFromRuntimeEnv() =>
    Platform.environment['HTTPM_ADMIN_BEARER_TOKEN']?.trim() ?? '';
