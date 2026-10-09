import 'package:flutter/material.dart';

/// The type of media being created and shared.
enum CreateMediaType { image, video, text }

/// Strongly-typed submission payload passed from the capture phase
/// ([CreateScreen]) to the review and publishing phase ([ShareExperienceScreen]).
class CreateSubmissionPayload {
  /// The underlying media type (photo, video clip, or styled text status).
  final CreateMediaType mediaType;

  /// Absolute file path to the captured or picked media (null for text mode).
  final String? mediaPath;

  /// Text content entered during text creation mode.
  final String? textContent;

  /// Aesthetic background color or gradient token for text status cards.
  final Color? textBackgroundColor;

  /// Optional active Quest ID to associate with this post for XP reward verification.
  final String? linkedQuestId;

  /// Human-readable title of the linked Quest.
  final String? linkedQuestTitle;

  const CreateSubmissionPayload({
    required this.mediaType,
    this.mediaPath,
    this.textContent,
    this.textBackgroundColor,
    this.linkedQuestId,
    this.linkedQuestTitle,
  });

  bool get isText => mediaType == CreateMediaType.text;
  bool get isVideo => mediaType == CreateMediaType.video;
  bool get isImage => mediaType == CreateMediaType.image;

  CreateSubmissionPayload copyWith({
    CreateMediaType? mediaType,
    String? mediaPath,
    String? textContent,
    Color? textBackgroundColor,
    String? linkedQuestId,
    String? linkedQuestTitle,
  }) {
    return CreateSubmissionPayload(
      mediaType: mediaType ?? this.mediaType,
      mediaPath: mediaPath ?? this.mediaPath,
      textContent: textContent ?? this.textContent,
      textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor,
      linkedQuestId: linkedQuestId ?? this.linkedQuestId,
      linkedQuestTitle: linkedQuestTitle ?? this.linkedQuestTitle,
    );
  }
}
