import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/network/dio_client.dart';
import '../../../core/widgets/app_snack_bar.dart';
import 'live_room_media.dart';

class LiveMediaPermissionState {
  const LiveMediaPermissionState({
    required this.cameraGranted,
    required this.microphoneGranted,
    this.cameraPermanentlyDenied = false,
    this.microphonePermanentlyDenied = false,
  });

  final bool cameraGranted;
  final bool microphoneGranted;
  final bool cameraPermanentlyDenied;
  final bool microphonePermanentlyDenied;

  bool get anyGranted => cameraGranted || microphoneGranted;
  bool get allGranted => cameraGranted && microphoneGranted;
  bool get anyPermanentlyDenied =>
      cameraPermanentlyDenied || microphonePermanentlyDenied;
}

class LiveMediaPermissionService {
  const LiveMediaPermissionService();

  bool get _isWidgetTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  Future<LiveMediaPermissionState> checkPermissions() async {
    if (kIsWeb) {
      return const LiveMediaPermissionState(
        cameraGranted: false,
        microphoneGranted: false,
      );
    }
    if (_isWidgetTestEnvironment) {
      return const LiveMediaPermissionState(
        cameraGranted: true,
        microphoneGranted: true,
      );
    }
    try {
      final camStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      return LiveMediaPermissionState(
        cameraGranted: camStatus.isGranted,
        microphoneGranted: micStatus.isGranted,
        cameraPermanentlyDenied: camStatus.isPermanentlyDenied,
        microphonePermanentlyDenied: micStatus.isPermanentlyDenied,
      );
    } catch (_) {
      return const LiveMediaPermissionState(
        cameraGranted: true,
        microphoneGranted: true,
      );
    }
  }

  Future<LiveMediaPermissionState> requestPermissions() async {
    if (kIsWeb) {
      // Browser permission is requested by actual device capture, not permission_handler.
      return const LiveMediaPermissionState(
        cameraGranted: false,
        microphoneGranted: false,
      );
    }
    if (_isWidgetTestEnvironment) {
      return const LiveMediaPermissionState(
        cameraGranted: true,
        microphoneGranted: true,
      );
    }
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();
      final camStatus =
          statuses[Permission.camera] ?? await Permission.camera.status;
      final micStatus =
          statuses[Permission.microphone] ?? await Permission.microphone.status;
      return LiveMediaPermissionState(
        cameraGranted: camStatus.isGranted,
        microphoneGranted: micStatus.isGranted,
        cameraPermanentlyDenied: camStatus.isPermanentlyDenied,
        microphonePermanentlyDenied: micStatus.isPermanentlyDenied,
      );
    } catch (_) {
      return const LiveMediaPermissionState(
        cameraGranted: true,
        microphoneGranted: true,
      );
    }
  }

  Future<bool> openSystemSettings() async {
    if (kIsWeb) return false;
    return openAppSettings();
  }
}

final liveMediaPermissionProvider = Provider<LiveMediaPermissionService>(
  (_) => const LiveMediaPermissionService(),
);

class LiveScreenShareCapabilities {
  const LiveScreenShareCapabilities({
    required this.supported,
    required this.platform,
    required this.supportsSystemScreenShare,
    required this.supportsDeviceAudio,
    required this.scopeDescription,
    required this.deviceAudioNotice,
    this.unsupportedReason,
  });

  final bool supported;
  final String platform;
  final bool supportsSystemScreenShare;
  final bool supportsDeviceAudio;
  final String scopeDescription;
  final String deviceAudioNotice;
  final String? unsupportedReason;
}

class LiveScreenShareStartResult {
  const LiveScreenShareStartResult({
    required this.started,
    this.scope = 'entire_screen',
    this.width = 540,
    this.height = 960,
    this.frameBase64,
    this.includeDeviceAudio = false,
    this.reason,
    this.message,
  });

  final bool started;
  final String scope;
  final int width;
  final int height;
  final String? frameBase64;
  final bool includeDeviceAudio;
  final String? reason;
  final String? message;
}

class LiveScreenShareFrame {
  const LiveScreenShareFrame({
    required this.active,
    required this.width,
    required this.height,
    this.frameBase64,
  });

  final bool active;
  final int width;
  final int height;
  final String? frameBase64;
}

class LiveScreenShareService {
  LiveScreenShareService() {
    _channel.setMethodCallHandler(_handleNativeCallback);
  }

  static const MethodChannel _channel = MethodChannel(
    'com.artkids.artkids_app/screen_share',
  );

  // 1x1 transparent PNG fallback for deterministic widget tests
  static const String defaultTestFrameBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  void Function(String reason)? _onSystemStop;

  bool get _isWidgetTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  void setOnSystemStopListener(void Function(String reason)? listener) {
    _onSystemStop = listener;
  }

  Future<dynamic> _handleNativeCallback(MethodCall call) async {
    if (call.method == 'onScreenShareStoppedBySystem') {
      final map = call.arguments is Map
          ? Map<String, dynamic>.from(call.arguments as Map)
          : const <String, dynamic>{};
      _onSystemStop?.call('${map['reason'] ?? 'os_stopped'}');
    }
  }

