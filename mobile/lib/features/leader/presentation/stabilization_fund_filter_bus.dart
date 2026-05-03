import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cầu nối để [LeaderMainScreen] (AppBar) gọi mở lọc kỳ từ [StabilizationFundScreen].
final stabilizationFundFilterBusProvider = Provider<StabilizationFundFilterBus>((ref) {
  final bus = StabilizationFundFilterBus();
  ref.onDispose(bus.clear);
  return bus;
});

final class StabilizationFundFilterBus {
  void Function()? _onOpen;

  void register(void Function()? fn) => _onOpen = fn;

  void clear() => _onOpen = null;

  void open() => _onOpen?.call();
}
