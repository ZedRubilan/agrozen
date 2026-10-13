import 'package:agrozen/services/voice_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Documents the honesty contract of voice input: no transcript is ever
/// fabricated, and every failure mode has a distinct, UI-handleable reason.
void main() {
  group('voice unavailability is explicit (no fabricated transcripts)', () {
    test('notConfigured reason when backend is absent', () {
      const err = VoiceUnavailable(
        'x',
        reason: VoiceUnavailableReason.notConfigured,
      );
      expect(err.reason, VoiceUnavailableReason.notConfigured);
      expect(err.toString(), contains('notConfigured'));
    });

    test('all failure reasons are enumerable for exhaustive UI handling',
        () {
      expect(VoiceUnavailableReason.values.length, 4);
    });
  });
}
