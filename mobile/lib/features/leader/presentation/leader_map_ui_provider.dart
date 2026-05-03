import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/leader_map_ui_state.dart';

final leaderMapUiProvider = StateProvider<LeaderMapUiState>((ref) => const LeaderMapUiState());
