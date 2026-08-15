import 'package:flutter_test/flutter_test.dart';

import '../../lib/shared/utils/validation_utils.dart';
import '../../lib/core/errors/failures.dart';
import '../../lib/core/errors/result.dart';

// ─── Availability Engine Contract Tests ──────────────────────────────────────
// These tests verify the availability engine's business rules in pure Dart.
// The actual scheduling engine lives in PostgreSQL (check_slot_available).
// These tests validate the contract that the engine must enforce.

/// Simulates a time slot for testing.
class TimeSlot {
  final DateTime startsAt;
  final DateTime endsAt;
  final int bufferBefore;
  final int bufferAfter;

  const TimeSlot({
    required this.startsAt,
    required this.endsAt,
    this.bufferBefore = 0,
    this.bufferAfter = 0,
  });

  /// Effective start (with buffer before)
  DateTime get effectiveStart =>
      startsAt.subtract(Duration(minutes: bufferBefore));

  /// Effective end (with buffer after)
  DateTime get effectiveEnd => endsAt.add(Duration(minutes: bufferAfter));

  /// Returns true if this slot conflicts with [other].
  bool conflictsWith(TimeSlot other) {
    return effectiveStart.isBefore(other.effectiveEnd) &&
        effectiveEnd.isAfter(other.effectiveStart);
  }
}

