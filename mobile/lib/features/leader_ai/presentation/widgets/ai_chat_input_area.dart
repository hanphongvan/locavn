import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/voice_recorder_service.dart';
import '../../data/leader_ai_api.dart';
import 'leader_ai_palette.dart';

/// Input bar dưới cùng — text field + nút mic + nút gửi.
///
/// 3 trạng thái:
/// - **idle**: TextField + nút mic (trái) + nút send (phải, mờ nếu empty)
/// - **recording**: ẩn TextField, hiện chip "Đang ghi NN s" + nút stop (đỏ) + nút huỷ
/// - **transcribing**: spinner + "Đang chuyển giọng nói…"
///
/// Sau transcribe thành công → tự động gọi [onSend] với text từ Whisper (UX C1 — auto-submit).
class AiChatInputArea extends ConsumerStatefulWidget {
  const AiChatInputArea({
    super.key,
    required this.onSend,
    required this.isSending,
  });

  final ValueChanged<String> onSend;
  final bool isSending;

  @override
  ConsumerState<AiChatInputArea> createState() => _AiChatInputAreaState();
}

enum _InputMode { idle, recording, transcribing }

class _AiChatInputAreaState extends ConsumerState<AiChatInputArea> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _recorder = VoiceRecorderService();

  bool _hasText = false;
  _InputMode _mode = _InputMode.idle;
  Duration _recordingElapsed = Duration.zero;
  Timer? _tickTimer;

  /// Hard cap thời lượng — Whisper xử lý ổn nhất với clip ≤ 30s, BE cũng giới hạn 5MB.
  static const Duration _maxRecordingDuration = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _recorder.cancel();
    _recorder.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitTyped() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _startRecording() async {
    if (widget.isSending || _mode != _InputMode.idle) return;

    final perm = await VoicePermission.ensureGranted();
    if (!mounted) return;
    if (perm != VoicePermissionResult.granted) {
      _showPermissionSnackbar(perm);
      return;
    }

    try {
      await _recorder.start();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Không bắt đầu ghi âm được: $e');
      return;
    }

    if (!mounted) return;
    _focusNode.unfocus();
    setState(() {
      _mode = _InputMode.recording;
      _recordingElapsed = Duration.zero;
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _recordingElapsed += const Duration(seconds: 1));
      if (_recordingElapsed >= _maxRecordingDuration) {
        _stopAndTranscribe();
      }
    });
  }

  Future<void> _stopAndTranscribe() async {
    _tickTimer?.cancel();
    _tickTimer = null;

    if (_mode != _InputMode.recording) return;
    setState(() => _mode = _InputMode.transcribing);

    final result = await _recorder.stop();
    if (!mounted) return;
    if (result == null) {
      setState(() => _mode = _InputMode.idle);
      _showErrorSnackbar('Đoạn ghi quá ngắn — bấm giữ lâu hơn.');
      return;
    }

    try {
      final text = await ref
          .read(leaderAiApiProvider)
          .transcribeVoice(filePath: result.path, contentType: VoiceRecorderService.mimeType);
      if (!mounted) return;
      // C1 — auto-submit text vào AI luôn.
      widget.onSend(text);
      setState(() => _mode = _InputMode.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _mode = _InputMode.idle);
      _showErrorSnackbar(e.toString());
    } finally {
      // Xoá file tạm sau khi upload xong (thành công hay fail).
      try {
        await VoiceRecorderService().cancel();
      } catch (_) {}
    }
  }

  Future<void> _cancelRecording() async {
    _tickTimer?.cancel();
    _tickTimer = null;
    await _recorder.cancel();
    if (!mounted) return;
    setState(() {
      _mode = _InputMode.idle;
      _recordingElapsed = Duration.zero;
    });
  }

  void _showPermissionSnackbar(VoicePermissionResult result) {
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

  void _showErrorSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: switch (_mode) {
          _InputMode.idle => _buildIdleRow(),
          _InputMode.recording => _buildRecordingRow(),
          _InputMode.transcribing => _buildTranscribingRow(),
        },
      ),
    );
  }

  Widget _buildIdleRow() {
    final disabled = !_hasText || widget.isSending;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _CircleIconButton(
          icon: Icons.mic_rounded,
          onTap: widget.isSending ? null : _startRecording,
          background: LeaderAiPalette.primaryNavy.withValues(alpha: 0.08),
          iconColor: LeaderAiPalette.primaryNavy,
          tooltip: 'Bấm để ghi âm câu hỏi',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitTyped(),
            enabled: !widget.isSending,
            decoration: InputDecoration(
              hintText: 'Nhập câu hỏi cho Loca AI...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: LeaderAiPalette.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: LeaderAiPalette.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: LeaderAiPalette.primaryNavy, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: widget.isSending ? null : Icons.send_rounded,
          loading: widget.isSending,
          onTap: disabled ? null : _submitTyped,
          background: disabled
              ? LeaderAiPalette.primaryNavy.withValues(alpha: 0.4)
              : LeaderAiPalette.primaryNavy,
          iconColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildRecordingRow() {
    final remaining = _maxRecordingDuration - _recordingElapsed;
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.close_rounded,
          onTap: _cancelRecording,
          background: Colors.grey.shade200,
          iconColor: Colors.grey.shade700,
          tooltip: 'Huỷ ghi âm',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE57373)),
            ),
            child: Row(
              children: [
                const _RecordingDot(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đang ghi âm… ${_formatDuration(_recordingElapsed)}',
                    style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '-${_formatDuration(remaining)}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: Icons.stop_rounded,
          onTap: _stopAndTranscribe,
          background: const Color(0xFFD32F2F),
          iconColor: Colors.white,
          tooltip: 'Dừng và gửi',
        ),
      ],
    );
  }

  Widget _buildTranscribingRow() {
    return Row(
      children: [
        const SizedBox(width: 12),
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Text(
          'Đang chuyển giọng nói thành văn bản…',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  static String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    this.icon,
    this.onTap,
    this.background,
    this.iconColor,
    this.tooltip,
    this.loading = false,
  });

  final IconData? icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? iconColor;
  final String? tooltip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background ?? LeaderAiPalette.primaryNavy,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icon, color: iconColor ?? Colors.white, size: 20),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _RecordingDot extends StatefulWidget {
  const _RecordingDot();

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot> with SingleTickerProviderStateMixin {
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
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFD32F2F),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
