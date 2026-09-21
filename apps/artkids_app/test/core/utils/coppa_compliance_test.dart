import 'package:flutter_test/flutter_test.dart';

import 'package:artkids_app/core/utils/coppa_compliance.dart';

void main() {
  group('CoppaCompliance', () {
    group('isValidChildNickname', () {
      test('accepts valid nickname', () {
        expect(CoppaCompliance.isValidChildNickname('Bé Kem'), isTrue);
      });

      test('accepts short nickname (2 chars)', () {
        expect(CoppaCompliance.isValidChildNickname('An'), isTrue);
      });

      test('rejects nickname with phone number pattern', () {
        expect(CoppaCompliance.isValidChildNickname('0912345678'), isFalse);
      });

      test('rejects nickname with email', () {
        expect(CoppaCompliance.isValidChildNickname('be@gmail.com'), isFalse);
      });

      test('rejects empty nickname', () {
        expect(CoppaCompliance.isValidChildNickname(''), isFalse);
      });

      test('rejects single char nickname', () {
        expect(CoppaCompliance.isValidChildNickname('A'), isFalse);
      });

      test('rejects too long nickname (>20 chars)', () {
        expect(
          CoppaCompliance.isValidChildNickname('A' * 21),
          isFalse,
        );
      });
    });

    group('isAgeEligibleForKidMode', () {
      test('accepts age 4', () {
        expect(CoppaCompliance.isAgeEligibleForKidMode(4), isTrue);
      });

      test('accepts age 12', () {
        expect(CoppaCompliance.isAgeEligibleForKidMode(12), isTrue);
      });

      test('accepts age 8', () {
        expect(CoppaCompliance.isAgeEligibleForKidMode(8), isTrue);
      });

      test('rejects age 3', () {
        expect(CoppaCompliance.isAgeEligibleForKidMode(3), isFalse);
      });

      test('rejects age 13', () {
        expect(CoppaCompliance.isAgeEligibleForKidMode(13), isFalse);
      });
    });
  });
}
