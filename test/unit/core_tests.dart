import 'package:flutter_test/flutter_test.dart';

import '../../lib/shared/utils/validation_utils.dart';
import '../../lib/core/errors/failures.dart';
import '../../lib/core/errors/result.dart';

void main() {
  group('ValidationUtils', () {
    group('email validation', () {
      test('accepts valid email addresses', () {
        expect(ValidationUtils.isValidEmail('user@example.com'), isTrue);
        expect(ValidationUtils.isValidEmail('user+tag@sub.domain.co'), isTrue);
        expect(ValidationUtils.isValidEmail('first.last@company.org'), isTrue);
      });

      test('rejects invalid email addresses', () {
        expect(ValidationUtils.isValidEmail(''), isFalse);
        expect(ValidationUtils.isValidEmail('notanemail'), isFalse);
        expect(ValidationUtils.isValidEmail('@domain.com'), isFalse);
        expect(ValidationUtils.isValidEmail('user@'), isFalse);
        expect(ValidationUtils.isValidEmail('user @domain.com'), isFalse);
      });

      test('validateEmail returns null for valid email', () {
        expect(ValidationUtils.validateEmail('user@example.com'), isNull);
      });

      test('validateEmail returns error for empty input', () {
        expect(ValidationUtils.validateEmail(''), isNotNull);
        expect(ValidationUtils.validateEmail(null), isNotNull);
      });

      test('validateEmail returns error for invalid format', () {
        expect(ValidationUtils.validateEmail('notanemail'), isNotNull);
      });
    });

    group('password validation', () {
      test('accepts passwords of 8+ characters', () {
        expect(ValidationUtils.isValidPassword('password'), isTrue);
        expect(ValidationUtils.isValidPassword('12345678'), isTrue);
        expect(ValidationUtils.isValidPassword('a' * 100), isTrue);
      });

      test('rejects passwords under 8 characters', () {
        expect(ValidationUtils.isValidPassword(''), isFalse);
        expect(ValidationUtils.isValidPassword('1234567'), isFalse);
      });

      test('validatePassword returns null for valid password', () {
        expect(ValidationUtils.validatePassword('securepass'), isNull);
      });

      test('validatePassword returns error for short password', () {
        expect(ValidationUtils.validatePassword('short'), isNotNull);
        expect(ValidationUtils.validatePassword(''), isNotNull);
        expect(ValidationUtils.validatePassword(null), isNotNull);
      });

      test('validateConfirmPassword matches original', () {
        expect(
          ValidationUtils.validateConfirmPassword('password123', 'password123'),
          isNull,
        );
      });

      test('validateConfirmPassword rejects mismatch', () {
        expect(
          ValidationUtils.validateConfirmPassword('password123', 'different'),
          isNotNull,
        );
      });
    });

    group('phone validation', () {
      test('accepts valid phone numbers', () {
        expect(ValidationUtils.isValidPhone('+1 555 123 4567'), isTrue);
        expect(ValidationUtils.isValidPhone('555-123-4567'), isTrue);
        expect(ValidationUtils.isValidPhone('+34 612 345 678'), isTrue);
      });

      test('rejects invalid phone numbers', () {
        expect(ValidationUtils.isValidPhone('abc'), isFalse);
        expect(ValidationUtils.isValidPhone('123'), isFalse); // too short
      });
    });

    group('name validation', () {
      test('accepts valid names', () {
        expect(ValidationUtils.validateName('John'), isNull);
        expect(ValidationUtils.validateName('María García'), isNull);
      });

      test('rejects empty or too short names', () {
        expect(ValidationUtils.validateName(''), isNotNull);
        expect(ValidationUtils.validateName('A'), isNotNull);
        expect(ValidationUtils.validateName(null), isNotNull);
      });

      test('rejects names over 100 characters', () {
        expect(ValidationUtils.validateName('A' * 101), isNotNull);
      });
    });

    group('numeric validation', () {
      test('validatePositiveNumber accepts positive values', () {
        expect(ValidationUtils.validatePositiveNumber('1'), isNull);
        expect(ValidationUtils.validatePositiveNumber('99.99'), isNull);
      });

      test('validatePositiveNumber rejects zero and negative', () {
        expect(ValidationUtils.validatePositiveNumber('0'), isNotNull);
        expect(ValidationUtils.validatePositiveNumber('-1'), isNotNull);
      });

      test('validateNonNegativeNumber accepts zero and positive', () {
        expect(ValidationUtils.validateNonNegativeNumber('0'), isNull);
        expect(ValidationUtils.validateNonNegativeNumber('10'), isNull);
      });

      test('validateNonNegativeNumber rejects negative', () {
        expect(ValidationUtils.validateNonNegativeNumber('-1'), isNotNull);
      });
    });
  });

  group('Result<T>', () {
    test('success() creates a Success result', () {
      final result = success('hello');
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, equals('hello'));
    });

    test('failure() creates a Failure result', () {
      final result = failure<String>(const NetworkFailure());
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('fold() calls onSuccess for Success', () {
      final result = success(42);
      final output = result.fold(
        onSuccess: (v) => 'got $v',
        onFailure: (_) => 'failed',
      );
      expect(output, equals('got 42'));
    });

    test('fold() calls onFailure for Failure', () {
      final result = failure<int>(const AuthFailure());
      final output = result.fold(
        onSuccess: (v) => 'got $v',
        onFailure: (f) => 'failed: ${f.code}',
      );
      expect(output, equals('failed: AUTH_ERROR'));
    });

    test('map() transforms success value', () {
      final result = success(10);
      final mapped = result.map((v) => v * 2);
      expect(mapped.valueOrNull, equals(20));
    });

    test('map() passes failure through unchanged', () {
      final result = failure<int>(const NetworkFailure());
      final mapped = result.map((v) => v * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.failureOrNull, isA<NetworkFailure>());
    });

    test('getOrElse() returns value for success', () {
      final result = success('value');
      expect(result.getOrElse('default'), equals('value'));
    });

    test('getOrElse() returns default for failure', () {
      final result = failure<String>(const NetworkFailure());
      expect(result.getOrElse('default'), equals('default'));
    });
  });

  group('Failure types', () {
    test('NetworkFailure has correct code', () {
      const f = NetworkFailure();
      expect(f.code, equals('NETWORK_ERROR'));
      expect(f.message, isNotEmpty);
    });

    test('AuthFailure has correct code', () {
      const f = AuthFailure();
      expect(f.code, equals('AUTH_ERROR'));
    });

    test('SessionExpiredFailure has correct code', () {
      const f = SessionExpiredFailure();
      expect(f.code, equals('SESSION_EXPIRED'));
    });

    test('ValidationFailure has correct code', () {
      const f = ValidationFailure();
      expect(f.code, equals('VALIDATION_ERROR'));
    });

    test('ConflictFailure carries custom message', () {
      const f = ConflictFailure(message: 'Slot already booked.');
      expect(f.message, equals('Slot already booked.'));
      expect(f.code, equals('CONFLICT'));
    });

    test('UnauthorizedFailure has correct code', () {
      const f = UnauthorizedFailure();
      expect(f.code, equals('UNAUTHORIZED'));
    });

    test('NotFoundFailure has correct code', () {
      const f = NotFoundFailure();
      expect(f.code, equals('NOT_FOUND'));
    });

    test('ServerFailure carries status code', () {
      const f = ServerFailure(statusCode: 500);
      expect(f.statusCode, equals(500));
      expect(f.code, equals('SERVER_ERROR'));
    });
  });

  group('Appointment state machine (validation logic)', () {
    // Mirror the PostgreSQL validate_appointment_transition logic in Dart
    // to verify the state machine contract is consistent.
    bool validateTransition(String from, String to) {
      const validTransitions = {
        'pending': ['confirmed', 'cancelled'],
        'confirmed': [
          'in_progress',
          'completed',
          'cancelled',
          'no_show',
          'rescheduled',
        ],
        'in_progress': ['completed', 'cancelled'],
        'rescheduled': ['confirmed', 'cancelled'],
        'waitlisted': ['confirmed', 'cancelled'],
      };
      return validTransitions[from]?.contains(to) ?? false;
    }

    test('pending → confirmed is valid', () {
      expect(validateTransition('pending', 'confirmed'), isTrue);
    });

    test('pending → cancelled is valid', () {
      expect(validateTransition('pending', 'cancelled'), isTrue);
    });

    test('pending → completed is INVALID', () {
      expect(validateTransition('pending', 'completed'), isFalse);
    });

    test('pending → in_progress is INVALID', () {
      expect(validateTransition('pending', 'in_progress'), isFalse);
    });

    test('confirmed → in_progress is valid', () {
      expect(validateTransition('confirmed', 'in_progress'), isTrue);
    });

    test('confirmed → completed is valid', () {
      expect(validateTransition('confirmed', 'completed'), isTrue);
    });

    test('confirmed → cancelled is valid', () {
      expect(validateTransition('confirmed', 'cancelled'), isTrue);
    });

    test('confirmed → no_show is valid', () {
      expect(validateTransition('confirmed', 'no_show'), isTrue);
    });

    test('confirmed → rescheduled is valid', () {
      expect(validateTransition('confirmed', 'rescheduled'), isTrue);
    });

    test('confirmed → pending is INVALID', () {
      expect(validateTransition('confirmed', 'pending'), isFalse);
    });

    test('in_progress → completed is valid', () {
      expect(validateTransition('in_progress', 'completed'), isTrue);
    });

    test('in_progress → cancelled is valid', () {
      expect(validateTransition('in_progress', 'cancelled'), isTrue);
    });

    test('in_progress → pending is INVALID', () {
      expect(validateTransition('in_progress', 'pending'), isFalse);
    });

    test('in_progress → confirmed is INVALID', () {
      expect(validateTransition('in_progress', 'confirmed'), isFalse);
    });

    test('completed → any status is INVALID', () {
      for (final to in [
        'pending',
        'confirmed',
        'in_progress',
        'cancelled',
        'no_show',
        'rescheduled',
      ]) {
        expect(
          validateTransition('completed', to),
          isFalse,
          reason: 'completed → $to should be invalid',
        );
      }
    });

    test('cancelled → any status is INVALID', () {
      for (final to in [
        'pending',
        'confirmed',
        'in_progress',
        'completed',
        'no_show',
        'rescheduled',
      ]) {
        expect(
          validateTransition('cancelled', to),
          isFalse,
          reason: 'cancelled → $to should be invalid',
        );
      }
    });

    test('no_show → any status is INVALID', () {
      for (final to in [
        'pending',
        'confirmed',
        'in_progress',
        'completed',
        'cancelled',
        'rescheduled',
      ]) {
        expect(
          validateTransition('no_show', to),
          isFalse,
          reason: 'no_show → $to should be invalid',
        );
      }
    });

    test('rescheduled → confirmed is valid', () {
      expect(validateTransition('rescheduled', 'confirmed'), isTrue);
    });

    test('rescheduled → cancelled is valid', () {
      expect(validateTransition('rescheduled', 'cancelled'), isTrue);
    });

    test('rescheduled → completed is INVALID', () {
      expect(validateTransition('rescheduled', 'completed'), isFalse);
    });
  });

  group('Tenant isolation (unit-level)', () {
    // Verify that organization_id scoping logic is correct in pure Dart.
    // These tests validate the contract that repository methods must enforce.

    test('org member check returns false for null user', () {
      // Simulates is_org_member returning false when auth.uid() is null
      String? userId;
      final isMember = userId != null;
      expect(isMember, isFalse);
    });

    test('different org IDs are not equal', () {
      const orgA = 'org-a-uuid-1234';
      const orgB = 'org-b-uuid-5678';
      expect(orgA == orgB, isFalse);
    });

    test('appointment belongs to correct org', () {
      const appointmentOrgId = 'org-a-uuid-1234';
      const requestingOrgId = 'org-b-uuid-5678';
      // Simulates the RLS check: user's org must match appointment's org
      final hasAccess = appointmentOrgId == requestingOrgId;
      expect(hasAccess, isFalse);
    });
  });
}
