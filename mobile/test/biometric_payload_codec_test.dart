import 'package:flutter_test/flutter_test.dart';
import 'package:httm_xangdau/core/auth/biometric/biometric_payload_codec.dart';

void main() {
  test('BiometricPayloadCodec roundtrip', () {
    const u = 'user@test';
    const p = 'secret-pass';
    final enc = BiometricPayloadCodec.encode(u, p);
    final dec = BiometricPayloadCodec.decode(enc);
    expect(dec, isNotNull);
    expect(dec!.username, u);
    expect(dec.password, p);
  });

  test('BiometricPayloadCodec rejects unknown version', () {
    expect(BiometricPayloadCodec.decode('{"v":99,"u":"a","p":"b"}'), isNull);
  });

  test('BiometricPayloadCodec rejects invalid json', () {
    expect(BiometricPayloadCodec.decode('not-json'), isNull);
  });
}
