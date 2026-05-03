// Pure Dart: open/closed from optional daily hours + backend `openNow` / `openStatus`. [clock] = device-local.
// Same-day [open, close) or overnight when open > close (e.g. 22:00–06:00).

/// Wall-clock time on a generic “business day” (no calendar date).
final class LocalClockTime {
  const LocalClockTime(this.hour, this.minute);

  final int hour;
  final int minute;

  int get minutesSinceMidnight => hour * 60 + minute;

  String toHHmm() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// UI cell: normalized `HH:mm`, raw fallback, or em dash when empty / null.
  static String displayCell(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '—';
    }
    final t = tryParse(raw);
    if (t != null) {
      return t.toHHmm();
    }
    return raw.trim();
  }

  /// Accepts `"H:mm"` / `"HH:mm"` (24h). Whitespace trimmed.
  static LocalClockTime? tryParse(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return LocalClockTime(h, m);
  }
}

/// Visual bucket for markers and badges (green / red / neutral).
enum StationOpenTone { open, closed, unknown }

/// Inputs for [StationAvailability.resolve].
final class StationAvailabilityInput {
  const StationAvailabilityInput({
    this.opening,
    this.closing,
    this.serverOpenNow,
    this.serverOpenStatus,
  });

  final LocalClockTime? opening;
  final LocalClockTime? closing;

  /// Backend `openNow` when present (no daily hours or alongside partial hours).
  final bool? serverOpenNow;

  /// Backend `openStatus`: `open` | `closed` | `unknown` (case-insensitive). Unrecognized values ignored.
  final String? serverOpenStatus;
}

enum _ServerSignal { absent, open, closed, unknown }

/// How the API describes current openness when daily `openingTime`/`closingTime` are absent or partial.
_ServerSignal _readServerSignal({required bool? openNow, required String? openStatus}) {
  if (openNow == true) return _ServerSignal.open;
  if (openNow == false) return _ServerSignal.closed;
  final s = openStatus?.trim().toLowerCase();
  if (s == null || s.isEmpty) return _ServerSignal.absent;
  if (s == 'open') return _ServerSignal.open;
  if (s == 'closed') return _ServerSignal.closed;
  if (s == 'unknown') return _ServerSignal.unknown;
  return _ServerSignal.absent;
}

/// Result of resolving daily hours and/or backend `openNow` / `openStatus` — Vietnamese UI copy.
final class StationAvailability {
  const StationAvailability({
    required this.tone,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.usedSchedule,
  });

  final StationOpenTone tone;
  final String primaryLabel;
  final String? secondaryLabel;

  /// `true` when both opening and closing were valid and used for [tone].
  final bool usedSchedule;

  static StationAvailability resolve(
    StationAvailabilityInput input, {
    DateTime? clock,
  }) {
    final o = input.opening;
    final c = input.closing;
    final serverNow = input.serverOpenNow;
    final serverStatus = input.serverOpenStatus;

    if (o != null && c != null) {
      final now = clock ?? DateTime.now();
      final nowM = now.hour * 60 + now.minute;
      final openM = o.minutesSinceMidnight;
      final closeM = c.minutesSinceMidnight;
      if (openM == closeM) {
        return StationAvailability(
          tone: StationOpenTone.unknown,
          primaryLabel: 'Không xác định',
          secondaryLabel: 'Giờ mở và giờ đóng trùng nhau.',
          usedSchedule: false,
        );
      }

      final isOpenWindow = openM < closeM
          ? (nowM >= openM && nowM < closeM)
          : (nowM >= openM || nowM < closeM);

      if (isOpenWindow) {
        return StationAvailability(
          tone: StationOpenTone.open,
          primaryLabel: 'Đang mở cửa',
          secondaryLabel: 'Đóng lúc ${c.toHHmm()}',
          usedSchedule: true,
        );
      }

      final secondary = _closedSecondaryLine(
        sameDay: openM < closeM,
        nowM: nowM,
        open: o,
      );

      return StationAvailability(
        tone: StationOpenTone.closed,
        primaryLabel: 'Hiện đóng cửa',
        secondaryLabel: secondary,
        usedSchedule: true,
      );
    }

    if (o != null || c != null) {
      return _fromPartialHours(
        openNow: serverNow,
        openStatus: serverStatus,
      );
    }

    return _fromServerOnlyNoSchedule(
      openNow: serverNow,
      openStatus: serverStatus,
    );
  }

  static String _closedSecondaryLine({
    required bool sameDay,
    required int nowM,
    required LocalClockTime open,
  }) {
    final openM = open.minutesSinceMidnight;
    if (sameDay) {
      if (nowM < openM) {
        return 'Mở lúc ${open.toHHmm()}';
      }
      return 'Mở lúc ${open.toHHmm()} (ngày mai)';
    }
    return 'Mở lúc ${open.toHHmm()}';
  }

  static StationAvailability _fromPartialHours({
    required bool? openNow,
    required String? openStatus,
  }) {
    const base = 'Chưa đủ giờ mở và đóng để tự tính.';
    final sig = _readServerSignal(openNow: openNow, openStatus: openStatus);
    switch (sig) {
      case _ServerSignal.open:
        return StationAvailability(
          tone: StationOpenTone.open,
          primaryLabel: 'Đang mở cửa',
          secondaryLabel: '$base Hiển thị theo máy chủ.',
          usedSchedule: false,
        );
      case _ServerSignal.closed:
        return StationAvailability(
          tone: StationOpenTone.closed,
          primaryLabel: 'Hiện đóng cửa',
          secondaryLabel: '$base Hiển thị theo máy chủ.',
          usedSchedule: false,
        );
      case _ServerSignal.unknown:
        return StationAvailability(
          tone: StationOpenTone.unknown,
          primaryLabel: 'Chưa xác định',
          secondaryLabel: '$base Máy chủ báo không xác định.',
          usedSchedule: false,
        );
      case _ServerSignal.absent:
        return StationAvailability(
          tone: StationOpenTone.unknown,
          primaryLabel: 'Chưa xác định',
          secondaryLabel: '$base Chưa có trạng thái hiện tại từ máy chủ.',
          usedSchedule: false,
        );
    }
  }

  static StationAvailability _fromServerOnlyNoSchedule({
    required bool? openNow,
    required String? openStatus,
  }) {
    final sig = _readServerSignal(openNow: openNow, openStatus: openStatus);
    switch (sig) {
      case _ServerSignal.open:
        return StationAvailability(
          tone: StationOpenTone.open,
          primaryLabel: 'Đang mở cửa',
          secondaryLabel: 'Theo máy chủ — chưa có giờ mở/đóng để đối chiếu thời gian.',
          usedSchedule: false,
        );
      case _ServerSignal.closed:
        return StationAvailability(
          tone: StationOpenTone.closed,
          primaryLabel: 'Hiện đóng cửa',
          secondaryLabel: 'Theo máy chủ — chưa có giờ mở/đóng để đối chiếu thời gian.',
          usedSchedule: false,
        );
      case _ServerSignal.unknown:
        return StationAvailability(
          tone: StationOpenTone.unknown,
          primaryLabel: 'Chưa xác định',
          secondaryLabel: 'Máy chủ báo trạng thái hiện tại không xác định.',
          usedSchedule: false,
        );
      case _ServerSignal.absent:
        return StationAvailability(
          tone: StationOpenTone.unknown,
          primaryLabel: 'Chưa xác định',
          secondaryLabel: 'Chưa có giờ mở/đóng hoặc trạng thái hiện tại từ máy chủ.',
          usedSchedule: false,
        );
    }
  }
}
