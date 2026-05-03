import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/app_info/package_info_provider.dart';
import '../account_palette.dart';

/// Dòng phiên bản ứng dụng (versionName + buildNumber từ [PackageInfo]).
class AppVersionFooter extends ConsumerWidget {
  const AppVersionFooter({super.key});

  static TextStyle _style(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AccountPalette.textSecondary.withValues(alpha: 0.9),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packageInfoProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: async.when(
        loading: () => Text('Phiên bản —', style: _style(context)),
        error: (Object _, StackTrace _) => const SizedBox.shrink(),
        data: (info) => Text(
          'Phiên bản ${info.version} (${info.buildNumber})',
          style: _style(context),
        ),
      ),
    );
  }
}