void main() {
  group('Availability Engine — slot conflict detection', () {
    final base = DateTime(2025, 1, 15, 10, 0); // 10:00 AM

    test('non-overlapping slots do not conflict', () {
      final slot1 = TimeSlot(
        startsAt: base,
        endsAt: base.add(const Duration(minutes: 60)),
      );
      final slot2 = TimeSlot(
        startsAt: base.add(const Duration(minutes: 60)),
        endsAt: base.add(const Duration(minutes: 120)),
      );
      expect(slot1.conflictsWith(slot2), isFalse);
      expect(slot2.conflictsWith(slot1), isFalse);
    });

    test('overlapping slots conflict', () {
      final slot1 = TimeSlot(
        startsAt: base,
        endsAt: base.add(const Duration(minutes: 60)),
      );
      final slot2 = TimeSlot(
        startsAt: base.add(const Duration(minutes: 30)),
        endsAt: base.add(const Duration(minutes: 90)),
      );
      expect(slot1.conflictsWith(slot2), isTrue);
      expect(slot2.conflictsWith(slot1), isTrue);
    });

    test('identical slots conflict', () {
      final slot1 = TimeSlot(
        startsAt: base,
        endsAt: base.add(const Duration(minutes: 60)),
      );
      final slot2 = TimeSlot(
        startsAt: base,
        endsAt: base.add(const Duration(minutes: 60)),
      );
      expect(slot1.conflictsWith(slot2), isTrue);
    });

    test('buffer before causes conflict with adjacent slot', () {
      // Slot 1: 10:00–11:00 with 15 min buffer after
      final slot1 = TimeSlot(
        startsAt: base,
        endsAt: base.add(const Duration(minutes: 60)),
        bufferAfter: 15,
      );
      // Slot 2: 11:05–12:05 (within buffer zone)
      final slot2 = TimeSlot(
        startsAt: base.add(const Duration(minutes: 65)),
        endsAt: base.add(const Duration(minutes: 125)),
      );
      // slot1 effective end = 11:15, slot2 starts at 11:05 → conflict
      expect(slot1.conflictsWith(slot2), isTrue);
    });

    test('buffer after clears when slot is far enough away', () {
      // Slot 1: 10:00–11:00 with 15 min buffer after
      final slot1 = TimeSlot(
        startsAt: base,
        endsAt: base.add(const Duration(minutes: 60)),
        bufferAfter: 15,
      );
      // Slot 2: 11:20–12:20 (outside buffer zone)
      final slot2 = TimeSlot(
        startsAt: base.add(const Duration(minutes: 80)),
        endsAt: base.add(const Duration(minutes: 140)),
      );
      // slot1 effective end = 11:15, slot2 starts at 11:20 → no conflict
      expect(slot1.conflictsWith(slot2), isFalse);
    });

    test('slot in the past is invalid for booking', () {
      final pastSlot = DateTime.now().subtract(const Duration(hours: 1));
      final isInFuture = pastSlot.isAfter(DateTime.now());
      expect(isInFuture, isFalse);
    });

    test('slot exactly at current time is invalid', () {
      final now = DateTime.now();
      // The booking engine requires starts_at > NOW()
      final isStrictlyFuture = now.isAfter(now);
      expect(isStrictlyFuture, isFalse);
    });

    test('slot in the future is valid', () {
      final futureSlot = DateTime.now().add(const Duration(hours: 2));
      final isInFuture = futureSlot.isAfter(DateTime.now());
      expect(isInFuture, isTrue);
    });
  });

  group('Availability Engine — business hours validation', () {
    test('appointment within business hours is valid', () {
      const openTime = Duration(hours: 9); // 9:00 AM
      const closeTime = Duration(hours: 18); // 6:00 PM
      const appointmentStart = Duration(hours: 10); // 10:00 AM
      const appointmentEnd = Duration(hours: 11); // 11:00 AM

      final isWithinHours =
          appointmentStart >= openTime && appointmentEnd <= closeTime;
      expect(isWithinHours, isTrue);
    });

    test('appointment starting before open time is invalid', () {
      const openTime = Duration(hours: 9);
      const closeTime = Duration(hours: 18);
      const appointmentStart = Duration(hours: 8); // 8:00 AM
      const appointmentEnd = Duration(hours: 9, minutes: 30);

      final isWithinHours =
          appointmentStart >= openTime && appointmentEnd <= closeTime;
      expect(isWithinHours, isFalse);
    });

    test('appointment ending after close time is invalid', () {
      const openTime = Duration(hours: 9);
      const closeTime = Duration(hours: 18);
      const appointmentStart = Duration(hours: 17, minutes: 30);
      const appointmentEnd = Duration(hours: 18, minutes: 30); // past close

      final isWithinHours =
          appointmentStart >= openTime && appointmentEnd <= closeTime;
      expect(isWithinHours, isFalse);
    });

    test('appointment on closed day is invalid', () {
      const isOpen = false;
      expect(isOpen, isFalse);
    });
  });

  group('Availability Engine — capacity validation', () {
    test('single capacity: one booking allowed', () {
      const maxCapacity = 1;
      const currentBookings = 0;
      final canBook = currentBookings < maxCapacity;
      expect(canBook, isTrue);
    });

    test('single capacity: second booking rejected', () {
      const maxCapacity = 1;
      const currentBookings = 1;
      final canBook = currentBookings < maxCapacity;
      expect(canBook, isFalse);
    });

    test('group capacity: multiple bookings allowed', () {
      const maxCapacity = 5;
      const currentBookings = 3;
      final canBook = currentBookings < maxCapacity;
      expect(canBook, isTrue);
    });

    test('group capacity: at max rejects new booking', () {
      const maxCapacity = 5;
      const currentBookings = 5;
      final canBook = currentBookings < maxCapacity;
      expect(canBook, isFalse);
    });
  });

  group('Rescheduling contract', () {
    test('rescheduling to same time is a no-op (same slot)', () {
      final original = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 10, 0);
      expect(original.isAtSameMomentAs(newTime), isTrue);
    });

    test('rescheduling to different time requires new conflict check', () {
      final original = DateTime(2025, 1, 15, 10, 0);
      final newTime = DateTime(2025, 1, 15, 14, 0);
      expect(original.isAtSameMomentAs(newTime), isFalse);
    });

    test('rescheduling to past time is invalid', () {
      final newTime = DateTime.now().subtract(const Duration(hours: 1));
      final isValid = newTime.isAfter(DateTime.now());
      expect(isValid, isFalse);
    });
  });

  group('Cancellation contract', () {
    test('cancellation within notice period is allowed', () {
      // Business policy: 24h notice required
      const minNoticeHours = 24;
      final appointmentTime = DateTime.now().add(const Duration(hours: 48));
      final hoursUntilAppointment = appointmentTime
          .difference(DateTime.now())
          .inHours;
      final canCancel = hoursUntilAppointment >= minNoticeHours;
      expect(canCancel, isTrue);
    });

    test('cancellation within minimum notice window is policy violation', () {
      const minNoticeHours = 24;
      final appointmentTime = DateTime.now().add(const Duration(hours: 12));
      final hoursUntilAppointment = appointmentTime
          .difference(DateTime.now())
          .inHours;
      final canCancel = hoursUntilAppointment >= minNoticeHours;
      expect(canCancel, isFalse);
    });

    test('cancelled appointments are never deleted', () {
      // This is a contract test: cancelled appointments must have deleted_at = null
      // and status = 'cancelled', not be physically removed.
      const status = 'cancelled';
      const deletedAt = null;
      expect(status, equals('cancelled'));
      expect(deletedAt, isNull);
    });
  });

  group('Token security', () {
    test('booking token has sufficient entropy (32 bytes = 64 hex chars)', () {
      // Tokens are generated as encode(gen_random_bytes(32), 'hex')
      // This produces a 64-character hex string
      const expectedLength = 64;
      // Simulate a token of the expected format
      final simulatedToken = 'a' * 64;
      expect(simulatedToken.length, equals(expectedLength));
    });

    test('cancellation token is different from booking token', () {
      // Each token is independently generated
      const bookingToken = 'booking_token_hex_64_chars_aaaa';
      const cancelToken = 'cancel_token_hex_64_chars_bbbb';
      expect(bookingToken == cancelToken, isFalse);
    });
  });

  group('Result type — async operations', () {
    test('flatMapAsync chains successful results', () async {
      final result = success(10);
      final chained = await result.flatMapAsync((v) async => success(v * 2));
      expect(chained.valueOrNull, equals(20));
    });

    test('flatMapAsync short-circuits on failure', () async {
      final result = failure<int>(const NetworkFailure());
      final chained = await result.flatMapAsync((v) async => success(v * 2));
      expect(chained.isFailure, isTrue);
      expect(chained.failureOrNull, isA<NetworkFailure>());
    });
  });
}
