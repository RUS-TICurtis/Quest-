import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/interaction/create/data/models/create_submission_payload.dart';

void main() {
  group('CreateSubmissionPayload Model Tests', () {
    test('instantiates correctly for Text mode', () {
      const payload = CreateSubmissionPayload(
        mediaType: CreateMediaType.text,
        textContent: 'Morning workout completed!',
        textBackgroundColor: Color(0xFF2563EB),
        linkedQuestId: 'quest-123',
        linkedQuestTitle: 'Morning 5km Run',
      );

      expect(payload.isText, isTrue);
      expect(payload.isImage, isFalse);
      expect(payload.isVideo, isFalse);
      expect(payload.textContent, 'Morning workout completed!');
      expect(payload.textBackgroundColor, const Color(0xFF2563EB));
      expect(payload.linkedQuestId, 'quest-123');
      expect(payload.linkedQuestTitle, 'Morning 5km Run');
    });

    test('instantiates correctly for Image mode', () {
      const payload = CreateSubmissionPayload(
        mediaType: CreateMediaType.image,
        mediaPath: '/data/user/0/com.quest/cache/photo.jpg',
      );

      expect(payload.isImage, isTrue);
      expect(payload.isText, isFalse);
      expect(payload.isVideo, isFalse);
      expect(payload.mediaPath, '/data/user/0/com.quest/cache/photo.jpg');
      expect(payload.textContent, isNull);
    });

    test('instantiates correctly for Video mode', () {
      const payload = CreateSubmissionPayload(
        mediaType: CreateMediaType.video,
        mediaPath: '/data/user/0/com.quest/cache/vlog.mp4',
        linkedQuestId: 'quest-999',
      );

      expect(payload.isVideo, isTrue);
      expect(payload.isImage, isFalse);
      expect(payload.isText, isFalse);
      expect(payload.mediaPath, '/data/user/0/com.quest/cache/vlog.mp4');
      expect(payload.linkedQuestId, 'quest-999');
    });

    test('copyWith preserves and overrides fields correctly', () {
      const original = CreateSubmissionPayload(
        mediaType: CreateMediaType.text,
        textContent: 'Initial text',
      );

      final updated = original.copyWith(
        textContent: 'Updated text',
        linkedQuestId: 'quest-456',
        linkedQuestTitle: 'Build Flutter Feature',
      );

      expect(updated.isText, isTrue);
      expect(updated.textContent, 'Updated text');
      expect(updated.linkedQuestId, 'quest-456');
      expect(updated.linkedQuestTitle, 'Build Flutter Feature');
    });
  });
}
