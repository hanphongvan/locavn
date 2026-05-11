import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Wrapper mỏng quanh `record` package — ghi audio m4a (AAC LC) vào thư mục tạm,
/// trả file path để upload lên backend `/api/leader-ai/voice/transcribe`.
///
/// UX: caller gọi [start] → sau đó [stop] để lấy file path. [cancel] huỷ và xoá file tạm.
/// Permission check được tách ra [VoicePermission.ensureGranted].
class VoiceRecorderService {
  VoiceRecorderService();

  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  DateTime? _startedAt;

  /// Mime-type khớp với accept list của backend. Dùng WAV vì `record_ios` 6.x có bug
  /// với AAC LC trên iOS 17/18 (file 28 bytes, chỉ có header, không samples).
  static const String mimeType = 'audio/wav';

  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _recorder.dispose();
  }

  /// Trả `true` nếu đang ghi.
  Future<bool> get isRecording => _recorder.isRecording();

  /// Tạo file path tạm + start record AAC trong container m4a.
  /// Caller phải đảm bảo permission đã grant trước khi gọi (xem [VoicePermission]).
  Future<void> start() async {
    if (await _recorder.isRecording()) {
      // Idempotent — nếu đã ghi thì không restart.
      return;
    }
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/locaai_voice_$ts.wav';

    final hasPermission = await _recorder.hasPermission();
    debugPrint('[voice] start: hasPermission=$hasPermission path=$path');

    await _recorder.start(
      const RecordConfig(
        // WAV PCM 16-bit — bypass bug AAC LC trên iOS 17/18. File ~32KB/s ở 16kHz mono.
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _currentPath = path;
    _startedAt = DateTime.now();

    // Verify recorder thực sự đang record sau khi start() trả về.
    final actuallyRecording = await _recorder.isRecording();
    debugPrint('[voice] start: isRecording=$actuallyRecording');
  }

  /// Stop record, trả file path đã ghi. Trả null nếu chưa start hoặc duration < 500ms.
  Future<({String path, Duration duration})?> stop() async {
    if (!await _recorder.isRecording()) {
      return null;
    }
    final returnedPath = await _recorder.stop();
    final path = returnedPath ?? _currentPath;
    final startedAt = _startedAt;
    _currentPath = null;
    _startedAt = null;

    if (path == null) return null;
    final duration = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);

    // Log size để debug "file 1KB không có audio samples".
    int fileSize = -1;
    try {
      fileSize = await File(path).length();
    } catch (_) {}
    debugPrint('[voice] stop: path=$path duration=${duration.inMilliseconds}ms size=${fileSize}B');

    if (duration < const Duration(milliseconds: 500)) {
      // Quá ngắn — xoá file rác, caller xử lý null = warn user.
      await _safeDelete(path);
      return null;
    }
    return (path: path, duration: duration);
  }

  /// Huỷ và xoá file tạm — gọi khi user cancel hoặc lỗi giữa chừng.
  Future<void> cancel() async {
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    final path = _currentPath;
    _currentPath = null;
    _startedAt = null;
    if (path != null) await _safeDelete(path);
  }

  static Future<void> _safeDelete(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Ignore — file tạm, OS sẽ dọn.
    }
  }
}

/// Helper xin permission microphone — gọi từ UI trước khi [VoiceRecorderService.start].
class VoicePermission {
  VoicePermission._();

  /// Trả [VoicePermissionResult.granted] nếu OK, hoặc lý do từ chối để UI show snackbar.
  static Future<VoicePermissionResult> ensureGranted() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return VoicePermissionResult.granted;
    if (status.isPermanentlyDenied) return VoicePermissionResult.permanentlyDenied;

    final requested = await Permission.microphone.request();
    if (requested.isGranted) return VoicePermissionResult.granted;
    if (requested.isPermanentlyDenied) return VoicePermissionResult.permanentlyDenied;
    return VoicePermissionResult.denied;
  }

  /// Mở Settings để user bật permission tay (khi permanentlyDenied).
  static Future<bool> openSettings() => openAppSettings();
}

enum VoicePermissionResult { granted, denied, permanentlyDenied }