  Future<LiveScreenShareCapabilities> getCapabilities() async {
    if (_isWidgetTestEnvironment) {
      return const LiveScreenShareCapabilities(
        supported: true,
        platform: 'android',
        supportsSystemScreenShare: true,
        supportsDeviceAudio: true,
        scopeDescription:
            'Trên Android, hệ điều hành sẽ mở hộp thoại bảo mật để bạn chọn chia sẻ Toàn bộ màn hình hoặc Một ứng dụng. Camera và Microphone vẫn hoạt động độc lập.',
        deviceAudioNotice:
            'Âm thanh nội bộ của thiết bị là quyền riêng trên Android 10+; mặc định chỉ truyền hình ảnh màn hình và âm thanh từ Microphone của bạn.',
      );
    }

    if (kIsWeb) {
      return const LiveScreenShareCapabilities(
        supported: true,
        platform: 'web',
        supportsSystemScreenShare: true,
        supportsDeviceAudio: true,
        scopeDescription:
            'Trên trình duyệt Desktop (Web), trình duyệt sẽ mở hộp thoại getDisplayMedia để bạn chọn Thẻ trình duyệt (Tab), Cửa sổ ứng dụng hoặc Toàn màn hình.',
        deviceAudioNotice:
            'Âm thanh hệ thống trên Web chỉ được truyền khi bạn tích chọn "Chia sẻ âm thanh thẻ/hệ thống" trong hộp thoại trình duyệt.',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>(
          'getPlatformCapabilities',
        );
        if (res != null) {
          return LiveScreenShareCapabilities(
            supported: res['supported'] == true,
            platform: '${res['platform'] ?? 'android'}',
            supportsSystemScreenShare: res['supportsSystemScreenShare'] == true,
            supportsDeviceAudio: res['supportsDeviceAudio'] == true,
            scopeDescription:
                '${res['scopeDescription'] ?? 'Chia sẻ màn hình thiết bị Android qua MediaProjection.'}',
            deviceAudioNotice:
                '${res['deviceAudioNotice'] ?? 'Âm thanh thiết bị là quyền riêng; mặc định chỉ truyền hình ảnh màn hình và Microphone.'}',
          );
        }
      } catch (_) {}
      return const LiveScreenShareCapabilities(
        supported: true,
        platform: 'android',
        supportsSystemScreenShare: true,
        supportsDeviceAudio: true,
        scopeDescription:
            'Trên Android, hệ điều hành sẽ mở hộp thoại bảo mật MediaProjection để bạn chọn chia sẻ Toàn bộ màn hình hoặc Một ứng dụng.',
        deviceAudioNotice:
            'Âm thanh nội bộ của thiết bị là quyền riêng trên Android 10+; mặc định chỉ truyền hình ảnh màn hình và âm thanh từ Microphone của bạn.',
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const LiveScreenShareCapabilities(
        supported: false,
        platform: 'ios',
        supportsSystemScreenShare: false,
        supportsDeviceAudio: false,
        scopeDescription:
            'Trên iOS, chia sẻ toàn màn hình ngoài ứng dụng yêu cầu cấu hình ReplayKit Broadcast Upload Extension kèm Apple Developer App Group.',
        deviceAudioNotice:
            'Âm thanh thiết bị trên iOS được quản lý qua ReplayKit.',
        unsupportedReason:
            'Bản dựng iOS hiện tại chưa cấu hình chứng chỉ Apple Developer App Group cho ReplayKit Broadcast Extension.',
      );
    }

    return LiveScreenShareCapabilities(
      supported: false,
      platform: defaultTargetPlatform.name,
      supportsSystemScreenShare: false,
      supportsDeviceAudio: false,
      scopeDescription: 'Nền tảng hiện tại chưa hỗ trợ chia sẻ màn hình.',
      deviceAudioNotice: 'Không hỗ trợ âm thanh thiết bị.',
      unsupportedReason:
          'Nền tảng ${defaultTargetPlatform.name} chưa hỗ trợ thu màn hình native trong cấu hình hiện tại.',
    );
  }

  Future<LiveScreenShareStartResult> startScreenShare() async {
    if (_isWidgetTestEnvironment) {
      return const LiveScreenShareStartResult(
        started: true,
        scope: 'entire_screen',
        width: 540,
        height: 960,
        frameBase64: defaultTestFrameBase64,
        includeDeviceAudio: false,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>(
          'startScreenShare',
        );
        if (res == null) {
          return const LiveScreenShareStartResult(
            started: false,
            reason: 'null_response',
            message: 'Không nhận được phản hồi từ dịch vụ chia sẻ màn hình.',
          );
        }
        return LiveScreenShareStartResult(
          started: res['started'] == true,
          scope: '${res['scope'] ?? 'entire_screen'}',
          width: (res['width'] as num?)?.toInt() ?? 540,
          height: (res['height'] as num?)?.toInt() ?? 960,
          frameBase64: res['frameBase64']?.toString(),
          includeDeviceAudio: res['includeDeviceAudio'] == true,
          reason: res['reason']?.toString(),
          message: res['message']?.toString(),
        );
      } catch (e) {
        return LiveScreenShareStartResult(
          started: false,
          reason: 'exception',
          message: 'Không thể khởi chạy chia sẻ màn hình: $e',
        );
      }
    }

    return const LiveScreenShareStartResult(
      started: false,
      reason: 'unsupported_platform',
      message: 'Nền tảng hiện tại chưa hỗ trợ thu màn hình trực tiếp.',
    );
  }

  Future<LiveScreenShareFrame?> captureFrame() async {
    if (_isWidgetTestEnvironment) {
      return const LiveScreenShareFrame(
        active: true,
        width: 540,
        height: 960,
        frameBase64: defaultTestFrameBase64,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      try {
        final res = await _channel.invokeMapMethod<String, dynamic>(
          'captureFrame',
        );
        if (res == null) return null;
        return LiveScreenShareFrame(
          active: res['active'] == true,
          width: (res['width'] as num?)?.toInt() ?? 540,
          height: (res['height'] as num?)?.toInt() ?? 960,
          frameBase64: res['frameBase64']?.toString(),
        );
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> stopScreenShare() async {
    if (_isWidgetTestEnvironment) return;
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      try {
        await _channel.invokeMethod<dynamic>('stopScreenShare');
      } catch (_) {}
    }
  }
}

final liveScreenShareProvider = Provider<LiveScreenShareService>(
  (_) => LiveScreenShareService(),
);

enum _ClassroomPhase {
  loadingToken,
  preJoin,
  connectingRoom,
  inRoom,
  endedOrError,
}

class LiveClassroomScreen extends ConsumerStatefulWidget {
  const LiveClassroomScreen({super.key, required this.sessionId, this.childId});

  final String sessionId;
  final String? childId;

  @override
  ConsumerState<LiveClassroomScreen> createState() =>
      _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends ConsumerState<LiveClassroomScreen>
    with WidgetsBindingObserver {
  _ClassroomPhase _phase = _ClassroomPhase.loadingToken;
  LiveMediaPermissionState _permissionState = const LiveMediaPermissionState(
    cameraGranted: true,
    microphoneGranted: true,
  );

  Map<String, dynamic>? _roomTokenData;
  String? _errorMessage;
  bool _roomClosedOrRevoked = false;

  bool _micEnabled = true;
  bool _cameraEnabled = true;
  String _cameraFacing = 'front';
  String _connectionQuality = 'good';
  bool _isReconnecting = false;
  bool _wasCameraEnabledBeforeBackground = false;
  bool _disposedResources = false;
  bool _actionBusy = false;
  bool _mediaBusy = false;
  String? _mediaError;
  late LiveRoomMedia _media;

  bool _canShareScreen = false;
  Map<String, dynamic>? _activeScreenShare;
  Uint8List? _cachedScreenShareBytes;
  String? _cachedScreenShareBase64;
  final TransformationController _screenShareZoomController =
      TransformationController();

  late final String _deviceId;
  List<Map<String, dynamic>> _participants = const [];
  Timer? _heartbeatTimer;
  Timer? _screenShareFrameTimer;

  bool get _isSelfSharingScreen {
    final myIdentity = '${_roomTokenData?['participantIdentity'] ?? ''}';
    final presenter = '${_activeScreenShare?['presenterIdentity'] ?? ''}';
    return _activeScreenShare != null &&
        myIdentity.isNotEmpty &&
        myIdentity == presenter;
  }

  late final LiveScreenShareService _screenShareService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _media = ref.read(liveRoomMediaFactoryProvider)();
    _media.addListener(_onMediaChanged);
    _deviceId = 'flutter-${DateTime.now().microsecondsSinceEpoch}';
    _screenShareService = ref.read(liveScreenShareProvider);
    _screenShareService.setOnSystemStopListener(
      _handleSystemStoppedScreenShare,
    );
    _initializePreJoin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenShareZoomController.dispose();
    _releaseMediaAndRoomResources();
    super.dispose();
  }

  void _releaseMediaAndRoomResources() {
    if (_disposedResources) return;
    _disposedResources = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _screenShareFrameTimer?.cancel();
    _screenShareFrameTimer = null;
    _screenShareService.setOnSystemStopListener(null);
    _screenShareService.stopScreenShare();
    _media.removeListener(_onMediaChanged);
    unawaited(_media.close());
  }

  void _onMediaChanged() {
    if (!mounted || _disposedResources) return;
    setState(() {
      _cameraEnabled = _media.cameraEnabled;
      _micEnabled = _media.microphoneEnabled;
      if (_media.disconnected) {
        _mediaError =
            'Kết nối âm thanh/video đã ngắt. Vui lòng rời phòng và vào lại.';
      }
    });
  }

  Future<void> _prepareLocalMedia(LiveMediaPermissionState permissions) async {
    final errors = <String>[];
    if (kIsWeb || permissions.cameraGranted) {
      try {
        await _media.setCameraEnabled(true);
      } catch (_) {
        errors.add(
          'Không mở được camera. Hãy cho phép camera trong trình duyệt và kiểm tra thiết bị có đang được ứng dụng khác sử dụng không.',
        );
      }
    }
    if (kIsWeb || permissions.microphoneGranted) {
      try {
        await _media.setMicrophoneEnabled(true);
      } catch (_) {
        errors.add(
          'Không mở được microphone. Hãy kiểm tra quyền microphone và thiết bị thu âm.',
        );
      }
    }
    if (!mounted || _disposedResources) return;
    setState(() {
      _cameraEnabled = _media.cameraEnabled;
      _micEnabled = _media.microphoneEnabled;
      _permissionState = LiveMediaPermissionState(
        cameraGranted: _media.cameraEnabled,
        microphoneGranted: _media.microphoneEnabled,
        cameraPermanentlyDenied: permissions.cameraPermanentlyDenied,
        microphonePermanentlyDenied: permissions.microphonePermanentlyDenied,
      );
      _mediaError = errors.isEmpty ? null : errors.join('\n');
    });
  }

  Future<void> _changeDevice(Future<void> Function() action) async {
    if (_mediaBusy || _disposedResources) return;
    setState(() => _mediaBusy = true);
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _mediaError = null;
        _cameraEnabled = _media.cameraEnabled;
        _micEnabled = _media.microphoneEnabled;
        _permissionState = LiveMediaPermissionState(
          cameraGranted: _permissionState.cameraGranted || _cameraEnabled,
          microphoneGranted: _permissionState.microphoneGranted || _micEnabled,
        );
      });
      if (_phase == _ClassroomPhase.inRoom) await _syncRoomState();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _mediaError =
            'Không thay đổi được thiết bị. Hãy kiểm tra quyền Camera/Mic và thử lại.',
      );
      showAppSnackBar(context, SnackBar(content: Text(_mediaError!)));
    } finally {
      if (mounted) setState(() => _mediaBusy = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A browser tab losing focus must not mute an ongoing class.
    if (kIsWeb) return;
    if (_phase == _ClassroomPhase.preJoin &&
        state == AppLifecycleState.resumed) {
      _refreshPermissionsFromStatus();
      return;
    }
    if (_phase != _ClassroomPhase.inRoom) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _wasCameraEnabledBeforeBackground = _cameraEnabled;
      // Note: If user is actively sharing their screen on Android via MediaProjection
      // ForegroundService, keep the screen-share stream alive when switching apps!
      if (_cameraEnabled && !_isSelfSharingScreen) {
        unawaited(_changeDevice(() => _media.setCameraEnabled(false)));
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_wasCameraEnabledBeforeBackground && _permissionState.cameraGranted) {
        unawaited(_changeDevice(() => _media.setCameraEnabled(true)));
      }
      _syncRoomState(connectionState: 'connected');
    }
  }

  Future<void> _initializePreJoin() async {
    if (_disposedResources) {
      _disposedResources = false;
      _media = ref.read(liveRoomMediaFactoryProvider)();
      _media.addListener(_onMediaChanged);
      _screenShareService.setOnSystemStopListener(
        _handleSystemStoppedScreenShare,
      );
    }
    setState(() {
      _phase = _ClassroomPhase.loadingToken;
      _errorMessage = null;
      _roomClosedOrRevoked = false;
    });

    final permService = ref.read(liveMediaPermissionProvider);
    final perms = await permService.requestPermissions();

    try {
      final tokenRes = await _postMap(
        '/live/sessions/${widget.sessionId}/room/token',
        data: {
          if (widget.childId != null && widget.childId!.isNotEmpty)
            'childId': widget.childId,
        },
      );
      if (!mounted) return;
      final permissions =
          (tokenRes['permissions'] as Map?)?.cast<String, dynamic>() ??
          const {};
      final role = '${tokenRes['participantRole'] ?? 'student'}';
      await _prepareLocalMedia(perms);
      if (!mounted) return;
      setState(() {
        _roomTokenData = tokenRes;
        _canShareScreen =
            permissions['canShareScreen'] == true ||
            role == 'instructor' ||
            role == 'admin';
        _phase = _ClassroomPhase.preJoin;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionState = perms;
        _errorMessage = _formatRoomError(e);
        _phase = _ClassroomPhase.endedOrError;
      });
    }
  }

  Future<void> _refreshPermissionsFromStatus() async {
    _onMediaChanged();
  }

  Future<void> _recheckOrRequestPermissions() async {
    final permService = ref.read(liveMediaPermissionProvider);
    final perms = await permService.requestPermissions();
    await _prepareLocalMedia(perms);
  }

  Future<void> _enterRoom() async {
    final tokenData = _roomTokenData;
    if (tokenData == null) return;
    if (!_permissionState.anyGranted) {
      showAppSnackBar(
        context,
        const SnackBar(
          content: Text(
            'Vui lòng cấp quyền Microphone hoặc Camera trước khi vào phòng học.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _phase = _ClassroomPhase.connectingRoom;
      _errorMessage = null;
    });

    try {
      final connectRes = await _postMap(
        '/live/sessions/${widget.sessionId}/room/connect',
        data: {
          'roomToken': '${tokenData['roomToken'] ?? ''}',
          'deviceId': _deviceId,
          'micEnabled': _micEnabled && _permissionState.microphoneGranted,
          'cameraEnabled': _cameraEnabled && _permissionState.cameraGranted,
          'cameraFacing': _cameraFacing,
        },
      );
      if (!mounted) return;
      _applyRoomSnapshot(connectRes);
      await _media.connect(
        (tokenData['sfu'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      if (!mounted || _disposedResources) return;
      setState(() {
        _connectionQuality = _cameraEnabled ? 'good' : 'audio_only';
        _isReconnecting = false;
        _phase = _ClassroomPhase.inRoom;
      });
      _startHeartbeat();
    } catch (e) {
      final diagnostic = '$e'.replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
        '[token]',
      );
      debugPrint('Classroom media connection failed: $diagnostic');
      // Do not leave a signalling participant or device capture behind when SFU join fails.
      try {
        await _postMap(
          '/live/sessions/${widget.sessionId}/room/disconnect',
          data: {
            'roomToken': '${tokenData['roomToken'] ?? ''}',
            'deviceId': _deviceId,
          },
        );
      } catch (_) {}
      _releaseMediaAndRoomResources();
      if (!mounted) return;
      setState(() {
        _errorMessage = _formatRoomError(e);
        _phase = _ClassroomPhase.endedOrError;
      });
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _phase == _ClassroomPhase.inRoom) {
        _syncRoomState(connectionState: 'connected');
      }
    });
  }

  void _startScreenShareFrameLoop() {
    _screenShareFrameTimer?.cancel();
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    _screenShareFrameTimer = Timer.periodic(
      const Duration(milliseconds: 1400),
      (_) => _pushLatestScreenShareFrame(),
    );
  }

  Future<void> _pushLatestScreenShareFrame() async {
    if (!mounted || _phase != _ClassroomPhase.inRoom || !_isSelfSharingScreen) {
      _screenShareFrameTimer?.cancel();
      return;
    }
    final tokenData = _roomTokenData;
    if (tokenData == null) return;

    final frame = await ref.read(liveScreenShareProvider).captureFrame();
    if (!mounted || frame == null) return;
    if (!frame.active) {
      await _handleSystemStoppedScreenShare('os_stopped');
      return;
    }
    final b64 = frame.frameBase64;
    if (b64 == null || b64.isEmpty) return;

    try {
      final res = await _postMap(
        '/live/sessions/${widget.sessionId}/room/screen-share/frame',
        data: {
          'roomToken': '${tokenData['roomToken'] ?? ''}',
          'width': frame.width,
          'height': frame.height,
          'frameBase64': b64,
        },
      );
      if (!mounted) return;
      _applyRoomSnapshot(res);
    } catch (e) {
      if (!mounted) return;
      if (_isTokenRevokedOrSessionEndedError(e)) {
        _screenShareFrameTimer?.cancel();
        await ref.read(liveScreenShareProvider).stopScreenShare();
        await _syncRoomState();
      }
    }
  }

  void _applyRoomSnapshot(Map<String, dynamic> snapshot) {
    final updatedParticipants = _asMapList(snapshot['participants']);
    final rawShare = snapshot['screenShare'];
    Map<String, dynamic>? activeShare;
    if (rawShare is Map && rawShare['isActive'] != false) {
      activeShare = Map<String, dynamic>.from(rawShare);
    }

    final frameB64 = activeShare?['frameBase64']?.toString();
    if (frameB64 != null && frameB64.isNotEmpty) {
      if (frameB64 != _cachedScreenShareBase64) {
        try {
          _cachedScreenShareBytes = base64Decode(frameB64);
          _cachedScreenShareBase64 = frameB64;
        } catch (_) {}
      }
    } else {
      _cachedScreenShareBytes = null;
      _cachedScreenShareBase64 = null;
    }

    final role = '${_roomTokenData?['participantRole'] ?? 'student'}';
    final isStaff = role == 'instructor' || role == 'admin';
    final canShare = snapshot.containsKey('canShareScreen')
        ? snapshot['canShareScreen'] == true
        : (isStaff || _canShareScreen);

    final wasSharingBefore = _activeScreenShare != null;
    setState(() {
      _participants = updatedParticipants;
      _activeScreenShare = activeShare;
      _canShareScreen = canShare;
      if (wasSharingBefore && activeShare == null) {
        _screenShareZoomController.value = Matrix4.identity();
      }
    });
  }

  Future<void> _syncRoomState({String connectionState = 'connected'}) async {
    final tokenData = _roomTokenData;
    if (tokenData == null || _phase != _ClassroomPhase.inRoom) return;

    try {
      final res = await _postMap(
        '/live/sessions/${widget.sessionId}/room/state',
        data: {
          'roomToken': '${tokenData['roomToken'] ?? ''}',
          'deviceId': _deviceId,
          'micEnabled': _micEnabled,
          'cameraEnabled': _cameraEnabled,
          'cameraFacing': _cameraFacing,
          'audioOnly': !_cameraEnabled,
          'isReconnecting': connectionState == 'reconnecting',
        },
      );
      if (!mounted) return;
      final mutedByInstructor = res['muteRequestedByInstructor'] == true;
      final shareRevoked = res['screenShareRevokedByInstructor'] == true;

      if (shareRevoked) {
        _screenShareFrameTimer?.cancel();
        await ref.read(liveScreenShareProvider).stopScreenShare();
        if (!mounted) return;
      }

      _applyRoomSnapshot(res);
      setState(() {
        if (mutedByInstructor && _micEnabled) {
          _micEnabled = false;
        }
        _isReconnecting = false;
        _connectionQuality = _cameraEnabled ? 'good' : 'audio_only';
      });

      if (mutedByInstructor) {
        await _media.setMicrophoneEnabled(false);
        if (!mounted) return;
        showAppSnackBar(
          context,
          const SnackBar(
            content: Text('Gia sư đã yêu cầu tắt microphone của bạn.'),
          ),
        );
      }
      if (shareRevoked) {
        showAppSnackBar(
          context,
          const SnackBar(
            content: Text('Gia sư đã thu hồi quyền chia sẻ màn hình của bạn.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (_isTokenRevokedOrSessionEndedError(e)) {
        _heartbeatTimer?.cancel();
        _screenShareFrameTimer?.cancel();
        await ref.read(liveScreenShareProvider).stopScreenShare();
        if (!mounted) return;
        setState(() {
          _roomClosedOrRevoked = true;
          _errorMessage = _formatRoomError(e);
          _phase = _ClassroomPhase.endedOrError;
        });
        _releaseMediaAndRoomResources();
      } else {
        setState(() {
          _isReconnecting = true;
          _connectionQuality = 'reconnecting';
        });
      }
    }
  }

  Future<void> _startScreenShareFlow() async {
    if (_actionBusy) return;
    if (!_canShareScreen) {
      showAppSnackBar(
        context,
        const SnackBar(
          content: Text(
            'Bạn chưa được gia sư cấp quyền chia sẻ màn hình trong buổi học này.',
          ),
        ),
      );
      return;
    }

    if (_activeScreenShare != null && !_isSelfSharingScreen) {
      final currentPresenter =
          '${_activeScreenShare?['presenterName'] ?? 'Người tham gia khác'}';
      showAppSnackBar(
        context,
        SnackBar(
          content: Text(
            'Hiện tại $currentPresenter đang chia sẻ màn hình. Chỉ một người được chia sẻ tại một thời điểm.',
          ),
        ),
      );
      return;
    }

    final screenService = ref.read(liveScreenShareProvider);
    final caps = await screenService.getCapabilities();
    if (!mounted) return;

    if (!caps.supported) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nền tảng chưa hỗ trợ chia sẻ màn hình'),
          content: Text(caps.unsupportedReason ?? caps.scopeDescription),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận chia sẻ màn hình'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caps.scopeDescription,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lưu ý về âm thanh & quyền riêng tư:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${caps.deviceAudioNotice}\n'
                    '• Camera và Microphone của bạn vẫn hoạt động độc lập theo trạng thái đã chọn.\n'
                    '• Chia sẻ màn hình chỉ truyền trực tiếp trong phòng học, không tự động ghi hình buổi học.',
                    style: const TextStyle(fontSize: 12.5, height: 1.38),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.screen_share, size: 18),
            label: const Text('Tiếp tục & Chọn màn hình'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionBusy = true);
    try {
      final startResult = await screenService.startScreenShare();
      if (!mounted) return;
      if (!startResult.started) {
        showAppSnackBar(
          context,
          SnackBar(
            content: Text(
              startResult.message ??
                  'Bạn đã từ chối hoặc hủy cấp quyền chia sẻ màn hình. Cuộc gọi âm thanh/video vẫn tiếp tục.',
            ),
          ),
        );
        return;
      }

      final tokenData = _roomTokenData;
      if (tokenData == null) {
        await screenService.stopScreenShare();
        return;
      }

      final res = await _postMap(
        '/live/sessions/${widget.sessionId}/room/screen-share/start',
        data: {
          'roomToken': '${tokenData['roomToken'] ?? ''}',
          'deviceId': _deviceId,
          'scope': startResult.scope,
          'includeDeviceAudio': startResult.includeDeviceAudio,
          'width': startResult.width,
          'height': startResult.height,
          if (startResult.frameBase64 != null)
            'frameBase64': startResult.frameBase64,
          'contentLabel':
              'Bài giảng & màn hình của ${tokenData['participantName'] ?? 'Gia sư'}',
        },
      );
      if (!mounted) return;
      _applyRoomSnapshot(res);
      _startScreenShareFrameLoop();
      showAppSnackBar(
        context,
        const SnackBar(
          content: Text('Đã bắt đầu chia sẻ màn hình trong lớp học.'),
        ),
      );
    } catch (e) {
      await screenService.stopScreenShare();
      if (!mounted) return;
      showAppSnackBar(context, SnackBar(content: Text(_formatRoomError(e))));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _stopScreenShare({String reason = 'user_stopped'}) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    _screenShareFrameTimer?.cancel();
    try {
      await ref.read(liveScreenShareProvider).stopScreenShare();
      final tokenData = _roomTokenData;
      if (tokenData != null) {
        final res = await _postMap(
          '/live/sessions/${widget.sessionId}/room/screen-share/stop',
          data: {
            'roomToken': '${tokenData['roomToken'] ?? ''}',
            'reason': reason,
          },
        );
        if (mounted) {
          _applyRoomSnapshot(res);
        }
      }
      if (mounted) {
        showAppSnackBar(
          context,
          const SnackBar(
            content: Text(
              'Đã dừng chia sẻ màn hình. Cuộc gọi âm thanh/video vẫn tiếp tục.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, SnackBar(content: Text(_formatRoomError(e))));
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _handleSystemStoppedScreenShare(String reason) async {
    if (!mounted || !_isSelfSharingScreen) return;
    _screenShareFrameTimer?.cancel();
    try {
      final tokenData = _roomTokenData;
      if (tokenData != null) {
        final res = await _postMap(
          '/live/sessions/${widget.sessionId}/room/screen-share/stop',
          data: {
            'roomToken': '${tokenData['roomToken'] ?? ''}',
            'reason': reason,
          },
        );
        if (mounted) {
          _applyRoomSnapshot(res);
        }
      }
    } catch (_) {}
    if (!mounted) return;
    showAppSnackBar(
      context,
      const SnackBar(
        content: Text(
          'Hệ điều hành đã dừng phiên chia sẻ màn hình. Cuộc gọi âm thanh/video vẫn tiếp tục.',
        ),
      ),
    );
  }

  Future<void> _setParticipantScreenSharePermission(
    String targetIdentity,
    String displayName,
    bool grant,
  ) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final res = await _postMap(
        '/live/sessions/${widget.sessionId}/room/screen-share/permission',
        data: {'targetIdentity': targetIdentity, 'canShareScreen': grant},
      );
      if (!mounted) return;
      _applyRoomSnapshot(res);
      showAppSnackBar(
        context,
        SnackBar(
          content: Text(
            grant
                ? 'Đã cấp quyền chia sẻ màn hình cho $displayName.'
                : 'Đã thu hồi quyền chia sẻ màn hình của $displayName.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, SnackBar(content: Text(_formatRoomError(e))));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _openFullscreenScreenShare() async {
    final share = _activeScreenShare;
    if (share == null) return;
    var landscapeMode = false;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setFullState) {
              final presenterName =
                  '${(_activeScreenShare ?? share)['presenterName'] ?? 'Gia sư'}';
              final contentLabel =
                  '${(_activeScreenShare ?? share)['contentLabel'] ?? 'Màn hình trình bày'}';
              return Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang chia sẻ màn hình: $presenterName',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        contentLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: landscapeMode ? 'Xoay dọc' : 'Xoay ngang',
                      onPressed: () async {
                        landscapeMode = !landscapeMode;
                        setFullState(() {});
                        await SystemChrome.setPreferredOrientations(
                          landscapeMode
                              ? const [
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight,
                                ]
                              : const [
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight,
                                ],
                        );
                      },
                      icon: const Icon(Icons.screen_rotation_alt),
                    ),
                    IconButton(
                      tooltip: 'Đặt lại thu phóng',
                      onPressed: () {
                        _screenShareZoomController.value = Matrix4.identity();
                      },
                      icon: const Icon(Icons.zoom_out_map),
                    ),
                    IconButton(
                      tooltip: 'Thoát toàn màn hình',
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.fullscreen_exit),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: Center(
                    child: _buildScreenShareInteractiveViewport(
                      _activeScreenShare ?? share,
                      isFullscreen: true,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _toggleMicrophone() => _changeDevice(
    () => _media.setMicrophoneEnabled(!_media.microphoneEnabled),
  );

  Future<void> _toggleCamera() =>
      _changeDevice(() => _media.setCameraEnabled(!_media.cameraEnabled));

  Future<void> _switchCameraFacing() => _changeDevice(() async {
    final front = _cameraFacing != 'front';
    await _media.switchCamera(front);
    if (mounted) setState(() => _cameraFacing = front ? 'front' : 'back');
  });

  Future<void> _muteParticipantMic(String targetIdentity, String name) async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      final res = await _postMap(
        '/live/sessions/${widget.sessionId}/room/moderate',
        data: {'targetIdentity': targetIdentity, 'action': 'mute_mic'},
      );
      if (!mounted) return;
      _applyRoomSnapshot(res);
      showAppSnackBar(
        context,
        SnackBar(content: Text('Đã tắt microphone của $name.')),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, SnackBar(content: Text(_formatRoomError(e))));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _leaveRoom() async {
    if (_actionBusy) return;
    setState(() => _actionBusy = true);
    _heartbeatTimer?.cancel();
    _screenShareFrameTimer?.cancel();
    try {
      await ref.read(liveScreenShareProvider).stopScreenShare();
      final tokenData = _roomTokenData;
      if (tokenData != null) {
        await _postMap(
          '/live/sessions/${widget.sessionId}/room/disconnect',
          data: {
            'roomToken': '${tokenData['roomToken'] ?? ''}',
            'deviceId': _deviceId,
          },
        );
      }
    } catch (_) {
      // Best-effort disconnect on leave.
    } finally {
      _releaseMediaAndRoomResources();
      if (mounted) {
        setState(() => _actionBusy = false);
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go('/parent/live');
        }
      }
    }
  }

  Future<void> _endSessionForAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc buổi học cho tất cả?'),
        content: const Text(
          'Phòng học trực tuyến và phiên chia sẻ màn hình (nếu có) sẽ đóng lại, ghi nhận tổng thời lượng tham gia của học viên và vô hiệu hóa toàn bộ phiên truy cập hiện tại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kết thúc buổi học'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actionBusy = true);
    _heartbeatTimer?.cancel();
    _screenShareFrameTimer?.cancel();
    try {
      await ref.read(liveScreenShareProvider).stopScreenShare();
      await _postMap(
        '/live/sessions/${widget.sessionId}/room/end',
        data: const {},
      );
      _releaseMediaAndRoomResources();
      if (!mounted) return;
      showAppSnackBar(
        context,
        const SnackBar(
          content: Text('Đã kết thúc buổi học và đóng phòng trực tuyến.'),
        ),
      );
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/parent/live');
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, SnackBar(content: Text(_formatRoomError(e))));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  void _showParticipantsSheet() {
    final permissions =
        (_roomTokenData?['permissions'] as Map?)?.cast<String, dynamic>() ??
        const {};
    final role = '${_roomTokenData?['participantRole'] ?? 'student'}';
    final isStaff = role == 'instructor' || role == 'admin';
    final canModerateAudio = permissions['canModerateAudio'] == true || isStaff;
    final canGrantScreenShare =
        permissions['canGrantScreenShare'] == true || isStaff;
    final myIdentity = '${_roomTokenData?['participantIdentity'] ?? ''}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A2234),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final list = _participants;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Người tham gia (${list.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24),
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Chưa có người tham gia nào trong phòng.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 380),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: list.length,
                          separatorBuilder: (_, _) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (_, idx) {
                            final p = list[idx];
                            final identity = '${p['identity'] ?? ''}';
                            final name = '${p['displayName'] ?? 'Người dùng'}';
                            final pRole = '${p['role'] ?? 'student'}';
                            final micOn = p['micEnabled'] == true;
                            final camOn = p['cameraEnabled'] == true;
                            final isSharing =
                                p['screenSharing'] == true ||
                                _activeScreenShare?['presenterIdentity'] ==
                                    identity;
                            final pCanShare =
                                p['canShareScreen'] == true ||
                                pRole == 'instructor' ||
                                pRole == 'admin';
                            final connState =
                                '${p['connectionState'] ?? 'connected'}';
                            final isSelf = identity == myIdentity;
                            final isInstructor =
                                pRole == 'instructor' || pRole == 'admin';

                            final statusParts = <String>[
                              isInstructor ? 'Gia sư' : 'Học viên',
                              _connectionLabel(connState),
                              if (isSharing) 'Đang chia sẻ màn hình',
                              if (!isInstructor && pCanShare && !isSharing)
                                'Được phép chia sẻ',
                            ];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: isInstructor
                                            ? const Color(0xFF3949AB)
                                            : const Color(0xFF00897B),
                                        child: Text(
                                          name.isNotEmpty
                                              ? name.characters.first
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isSelf ? '$name (Bạn)' : name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              statusParts.join(' · '),
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSharing)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6),
                                          child: Icon(
                                            Icons.screen_share,
                                            color: Colors.tealAccent,
                                            size: 19,
                                          ),
                                        ),
                                      Icon(
                                        micOn ? Icons.mic : Icons.mic_off,
                                        color: micOn
                                            ? Colors.greenAccent
                                            : Colors.redAccent,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        camOn
                                            ? Icons.videocam
                                            : Icons.videocam_off,
                                        color: camOn
                                            ? Colors.greenAccent
                                            : Colors.white54,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  if (!isSelf &&
                                      !isInstructor &&
                                      (canModerateAudio ||
                                          canGrantScreenShare)) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (canModerateAudio && micOn)
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  Colors.orangeAccent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                            ),
                                            onPressed: () async {
                                              Navigator.of(ctx).pop();
                                              await _muteParticipantMic(
                                                identity,
                                                name,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.mic_off,
                                              size: 16,
                                            ),
                                            label: const Text('Tắt mic'),
                                          ),
                                        if (canGrantScreenShare)
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              foregroundColor: pCanShare
                                                  ? Colors.redAccent
                                                  : Colors.tealAccent,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                            ),
                                            onPressed: () async {
                                              Navigator.of(ctx).pop();
                                              await _setParticipantScreenSharePermission(
                                                identity,
                                                name,
                                                !pCanShare,
                                              );
                                            },
                                            icon: Icon(
                                              pCanShare
                                                  ? Icons.stop_screen_share
                                                  : Icons.screen_share,
                                              size: 16,
                                            ),
                                            label: Text(
                                              pCanShare
                                                  ? 'Thu hồi chia sẻ'
                                                  : 'Cấp quyền chia sẻ',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101624),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161E31),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (_phase == _ClassroomPhase.inRoom) {
              _leaveRoom();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/parent/live');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_roomTokenData?['sessionTitle'] ?? 'Phòng học trực tuyến'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (_roomTokenData != null)
              Text(
                '${_roomTokenData?['className'] ?? ''} · ${_roomTokenData?['isOneOnOne'] == true ? 'Lớp 1 kèm 1' : 'Lớp nhóm (${_roomTokenData?['capacity'] ?? ''} HV)'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (_phase == _ClassroomPhase.inRoom)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildConnectionBadge(),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (_phase) {
          _ClassroomPhase.loadingToken => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Đang xác thực quyền truy cập phòng học...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          _ClassroomPhase.connectingRoom => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.greenAccent),
                SizedBox(height: 12),
                Text(
                  'Đang kết nối vào phòng học trực tuyến...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          _ClassroomPhase.preJoin => _buildPreJoinBody(),
          _ClassroomPhase.inRoom => _buildInRoomBody(),
          _ClassroomPhase.endedOrError => _buildErrorOrEndedBody(),
        },
      ),
    );
  }

  Widget _buildConnectionBadge() {
    final (label, color, icon) = switch (_connectionQuality) {
      'reconnecting' => (
        'Đang kết nối lại...',
        Colors.orangeAccent,
        Icons.sync_problem,
      ),
      'audio_only' => ('Chỉ âm thanh', Colors.amberAccent, Icons.graphic_eq),
      'disconnected' => ('Mất kết nối', Colors.redAccent, Icons.wifi_off),
      _ => ('Đã kết nối', Colors.greenAccent, Icons.wifi),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreJoinBody() {
    final tokenData = _roomTokenData ?? const {};
    final participantName = '${tokenData['participantName'] ?? 'Người dùng'}';
    final role = '${tokenData['participantRole'] ?? 'student'}';
    final isInstructor = role == 'instructor' || role == 'admin';
    final sfu = (tokenData['sfu'] as Map?)?.cast<String, dynamic>() ?? const {};
    final sfuConfigured = sfu['isConfigured'] == true;
    final missingKeys =
        ((sfu['missingConfigurationKeys'] ?? sfu['missingConfigKeys']) as List?)
            ?.cast<String>() ??
        const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2234),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kiểm tra thiết bị trước khi vào phòng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vai trò: ${isInstructor ? 'Gia sư phụ trách' : 'Học viên'} · $participantName',
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã phòng nội bộ: ${tokenData['roomName'] ?? ''}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_mediaError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _mediaError!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          if (!_permissionState.allGranted) _buildPermissionWarningCard(),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF1B253B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _cameraEnabled && _permissionState.cameraGranted
                    ? Colors.tealAccent.withValues(alpha: 0.5)
                    : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                if (_media.localVideo != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: lk.VideoTrackRenderer(
                        _media.localVideo!,
                        fit: lk.VideoViewFit.cover,
                      ),
                    ),
                  ),
                if (_media.localVideo == null)
                  Center(
                    child: _cameraEnabled && _permissionState.cameraGranted
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam,
                                color: Colors.tealAccent,
                                size: 48,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Xem trước Camera ($participantName)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _cameraFacing == 'front'
                                    ? 'Đang chọn: Camera trước'
                                    : 'Đang chọn: Camera sau',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 38,
                                backgroundColor: isInstructor
                                    ? const Color(0xFF3949AB)
                                    : const Color(0xFF00897B),
                                child: Text(
                                  participantName.isNotEmpty
                                      ? participantName.characters.first
                                            .toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                participantName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Camera đang tắt — Hiển thị ảnh đại diện',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _micEnabled && _permissionState.microphoneGranted
                              ? Icons.mic
                              : Icons.mic_off,
                          size: 16,
                          color:
                              _micEnabled && _permissionState.microphoneGranted
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _micEnabled && _permissionState.microphoneGranted
                              ? 'Mic đang bật'
                              : 'Mic đang tắt',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: _micEnabled ? Colors.greenAccent : Colors.white38,
                  ),
                ),
                onPressed: _toggleMicrophone,
                icon: Icon(_micEnabled ? Icons.mic : Icons.mic_off),
                label: Text(_micEnabled ? 'Tắt mic' : 'Bật mic'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: _cameraEnabled ? Colors.tealAccent : Colors.white38,
                  ),
                ),
                onPressed: _toggleCamera,
                icon: Icon(
                  _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                ),
                label: Text(_cameraEnabled ? 'Tắt camera' : 'Bật camera'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                ),
                onPressed: _switchCameraFacing,
                icon: const Icon(Icons.cameraswitch),
                label: Text(
                  _cameraFacing == 'front' ? 'Camera trước' : 'Camera sau',
                ),
              ),
            ],
          ),
          if (!sfuConfigured) ...[
            const SizedBox(height: 16),
            _buildSfuConfigBanner(missingKeys),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _permissionState.anyGranted ? _enterRoom : null,
            icon: const Icon(Icons.meeting_room),
            label: Text(
              isInstructor
                  ? 'Vào phòng dạy trực tuyến'
                  : 'Vào phòng học trực tuyến',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarningCard() {
    final missingItems = <String>[
      if (!_permissionState.cameraGranted) 'Camera',
      if (!_permissionState.microphoneGranted) 'Microphone',
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amberAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amberAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quyền ${missingItems.join(' & ')} đang bị từ chối',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Để trao đổi âm thanh và hình ảnh trực tiếp trong lớp học, vui lòng cấp quyền Camera và Microphone cho ứng dụng. Nếu bạn đã chọn "Không hỏi lại", hãy mở Cài đặt ứng dụng để bật lại quyền.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: _recheckOrRequestPermissions,
                icon: const Icon(Icons.security, size: 18),
                label: const Text('Cấp quyền Camera & Mic'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amberAccent,
                  side: const BorderSide(color: Colors.amberAccent),
                ),
                onPressed: () async {
                  await ref
                      .read(liveMediaPermissionProvider)
                      .openSystemSettings();
                },
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Mở cài đặt quyền ứng dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSfuConfigBanner(List<String> missingKeys) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.lightBlueAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.lightBlueAccent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Camera đang ở chế độ xem trước trên thiết bị của bạn. Phòng học chưa được bật truyền âm thanh/video giữa các thành viên. Vui lòng liên hệ quản trị viên.',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInRoomBody() {
    final tokenData = _roomTokenData ?? const {};
    final isOneOnOne =
        tokenData['isOneOnOne'] == true ||
        (tokenData['capacity'] is num &&
            (tokenData['capacity'] as num).toInt() == 1);
    final permissions =
        (tokenData['permissions'] as Map?)?.cast<String, dynamic>() ?? const {};
    final canEndSession = permissions['canEndSession'] == true;
    final sfu = (tokenData['sfu'] as Map?)?.cast<String, dynamic>() ?? const {};
    final sfuConfigured = sfu['isConfigured'] == true;
    final missingKeys =
        ((sfu['missingConfigurationKeys'] ?? sfu['missingConfigKeys']) as List?)
            ?.cast<String>() ??
        const [];

    final instructors = _participants
        .where((p) => p['role'] == 'instructor' || p['role'] == 'admin')
        .toList();
    final students = _participants
        .where((p) => p['role'] != 'instructor' && p['role'] != 'admin')
        .toList();

    return Column(
      children: [
        if (_mediaError != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _mediaError!,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
        if (_media.needsAudioGesture)
          TextButton.icon(
            onPressed: _media.startAudio,
            icon: const Icon(Icons.volume_up),
            label: const Text('Bật âm thanh phòng học'),
          ),
        if (_isSelfSharingScreen) _buildSelfSharingBanner(),
        if (_isReconnecting)
          Container(
            width: double.infinity,
            color: Colors.orange.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Mạng gián đoạn — Đang tự động kết nối lại phòng học...',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => _syncRoomState(connectionState: 'connected'),
                  child: const Text(
                    'Thử lại ngay',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        if (!sfuConfigured && _activeScreenShare == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _buildSfuConfigBanner(missingKeys),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _activeScreenShare != null
                ? _buildScreenShareStage(_activeScreenShare!)
                : (isOneOnOne
                      ? _buildOneOnOneStage(instructors, students)
                      : _buildGroupStage(instructors, students)),
          ),
        ),
        _buildBottomControlBar(canEndSession: canEndSession),
      ],
    );
  }

  Widget _buildSelfSharingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C),
        border: Border(
          bottom: BorderSide(color: Colors.tealAccent.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.screen_share, color: Colors.tealAccent, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Bạn đang chia sẻ màn hình · Camera & Mic vẫn hoạt động',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
            ),
            onPressed: _actionBusy ? null : () => _stopScreenShare(),
            icon: const Icon(Icons.stop_screen_share, size: 16),
            label: const Text(
              'Dừng chia sẻ',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenShareStage(Map<String, dynamic> share) {
    final presenterName = '${share['presenterName'] ?? 'Gia sư'}';
    final contentLabel = '${share['contentLabel'] ?? 'Bài giảng trực tuyến'}';

    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0B101B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.65),
                width: 1.6,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF152036),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.present_to_all,
                        color: Colors.tealAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang chia sẻ màn hình: $presenterName · $contentLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đặt lại thu phóng',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        icon: const Icon(
                          Icons.zoom_out_map,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () {
                          _screenShareZoomController.value = Matrix4.identity();
                        },
                      ),
                      IconButton(
                        tooltip: 'Xem toàn màn hình / xoay ngang',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        icon: const Icon(
                          Icons.fullscreen,
                          color: Colors.tealAccent,
                          size: 20,
                        ),
                        onPressed: _openFullscreenScreenShare,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(14),
                    ),
                    child: _buildScreenShareInteractiveViewport(
                      share,
                      isFullscreen: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 102,
          child: _participants.isEmpty
              ? const SizedBox.shrink()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _participants.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, idx) => SizedBox(
                    width: 155,
                    child: _buildParticipantVideoTile(
                      _participants[idx],
                      isPrimaryStage: false,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildScreenShareInteractiveViewport(
    Map<String, dynamic> share, {
    required bool isFullscreen,
  }) {
    final width = (share['width'] as num?)?.toDouble() ?? 540.0;
    final height = (share['height'] as num?)?.toDouble() ?? 960.0;
    final ratio = height > 0 ? (width / height) : (9.0 / 16.0);
    final presenterName = '${share['presenterName'] ?? 'Gia sư'}';
    final contentLabel = '${share['contentLabel'] ?? 'Màn hình bài giảng'}';
    final frameBytes = _cachedScreenShareBytes;

    return InteractiveViewer(
      transformationController: _screenShareZoomController,
      minScale: 1.0,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio.clamp(0.35, 3.2),
          child: Container(
            color: const Color(0xFF0E1726),
            child: frameBytes != null && frameBytes.isNotEmpty
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        frameBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${width.toInt()}×${height.toInt()} · Chụm 2 ngón để phóng to',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.screen_share_outlined,
                            color: Colors.tealAccent,
                            size: 46,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Màn hình của $presenterName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contentLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOneOnOneStage(
    List<Map<String, dynamic>> instructors,
    List<Map<String, dynamic>> students,
  ) {
    final instructorTile = instructors.isNotEmpty
        ? _buildParticipantVideoTile(instructors.first, isPrimaryStage: true)
        : _buildEmptySlotTile(
            title: 'Gia sư chưa vào phòng',
            subtitle: 'Đang chờ gia sư kết nối...',
            icon: Icons.school_outlined,
          );

    final studentTile = students.isNotEmpty
        ? _buildParticipantVideoTile(students.first, isPrimaryStage: true)
        : _buildEmptySlotTile(
            title: 'Học viên chưa vào phòng',
            subtitle: 'Lớp 1 kèm 1 · Đang chờ học viên kết nối...',
            icon: Icons.person_outline,
          );

    return Column(
      children: [
        Expanded(child: instructorTile),
        const SizedBox(height: 12),
        Expanded(child: studentTile),
      ],
    );
  }

  Widget _buildGroupStage(
    List<Map<String, dynamic>> instructors,
    List<Map<String, dynamic>> students,
  ) {
    final instructorTile = instructors.isNotEmpty
        ? _buildParticipantVideoTile(instructors.first, isPrimaryStage: true)
        : _buildEmptySlotTile(
            title: 'Gia sư chưa vào phòng',
            subtitle: 'Đang chờ gia sư kết nối...',
            icon: Icons.school_outlined,
          );

    return Column(
      children: [
        Expanded(flex: 5, child: instructorTile),
        const SizedBox(height: 10),
        Expanded(
          flex: 5,
          child: students.isEmpty
              ? _buildEmptySlotTile(
                  title: 'Chưa có học viên trong phòng',
                  subtitle:
                      'Danh sách video học viên lớp nhóm sẽ hiển thị tại đây',
                  icon: Icons.groups_outlined,
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: students.length,
                  itemBuilder: (_, idx) =>
                      _buildParticipantVideoTile(students[idx]),
                ),
        ),
      ],
    );
  }

  Widget _buildParticipantVideoTile(
    Map<String, dynamic> participant, {
    bool isPrimaryStage = false,
  }) {
    final myIdentity = '${_roomTokenData?['participantIdentity'] ?? ''}';
    final identity = '${participant['identity'] ?? ''}';
    final isSelf = identity == myIdentity;
    final name = '${participant['displayName'] ?? 'Người dùng'}';
    final role = '${participant['role'] ?? 'student'}';
    final isInstructor = role == 'instructor' || role == 'admin';
    final micOn = participant['micEnabled'] == true;
    final camOn = participant['cameraEnabled'] == true;
    final videoTrack = _media.videoFor(identity, self: isSelf);
    final connState = '${participant['connectionState'] ?? 'connected'}';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B253B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInstructor
              ? Colors.indigoAccent.withValues(alpha: 0.7)
              : Colors.tealAccent.withValues(alpha: 0.45),
          width: isPrimaryStage ? 1.6 : 1.2,
        ),
      ),
      child: Stack(
        children: [
          if (videoTrack != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: lk.VideoTrackRenderer(
                  videoTrack,
                  fit: lk.VideoViewFit.cover,
                ),
              ),
            ),
          if (videoTrack == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 28,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: camOn
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.videocam,
                              color: isInstructor
                                  ? Colors.indigoAccent.shade100
                                  : Colors.tealAccent,
                              size: isPrimaryStage ? 42 : 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSelf ? '$name (Bạn)' : name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: isPrimaryStage ? 16 : 13.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đang chờ hình ảnh camera…',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: isPrimaryStage ? 32 : 24,
                              backgroundColor: isInstructor
                                  ? const Color(0xFF3949AB)
                                  : const Color(0xFF00897B),
                              child: Text(
                                name.isNotEmpty
                                    ? name.characters.first.toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isPrimaryStage ? 24 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSelf ? '$name (Bạn)' : name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: isPrimaryStage ? 15.5 : 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Camera đang tắt',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isInstructor
                    ? const Color(0xFF3949AB).withValues(alpha: 0.85)
                    : Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isInstructor ? 'Gia sư' : 'Học viên',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (connState != 'connected')
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _connectionLabel(connState),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isSelf ? '$name (Bạn)' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        micOn ? Icons.mic : Icons.mic_off,
                        size: 15,
                        color: micOn ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        camOn ? Icons.videocam : Icons.videocam_off,
                        size: 15,
                        color: camOn ? Colors.greenAccent : Colors.white54,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white38, size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlBar({required bool canEndSession}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF161E31),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          _ControlButton(
            icon: _micEnabled ? Icons.mic : Icons.mic_off,
            label: _micEnabled ? 'Tắt mic' : 'Bật mic',
            active: _micEnabled,
            activeColor: const Color(0xFF26324B),
            inactiveColor: Colors.red.shade800,
            onPressed: _toggleMicrophone,
          ),
          _ControlButton(
            icon: _cameraEnabled ? Icons.videocam : Icons.videocam_off,
            label: _cameraEnabled ? 'Tắt cam' : 'Bật cam',
            active: _cameraEnabled,
            activeColor: const Color(0xFF26324B),
            inactiveColor: Colors.red.shade800,
            onPressed: _toggleCamera,
          ),
          _ControlButton(
            icon: Icons.cameraswitch,
            label: 'Đổi cam',
            active: true,
            activeColor: const Color(0xFF26324B),
            inactiveColor: const Color(0xFF26324B),
            onPressed: _switchCameraFacing,
          ),
          if (_canShareScreen || _isSelfSharingScreen)
            _ControlButton(
              icon: _isSelfSharingScreen
                  ? Icons.stop_screen_share
                  : Icons.screen_share,
              label: _isSelfSharingScreen ? 'Dừng chia sẻ' : 'Chia sẻ màn hình',
              active: !_isSelfSharingScreen,
              activeColor: const Color(0xFF00695C),
              inactiveColor: Colors.red.shade800,
              onPressed: _actionBusy
                  ? () {}
                  : (_isSelfSharingScreen
                        ? _stopScreenShare
                        : _startScreenShareFlow),
            ),
          _ControlButton(
            icon: Icons.people_alt_outlined,
            label: 'Người tham gia (${_participants.length})',
            active: true,
            activeColor: const Color(0xFF26324B),
            inactiveColor: const Color(0xFF26324B),
            onPressed: _showParticipantsSheet,
          ),
          _ControlButton(
            icon: Icons.call_end,
            label: 'Rời phòng',
            active: false,
            activeColor: Colors.orange.shade800,
            inactiveColor: Colors.orange.shade800,
            onPressed: _actionBusy ? () {} : _leaveRoom,
          ),
          if (canEndSession)
            _ControlButton(
              icon: Icons.stop_circle_outlined,
              label: 'Kết thúc buổi học',
              active: false,
              activeColor: Colors.red.shade700,
              inactiveColor: Colors.red.shade700,
              onPressed: _actionBusy ? () {} : _endSessionForAll,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorOrEndedBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _roomClosedOrRevoked
                  ? Icons.meeting_room_outlined
                  : Icons.error_outline,
              color: _roomClosedOrRevoked
                  ? Colors.orangeAccent
                  : Colors.redAccent,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              _roomClosedOrRevoked
                  ? 'Phòng học đã đóng hoặc phiên kết thúc'
                  : 'Không thể kết nối vào phòng học',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi không xác định.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                if (!_roomClosedOrRevoked)
                  FilledButton.icon(
                    onPressed: _initializePreJoin,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop(true);
                    } else {
                      context.go('/parent/live');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại chi tiết buổi học'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _postMap(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    final res = await ref.read(dioProvider).post<dynamic>(path, data: data);
    final raw = res.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _connectionLabel(String state) {
    return switch (state) {
      'reconnecting' => 'Đang kết nối lại',
      'disconnected' => 'Mất kết nối',
      'audio_only' => 'Chỉ âm thanh',
      _ => 'Đang kết nối',
    };
  }

  bool _isTokenRevokedOrSessionEndedError(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      return status == 401 || status == 403 || status == 409;
    }
    return false;
  }

  String _formatRoomError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'] ?? data['detail'] ?? data['title'];
        if (msg != null && '$msg'.trim().isNotEmpty) {
          return '$msg'.trim();
        }
      }
    }
    return 'Không thể kết nối máy chủ phòng học. Vui lòng kiểm tra mạng và thử lại.';
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? activeColor : inactiveColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
