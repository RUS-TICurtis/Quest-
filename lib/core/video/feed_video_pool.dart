import 'package:video_player/video_player.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PoolEntry {
  final VideoPlayerController controller;
  bool isInitialized = false;
  bool isError = false;

  PoolEntry(this.controller);
}

class FeedVideoPool extends Notifier<void> {
  final Map<int, PoolEntry> _entries = {};
  List<CreatorVideo> _videos = [];
  int _currentIndex = 0;
  bool _isGloballyPaused = false;

  @override
  void build() {}

  void setVideos(List<CreatorVideo> videos) {
    _videos = videos;
    if (_videos.isNotEmpty) {
      _activateWindow(_currentIndex);
    }
  }

  void onPageChanged(int index) {
    if (index == _currentIndex) return;
    
    // Pause previous
    _entries[_currentIndex]?.controller.pause();
    
    _currentIndex = index;
    
    // Play new
    if (!_isGloballyPaused) {
      _entries[_currentIndex]?.controller.play();
    }
    
    _activateWindow(_currentIndex);
    _disposeOutsideWindow(_currentIndex);
  }

  void setGlobalPause(bool paused) {
    _isGloballyPaused = paused;
    if (paused) {
      _entries[_currentIndex]?.controller.pause();
    } else {
      _entries[_currentIndex]?.controller.play();
    }
  }

  void _activateWindow(int centerIndex) {
    for (int i = centerIndex - 1; i <= centerIndex + 1; i++) {
      if (i >= 0 && i < _videos.length) {
        if (!_entries.containsKey(i)) {
          _initializeEntry(i, autoPlay: i == _currentIndex && !_isGloballyPaused);
        }
      }
    }
  }

  Future<void> _initializeEntry(int index, {required bool autoPlay}) async {
    final video = _videos[index];
    final String url;
    if (video.muxPlaybackId != null && video.muxPlaybackId!.isNotEmpty) {
      url = 'https://stream.mux.com/${video.muxPlaybackId!}.m3u8';
    } else {
      url = video.videoUrl;
    }

    if (url.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    final entry = PoolEntry(controller);
    _entries[index] = entry;

    try {
      await controller.initialize();
      controller.setLooping(true);
      entry.isInitialized = true;
      
      if (autoPlay && index == _currentIndex && !_isGloballyPaused) {
        controller.play();
      }
      ref.notifyListeners();
    } catch (e) {
      entry.isError = true;
      ref.notifyListeners();
    }
  }

  void _disposeOutsideWindow(int centerIndex) {
    final keysToRemove = <int>[];
    for (final key in _entries.keys) {
      if (key < centerIndex - 1 || key > centerIndex + 1) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      final entry = _entries.remove(key);
      entry?.controller.dispose();
    }
  }

  VideoPlayerController? getController(int index) {
    return _entries[index]?.controller;
  }

  bool isInitialized(int index) {
    return _entries[index]?.isInitialized ?? false;
  }

  bool isError(int index) {
    return _entries[index]?.isError ?? false;
  }
}

final feedVideoPoolProvider = NotifierProvider<FeedVideoPool, void>(() {
  return FeedVideoPool();
});
