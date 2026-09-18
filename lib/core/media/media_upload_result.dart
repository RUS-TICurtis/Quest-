class MediaUploadResult {
  /// Could be a Mux Playback ID or a full Cloudinary/direct HTTPS URL.
  final String url;

  /// Mux asset ID – required for deletion. Null when Cloudinary fallback is used.
  final String? assetId;

  /// True when the upload was served by Cloudinary instead of Mux.
  final bool usedFallback;

  MediaUploadResult({
    required this.url,
    this.assetId,
    this.usedFallback = false,
  });
}
