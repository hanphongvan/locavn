import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account/account_screen.dart';

/// Tab **Tài khoản** (bottom navigation).
class MoreShellPage extends ConsumerWidget {
  const MoreShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AccountScreen();
  }
}
