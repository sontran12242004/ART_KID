import 'package:flutter_test/flutter_test.dart';

import 'package:artkids_app/core/network/ai_job_poller.dart';

void main() {
  group('AiJobStatus', () {
    test('has all expected values', () {
      expect(AiJobStatus.values, containsAll([
        AiJobStatus.pending,
        AiJobStatus.processing,
        AiJobStatus.done,
        AiJobStatus.failed,
      ]));
    });
  });
}
