import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/features/stations/domain/station_availability.dart';

void main() {
  group('LocalClockTime.tryParse', () {
    test('parses H:mm and HH:mm', () {
      expect(LocalClockTime.tryParse('8:30')!.toHHmm(), '08:30');
      expect(LocalClockTime.tryParse('08:05')!.toHHmm(), '08:05');
      expect(LocalClockTime.tryParse('  22:00  ')!.toHHmm(), '22:00');
    });

    test('rejects invalid', () {
      expect(LocalClockTime.tryParse(null), isNull);
      expect(LocalClockTime.tryParse(''), isNull);
      expect(LocalClockTime.tryParse('25:00'), isNull);
      expect(LocalClockTime.tryParse('12:99'), isNull);
      expect(LocalClockTime.tryParse('noon'), isNull);
    });
  });

  group('StationAvailability.resolve same-day', () {
    test('open inside window', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(8, 0),
          closing: LocalClockTime(22, 0),
        ),
        clock: DateTime(2026, 4, 18, 12, 0),
      );
      expect(r.tone, StationOpenTone.open);
      expect(r.usedSchedule, isTrue);
      expect(r.primaryLabel, 'Đang mở cửa');
      expect(r.secondaryLabel, 'Đóng lúc 22:00');
    });

    test('closed before opening', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(8, 0),
          closing: LocalClockTime(22, 0),
        ),
        clock: DateTime(2026, 4, 18, 6, 0),
      );
      expect(r.tone, StationOpenTone.closed);
      expect(r.secondaryLabel, 'Mở lúc 08:00');
    });

    test('closed after close same day', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(8, 0),
          closing: LocalClockTime(22, 0),
        ),
        clock: DateTime(2026, 4, 18, 23, 0),
      );
      expect(r.tone, StationOpenTone.closed);
      expect(r.secondaryLabel, 'Mở lúc 08:00 (ngày mai)');
    });
  });

  group('StationAvailability.resolve overnight', () {
    test('open late evening', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(22, 0),
          closing: LocalClockTime(6, 0),
        ),
        clock: DateTime(2026, 4, 18, 23, 0),
      );
      expect(r.tone, StationOpenTone.open);
      expect(r.secondaryLabel, 'Đóng lúc 06:00');
    });

    test('open early morning', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(22, 0),
          closing: LocalClockTime(6, 0),
        ),
        clock: DateTime(2026, 4, 18, 3, 0),
      );
      expect(r.tone, StationOpenTone.open);
    });

    test('closed between morning close and evening open', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(22, 0),
          closing: LocalClockTime(6, 0),
        ),
        clock: DateTime(2026, 4, 18, 12, 0),
      );
      expect(r.tone, StationOpenTone.closed);
      expect(r.secondaryLabel, 'Mở lúc 22:00');
    });
  });

  group('fallback server openNow / openStatus (no daily hours)', () {
    test('openNow true', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          serverOpenNow: true,
        ),
      );
      expect(r.tone, StationOpenTone.open);
      expect(r.usedSchedule, isFalse);
      expect(r.primaryLabel, 'Đang mở cửa');
      expect(r.secondaryLabel, contains('máy chủ'));
    });

    test('openStatus Open case-insensitive', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          serverOpenStatus: ' Open ',
        ),
      );
      expect(r.tone, StationOpenTone.open);
      expect(r.primaryLabel, 'Đang mở cửa');
    });

    test('openNow false beats conflicting openStatus', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          serverOpenNow: false,
          serverOpenStatus: 'open',
        ),
      );
      expect(r.tone, StationOpenTone.closed);
    });

    test('no signals — neutral unknown', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(),
      );
      expect(r.tone, StationOpenTone.unknown);
      expect(r.secondaryLabel, contains('Chưa có'));
    });

    test('openStatus unknown', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          serverOpenStatus: 'unknown',
        ),
      );
      expect(r.tone, StationOpenTone.unknown);
      expect(r.secondaryLabel, contains('không xác định'));
    });

    test('partial hours uses server openNow with note', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(8, 0),
          closing: null,
          serverOpenNow: false,
        ),
      );
      expect(r.tone, StationOpenTone.closed);
      expect(r.secondaryLabel, contains('Chưa đủ'));
      expect(r.secondaryLabel, contains('máy chủ'));
    });

    test('partial hours no server — unknown', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(8, 0),
          closing: null,
        ),
      );
      expect(r.tone, StationOpenTone.unknown);
      expect(r.secondaryLabel, contains('Chưa đủ'));
      expect(r.secondaryLabel, contains('Chưa có trạng thái'));
    });

    test('equal open and close is unknown', () {
      final r = StationAvailability.resolve(
        const StationAvailabilityInput(
          opening: LocalClockTime(8, 0),
          closing: LocalClockTime(8, 0),
        ),
      );
      expect(r.tone, StationOpenTone.unknown);
      expect(r.usedSchedule, isFalse);
    });
  });
}
