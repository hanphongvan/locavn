import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/map/providers/goong/goong_style.dart';

void main() {
  group('GoongStyle', () {
    test('highlight URL chứa key + path đúng', () {
      final url = GoongStyle.highlight('TEST_KEY_123');
      expect(url,
          'https://tiles.goong.io/assets/goong_map_highlight.json?api_key=TEST_KEY_123');
    });

    test('satellite URL chứa key + path đúng', () {
      final url = GoongStyle.satellite('TEST_KEY_123');
      expect(url,
          'https://tiles.goong.io/assets/goong_satellite.json?api_key=TEST_KEY_123');
    });

    test('encode key có ký tự đặc biệt', () {
      // Uri.encodeQueryComponent dùng `+` cho space (HTML form encoding).
      final url = GoongStyle.highlight('a b&c=d');
      expect(url, contains('api_key=a+b%26c%3Dd'));
    });
  });
}
