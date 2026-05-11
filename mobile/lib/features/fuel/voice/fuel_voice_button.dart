import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/voice_recorder_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../data/models/fuel_tracking_models.dart';
import '../presentation/fuel_palette.dart';
import '../presentation/fuel_tracking_providers.dart';
import 'fuel_voice_repository.dart';
import 'parsed_fuel_transaction_dto.dart';

/// Nút mic 54x54 cạnh "Đổ nhiên liệu" — chỉ hiện khi `fuelVoiceFeatureEnabledProvider` = true.
/// Tap → mở modal recording → upload → mở form đổ nhiên liệu với data prefill từ Whisper.
class FuelVoiceButton extends ConsumerWidget {
  const FuelVoiceButton({super.key, required this.vehicleId});

  /// `null` khi user chưa có xe — nút disabled, tap show snack báo cần thêm xe trước.
  final int? vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureAsync = ref.watch(fuelVoiceFeatureEnabledProvider);
    final enabled = featureAsync.maybeWhen(data: (v) => v, orElse: () => false);
    if (!enabled) return const SizedBox.shrink();

    final canUse = vehicleId != null && vehicleId! > 0;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: canUse ? FuelPalette.primaryBlue : FuelPalette.primaryBlue.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (!canUse) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng thêm xe trước khi ghi lần đổ xăng.')),
              );
              return;
            }
            await _startVoiceFlow(context, ref, vehicleId!);
          },
          child: const SizedBox(
            width: 54,
            height: 54,
            child: Icon(Icons.mic_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  Future<void> _startVoiceFlow(BuildContext context, WidgetRef ref, int vehicleIdValue) async {
    final perm = await VoicePermission.ensureGranted();
    if (!context.mounted) return;
    if (perm != VoicePermissionResult.granted) {
      _showPermissionSnackbar(context, perm);
      return;
    }

    final result = await showModalBottomSheet<ParsedFuelTransactionDto?>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => const _VoiceRecordingSheet(),
    );

    if (!context.mounted || result == null) return;

    if (result.hasAmount) {
      await _pushFormWithPrefill(context, ref, vehicleIdValue, result);
    } else {
      await _showFailDialog(context, ref, vehicleIdValue, result);
    }
  }

  Future<void> _pushFormWithPrefill(
    BuildContext context,
    WidgetRef ref,
    int vehicleIdValue,
    ParsedFuelTransactionDto result,
  ) async {
    final prefill = FuelTransactionEditPrefill(
      transactionId: 0, // 0 = create mới (route bỏ qua editTransactionId)
      amountDong: result.amountVnd ?? 0,
      odometerKm: result.odometerKm?.toDouble(),
      transactionDate: result.transactionDate,
      note: null,
    );
    final ok = await context.push<bool>(
      '${AppRoute.addFuelTransaction.path}?vehicleId=$vehicleIdValue',
      extra: prefill,
    );
    if (ok == true && context.mounted) {
      ref.invalidate(fuelDashboardProvider);
    }
  }

  Future<void> _showFailDialog(
    BuildContext context,
    WidgetRef ref,
    int vehicleIdValue,
    ParsedFuelTransactionDto result,
  ) async {
    final action = await showDialog<_FailAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Không nhận diện được số tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hệ thống nghe được:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                result.rawText.isEmpty ? '(không nghe rõ)' : '"${result.rawText}"',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: result.rawText.isEmpty ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Bạn muốn:', style: TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_FailAction.openEmpty),
            child: const Text('Mở form trống'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(_FailAction.retry),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    switch (action) {
      case _FailAction.retry:
        await _startVoiceFlow(context, ref, vehicleIdValue);
        break;
      case _FailAction.openEmpty:
        final ok = await context.push<bool>(
          '${AppRoute.addFuelTransaction.path}?vehicleId=$vehicleIdValue',
        );
        if (ok == true && context.mounted) {
          ref.invalidate(fuelDashboardProvider);
        }
        break;
      case null:
        // User dismiss dialog — không làm gì.
        break;
    }
  }

  static void _showPermissionSnackbar(BuildContext context, VoicePermissionResult result) {
    final messenger = ScaffoldMessenger.of(context);
    if (result == VoicePermissionResult.permanentlyDenied) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Bạn đã từ chối quyền microphone. Mở Cài đặt để bật lại.'),
          action: SnackBarAction(label: 'Cài đặt', onPressed: VoicePermission.openSettings),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Cần cấp quyền microphone để ghi âm.')),
      );
    }
  }
}

enum _FailAction { retry, openEmpty }

/// Modal sheet 3 trạng thái: recording → transcribing → pop với DTO (hoặc null nếu user cancel).
class _VoiceRecordingSheet extends ConsumerStatefulWidget {
  const _VoiceRecordingSheet();

  @override
  ConsumerState<_VoiceRecordingSheet> createState() => _VoiceRecordingSheetState();
}

enum _SheetMode { recording, transcribing }

class _VoiceRecordingSheetState extends ConsumerState<_VoiceRecordingSheet> {
  static const Duration _maxDuration = Duration(seconds: 30);

  final _recorder = VoiceRecorderService();
  _SheetMode _mode = _SheetMode.recording;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      await _recorder.start();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không bắt đầu ghi âm được: $e')),
      );
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
      if (_elapsed >= _maxDuration) _stopAndUpload();
    });
  }

  Future<void> _cancel() async {
    _ticker?.cancel();
    await _recorder.cancel();
    if (mounted) Navigator.of(context).pop(null);
  }

  Future<void> _stopAndUpload() async {
    if (_mode != _SheetMode.recording) return;
    _ticker?.cancel();
    setState(() => _mode = _SheetMode.transcribing);

    final audio = await _recorder.stop();
    if (!mounted) return;
    if (audio == null) {
      Navigator.of(context).pop(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đoạn ghi quá ngắn — bấm giữ lâu hơn.')),
      );
      return;
    }

    try {
      final dto = await ref.read(fuelVoiceRepositoryProvider).parseVoice(
            filePath: audio.path,
            contentType: VoiceRecorderService.mimeType,
          );
      if (!mounted) return;
      Navigator.of(context).pop(dto);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(null);
      final msg = e is ApiException ? e.message : 'Lỗi gửi ghi âm: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _maxDuration - _elapsed;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (_mode == _SheetMode.recording) ..._buildRecording(remaining) else ..._buildTranscribing(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecording(Duration remaining) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _PulsingDot(),
          const SizedBox(width: 10),
          Text(
            'Đang ghi âm… ${_format(_elapsed)}',
            style: const TextStyle(
              color: Color(0xFFC62828),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Còn ${_format(remaining)} • Hãy nói số tiền và số km',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
      ),
      const SizedBox(height: 24),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Huỷ'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          FilledButton.icon(
            onPressed: _stopAndUpload,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Dừng và gửi'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildTranscribing() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: CircularProgressIndicator(),
      ),
      Text(
        'Đang chuyển giọng nói thành văn bản…',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
      ),
      const SizedBox(height: 16),
    ];
  }

  static String _format(Duration d) {
    if (d.isNegative) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl),
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFFD32F2F),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
