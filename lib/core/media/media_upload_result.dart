class MediaUploadResult {
  final String url; // Could be direct URL or Mux Playback ID
  final String? assetId; // Required for deleting from Mux

  MediaUploadResult({required this.url, this.assetId});
}
