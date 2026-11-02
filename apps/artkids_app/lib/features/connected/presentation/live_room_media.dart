import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

/// Owns device capture and SFU tracks for one classroom screen.
class LiveRoomMedia extends ChangeNotifier {
  lk.LocalVideoTrack? _camera;
  lk.LocalAudioTrack? _microphone;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _events;
  bool _closed = false;
  bool disconnected = false;

  bool get cameraEnabled => _camera != null && !_camera!.muted;
  bool get microphoneEnabled => _microphone != null && !_microphone!.muted;
  bool get connected => _room?.connectionState == lk.ConnectionState.connected;
  bool get reconnecting =>
      _room?.connectionState == lk.ConnectionState.reconnecting;
  bool get needsAudioGesture => _room != null && !_room!.canPlaybackAudio;
  lk.VideoTrack? get localVideo => cameraEnabled ? _camera : null;

  void _changed() {
    if (!_closed) notifyListeners();
  }

  Future<void> setCameraEnabled(bool enabled) async {
    if (_closed) return;
    final participant = _room?.localParticipant;
    if (participant != null) {
      final publication = await participant.setCameraEnabled(enabled);
      _camera = publication?.track as lk.LocalVideoTrack? ?? _camera;
    } else if (enabled) {
      if (_camera == null) {
        final track = await lk.LocalVideoTrack.createCameraTrack(
          const lk.CameraCaptureOptions(
            params: lk.VideoParametersPresets.h360_169,
          ),
        );
        if (_closed) {
          await track.dispose();
          return;
        }
        _camera = track;
      } else {
        await _camera!.unmute();
      }
    } else {
      await _camera?.mute();
    }
    _changed();
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_closed) return;
    final participant = _room?.localParticipant;
    if (participant != null) {
      final publication = await participant.setMicrophoneEnabled(enabled);
      _microphone = publication?.track as lk.LocalAudioTrack? ?? _microphone;
    } else if (enabled) {
      if (_microphone == null) {
        final track = await lk.LocalAudioTrack.create();
        if (_closed) {
          await track.dispose();
          return;
        }
        _microphone = track;
      } else {
        await _microphone!.unmute();
      }
    } else {
      await _microphone?.mute();
    }
    _changed();
  }

  Future<void> switchCamera(bool front) async {
    await _camera?.setCameraPosition(
      front ? lk.CameraPosition.front : lk.CameraPosition.back,
    );
    _changed();
  }

  Future<void> connect(Map<String, dynamic> configuration) async {
    if (configuration['isConfigured'] != true || _closed) return;
    final url = '${configuration['url'] ?? configuration['serverUrl'] ?? ''}';
    final token = '${configuration['accessToken'] ?? ''}';
    if (!url.startsWith('wss://') || token.isEmpty) {
      throw StateError('Cấu hình phòng học trực tuyến không hợp lệ.');
    }
    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );
    _room = room;
    disconnected = false;
    _events = room.createListener()
      ..on<lk.RoomEvent>((_) => _changed())
      ..on<lk.RoomDisconnectedEvent>((_) async {
        disconnected = true;
        await _camera?.mute();
        await _microphone?.mute();
        _changed();
      });
    try {
      await room.connect(url, token);
      if (_closed) {
        await room.disconnect();
        return;
      }
      final participant = room.localParticipant!;
      if (_camera != null && !cameraEnabled) {
        await _camera!.dispose();
        _camera = null;
      }
      if (_microphone != null && !microphoneEnabled) {
        await _microphone!.dispose();
        _microphone = null;
      }
      if (_camera != null && cameraEnabled) {
        await participant.publishVideoTrack(_camera!);
      }
      if (_microphone != null && microphoneEnabled) {
        await participant.publishAudioTrack(_microphone!);
      }
      await room.startAudio();
      _changed();
    } catch (_) {
      await _releaseRoom();
      _changed();
      rethrow;
    }
  }

  lk.VideoTrack? videoFor(String identity, {required bool self}) {
    if (self) return localVideo;
    final participant = _room?.remoteParticipants[identity];
    if (participant == null) return null;
    for (final publication in participant.videoTrackPublications) {
      if (publication.source == lk.TrackSource.camera && !publication.muted) {
        return publication.track;
      }
    }
    return null;
  }

  Future<void> startAudio() async {
    await _room?.startAudio();
    _changed();
  }

  Future<void> _releaseRoom() async {
    final events = _events;
    final room = _room;
    final camera = _camera;
    final microphone = _microphone;
    _events = null;
    _room = null;
    _camera = null;
    _microphone = null;
    // Teardown must release every device even if an SFU disconnect fails.
    Future<void> safely(Future<dynamic> Function() action) async {
      try {
        await action();
      } catch (_) {}
    }

    if (events != null) await safely(events.dispose);
    if (room != null) {
      if (room.connectionState != lk.ConnectionState.disconnected) {
        await safely(room.disconnect);
      }
      await safely(room.dispose);
    }
    if (camera != null) await safely(camera.dispose);
    if (microphone != null) await safely(microphone.dispose);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _releaseRoom();
    super.dispose();
  }
}

final liveRoomMediaFactoryProvider = Provider<LiveRoomMedia Function()>(
  (_) => LiveRoomMedia.new,
);
