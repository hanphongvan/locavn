import 'package:flutter/material.dart';

/// Shared with [GoRouter] and [AuthHttpInterceptor] so 401 handling can navigate without importing the full router graph.
final appRootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
