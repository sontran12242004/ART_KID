import '../../../core/routing/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_interceptor.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/connected_api.dart';
import 'family_screens.dart';
import 'widgets.dart';

export 'live_classroom_screen.dart';

typedef UrlLauncherCallback = Future<bool> Function(Uri uri);

final urlLauncherProvider = Provider<UrlLauncherCallback>((ref) {
  return (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
});

String formatSessionDate(dynamic startsAt) {
  if (startsAt == null) return 'Chưa xác định ngày';
  final dt = DateTime.parse(startsAt.toString()).toLocal();
  return DateFormat('dd/MM/yyyy').format(dt);
}

String formatSessionTimeRange(dynamic startsAt, dynamic endsAt) {
  if (startsAt == null || endsAt == null) return 'Chưa xác định giờ';
  final start = DateTime.parse(startsAt.toString()).toLocal();
  final end = DateTime.parse(endsAt.toString()).toLocal();
  final fmt = DateFormat('HH:mm');
  return '${fmt.format(start)} – ${fmt.format(end)}';
}

String formatSessionDateTimeRange(dynamic startsAt, dynamic endsAt) {
  if (startsAt == null || endsAt == null) return 'Chưa có lịch';
  return '${formatSessionDate(startsAt)} · ${formatSessionTimeRange(startsAt, endsAt)}';
}

String formatDurationSeconds(dynamic secondsRaw) {
  final seconds = (secondsRaw as num?)?.toInt() ?? 0;
  if (seconds <= 0) return '0 phút';
  final mins = seconds ~/ 60;
  final rem = seconds % 60;
  if (mins == 0) return '$rem giây';
  if (rem == 0) return '$mins phút';
  return '$mins phút $rem giây';
}

String liveEffectiveStatusLabel(dynamic effectiveStatus) {
  return switch (effectiveStatus?.toString()) {
    'live' => 'Đang diễn ra',
    'scheduled' => 'Sắp diễn ra',
    'completed' => 'Đã kết thúc',
    'cancelled' => 'Đã hủy',
    _ => statusLabel(effectiveStatus),
  };
}

Color liveEffectiveStatusColor(dynamic effectiveStatus) {
  return switch (effectiveStatus?.toString()) {
    'live' => const Color(0xFF00897B),
    'scheduled' => const Color(0xFF5E35B1),
    'completed' => const Color(0xFF546E7A),
    'cancelled' => const Color(0xFFC62828),
    _ => Colors.blueGrey,
  };
}

IconData providerIcon(dynamic providerLabel) {
  final text = (providerLabel?.toString() ?? '').toLowerCase();
  if (text.contains('zoom')) return Icons.videocam_rounded;
  if (text.contains('meet') || text.contains('google')) {
    return Icons.video_camera_front_rounded;
  }
  if (text.contains('teams') || text.contains('microsoft')) {
    return Icons.groups_rounded;
  }
  return Icons.cast_for_education_rounded;
}

String formatStudentSummary(
  Map<String, dynamic> sessionOrClass, {
  required bool isStaff,
}) {
  final capacity = (sessionOrClass['capacity'] as num?)?.toInt() ?? 30;
  final enrolledCount = (sessionOrClass['enrolledCount'] as num?)?.toInt() ?? 0;
  final rawNames = sessionOrClass['enrolledStudentNames'];
  final names = rawNames is List
      ? rawNames
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
      : <String>[];

  if (capacity == 1) {
    if (names.isNotEmpty) {
      return '${names.first} (Lớp 1 kèm 1)';
    }
    final singleChild = sessionOrClass['childNickname']?.toString();
    if (singleChild != null && singleChild.isNotEmpty) {
      return '$singleChild (Lớp 1 kèm 1)';
    }
    return enrolledCount > 0
        ? '1/1 học viên (Lớp 1 kèm 1)'
        : 'Chưa có học viên (Lớp 1 kèm 1)';
  }

  if (isStaff) {
    if (names.length == 1 && enrolledCount == 1) {
      return '1/$capacity học viên (${names.first})';
    }
    return '$enrolledCount/$capacity học viên';
  }

  final childName = sessionOrClass['childNickname']?.toString();
  if (childName != null && childName.isNotEmpty) {
    return childName;
  }
  return '$enrolledCount/$capacity học viên';
}

Future<void> joinLiveSession(
  BuildContext context,
  WidgetRef ref, {
  required String sessionId,
  required bool isStaff,
  String? childId,
}) async {
  if (!isStaff && (childId == null || childId.isEmpty)) {
    toast(
      context,
      'Vui lòng chọn hồ sơ bé trước khi tham gia lớp học.',
      error: true,
    );
    return;
  }
  final query = !isStaff && childId != null && childId.isNotEmpty
      ? '?childId=$childId'
      : '';
  ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
  await context.push('/parent/live/sessions/$sessionId/room$query');
  ref.invalidate(apiDataProvider);
}

Future<void> showEditOrScheduleSessionDialog(
  BuildContext context,
  WidgetRef ref, {
  required String classId,
  Map<String, dynamic>? existingSession,
  bool roomLinkOnly = false,
}) async {
  final isEdit = existingSession != null;
  final currentTitle = existingSession?['title']?.toString() ?? '';
  final currentStartsAt = existingSession?['startsAt'] != null
      ? DateTime.parse(
          existingSession!['startsAt'].toString(),
        ).toLocal().toIso8601String()
      : DateTime.now().add(const Duration(minutes: 15)).toIso8601String();
  final currentEndsAt = existingSession?['endsAt'] != null
      ? DateTime.parse(
          existingSession!['endsAt'].toString(),
        ).toLocal().toIso8601String()
      : DateTime.now().add(const Duration(hours: 1, minutes: 15)).toIso8601String();
  final currentRoomUrl = existingSession?['roomUrl']?.toString() ?? '';
  final currentProvider =
      existingSession?['provider']?.toString() ?? 'google_meet';
  final currentLessonId = existingSession?['lessonId']?.toString() ?? '';

  final fields = roomLinkOnly && isEdit
      ? [
          EntryField(
            'roomUrl',
            'Đường dẫn phòng học trực tuyến (HTTPS)',
            value: currentRoomUrl,
          ),
          EntryField(
            'provider',
            'Nền tảng (zoom / google_meet / microsoft_teams)',
            value: currentProvider,
          ),
        ]
      : [
          EntryField('title', 'Tên buổi học', value: currentTitle),
          EntryField(
            'startsAt',
            'Giờ bắt đầu (ISO)',
            value: currentStartsAt,
          ),
          EntryField(
            'endsAt',
            'Giờ kết thúc (ISO)',
            value: currentEndsAt,
          ),
          EntryField(
            'roomUrl',
            'Đường dẫn phòng học HTTPS (để trống nếu chưa có)',
            value: currentRoomUrl,
            required: false,
          ),
          EntryField(
            'provider',
            'Nền tảng (zoom / google_meet / microsoft_teams)',
            value: currentProvider,
          ),
        ];

  final v = await askFields(
    context,
    roomLinkOnly
        ? 'Cập nhật liên kết phòng học'
        : isEdit
        ? 'Cập nhật lịch & phòng học'
        : 'Lên lịch buổi dạy mới',
    fields,
  );
  if (v == null || !context.mounted) return;

  final title = (roomLinkOnly ? currentTitle : v['title'] ?? '').trim();
  if (title.isEmpty) {
    toast(context, 'Vui lòng nhập tên buổi học.', error: true);
    return;
  }

  DateTime startsAtUtc;
  DateTime endsAtUtc;
  try {
    startsAtUtc = DateTime.parse(
      roomLinkOnly ? currentStartsAt : v['startsAt']!.trim(),
    ).toUtc();
    endsAtUtc = DateTime.parse(
      roomLinkOnly ? currentEndsAt : v['endsAt']!.trim(),
    ).toUtc();
  } catch (_) {
    toast(context, 'Định dạng thời gian không hợp lệ.', error: true);
    return;
  }

  if (!endsAtUtc.isAfter(startsAtUtc)) {
    toast(context, 'Giờ kết thúc phải sau giờ bắt đầu.', error: true);
    return;
  }

  final rawRoomUrl = (v['roomUrl'] ?? '').trim();
  if (rawRoomUrl.isNotEmpty) {
    final uri = Uri.tryParse(rawRoomUrl);
    if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
      toast(
        context,
        'Liên kết phòng học bắt buộc sử dụng giao thức https://.',
        error: true,
      );
      return;
    }
  }

  final rawProvider = (v['provider'] ?? '').trim();
  final payload = <String, dynamic>{
    'title': title,
    'startsAt': startsAtUtc.toIso8601String(),
    'endsAt': endsAtUtc.toIso8601String(),
    'roomUrl': rawRoomUrl.isEmpty ? null : rawRoomUrl,
    'provider': rawProvider.isEmpty ? 'external' : rawProvider,
    'lessonId': currentLessonId.isEmpty ? null : currentLessonId,
  };

  final endpoint = isEdit
      ? '/live/classes/$classId/sessions/${existingSession['id']}'
      : '/live/classes/$classId/sessions';
  await mutate(
    context,
    ref,
    endpoint,
    payload,
    method: isEdit ? 'PUT' : 'POST',
    success: isEdit
        ? 'Đã cập nhật thông tin buổi dạy.'
        : 'Đã tạo lịch buổi dạy mới.',
  );
}

class LiveClassesScreen extends ConsumerStatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  ConsumerState<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends ConsumerState<LiveClassesScreen> {
  String? _selectedFilter;
  bool _showClassesCatalog = false;

  String _effectiveFilter(bool isStaff) {
    return _selectedFilter ?? (isStaff ? 'all' : 'upcoming');
  }

  String _sessionsPath(String? childId, bool isStaff) {
    final params = <String, String>{
      'status': _effectiveFilter(isStaff),
      'pageSize': '50',
    };
    if (!isStaff && childId != null && childId.isNotEmpty) {
      params['childId'] = childId;
    }
    final query = Uri(queryParameters: params).query;
    return '/live/sessions?$query';
  }

  String _classesPath(String? childId, bool isStaff) {
    final params = <String, String>{'pageSize': '50'};
    if (!isStaff && childId != null && childId.isNotEmpty) {
      params['childId'] = childId;
    }
    final query = Uri(queryParameters: params).query;
    return '/live/classes?$query';
  }

  Future<void> _refreshAll(String sessionsPath, String classesPath) async {
    ref.invalidate(apiDataProvider(sessionsPath));
    ref.invalidate(apiDataProvider(classesPath));
    try {
      await Future.wait([
        ref.read(apiDataProvider(sessionsPath).future),
        ref.read(apiDataProvider(classesPath).future),
      ]);
    } catch (_) {
      // Errors are rendered by the screen error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final isStaff = user != null && user.role != 'parent';
    final activeFilter = _effectiveFilter(isStaff);
    final selectedChild = auth.selectedChild;
    final childId = selectedChild?.id;
    final sessionsPath = _sessionsPath(childId, isStaff);
    final classesPath = _classesPath(childId, isStaff);
    final sessionsAsync = ref.watch(apiDataProvider(sessionsPath));

    Map<String, dynamic>? counts;
    final rawValue = sessionsAsync.valueOrNull;
    if (rawValue is Map && rawValue['counts'] is Map) {
      counts = Map<String, dynamic>.from(rawValue['counts'] as Map);
    }

    final filters = isStaff
        ? const [
            ('all', 'Tất cả'),
            ('upcoming', 'Sắp diễn ra'),
            ('live', 'Đang diễn ra'),
            ('ended', 'Đã kết thúc'),
            ('cancelled', 'Đã hủy'),
          ]
        : const [
            ('upcoming', 'Sắp diễn ra'),
            ('live', 'Đang diễn ra'),
            ('ended', 'Đã kết thúc'),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Lớp học trực tuyến'),
        actions: [
          IconButton(
            tooltip: _showClassesCatalog
                ? 'Xem lịch buổi học'
                : isStaff
                ? 'Quản lý lớp học'
                : 'Danh sách lớp đăng ký',
            onPressed: () =>
                setState(() => _showClassesCatalog = !_showClassesCatalog),
            icon: Icon(
              _showClassesCatalog
                  ? Icons.event_note_rounded
                  : Icons.class_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => _refreshAll(sessionsPath, classesPath),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isStaff && auth.children.length > 1)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: ChildPicker(),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment<bool>(
                          value: false,
                          icon: const Icon(Icons.videocam_outlined, size: 18),
                          label: Text(
                            isStaff ? 'Lịch giảng dạy' : 'Buổi học',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: const Icon(Icons.school_outlined, size: 18),
                          label: Text(
                            isStaff ? 'Quản lý lớp' : 'Lớp đăng ký',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      selected: {_showClassesCatalog},
                      onSelectionChanged: (selection) {
                        setState(() => _showClassesCatalog = selection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (!_showClassesCatalog)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in filters)
                      ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          counts != null && counts[filter.$1] != null
                              ? '${filter.$2} (${counts[filter.$1]})'
                              : filter.$2,
                        ),
                        selected: activeFilter == filter.$1,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter.$1);
                          }
                        },
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _showClassesCatalog
                  ? _LiveClassesCatalogView(
                      classesPath: classesPath,
                      sessionsPath: sessionsPath,
                      isStaff: isStaff,
                      childId: childId,
                      onSwitchToSessions: () =>
                          setState(() => _showClassesCatalog = false),
                    )
                  : _LiveSessionsListView(
                      sessionsPath: sessionsPath,
                      classesPath: classesPath,
                      selectedFilter: activeFilter,
                      isStaff: isStaff,
                      childId: childId,
                      onExploreClasses: () =>
                          setState(() => _showClassesCatalog = true),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveSessionsListView extends ConsumerWidget {
  const _LiveSessionsListView({
    required this.sessionsPath,
    required this.classesPath,
    required this.selectedFilter,
    required this.isStaff,
    required this.childId,
    required this.onExploreClasses,
  });

  final String sessionsPath;
  final String classesPath;
  final String selectedFilter;
  final bool isStaff;
  final String? childId;
  final VoidCallback onExploreClasses;

  String _emptyTitle() {
    if (isStaff) {
      return switch (selectedFilter) {
        'live' => 'Hiện không có buổi dạy nào đang diễn ra',
        'upcoming' => 'Chưa có buổi dạy nào sắp diễn ra',
        'ended' => 'Chưa có buổi dạy nào đã kết thúc',
        'cancelled' => 'Không có buổi dạy nào bị hủy',
        _ => 'Chưa có lịch giảng dạy trực tuyến',
      };
    }
    return switch (selectedFilter) {
      'live' => 'Hiện không có buổi học nào đang diễn ra',
      'ended' => 'Chưa có buổi học nào đã kết thúc',
      'cancelled' => 'Không có buổi học nào bị hủy',
      _ => 'Chưa có buổi học sắp diễn ra',
    };
  }

  String _emptySubtitle() {
    if (isStaff) {
      return 'Gia sư có thể chuyển sang mục "Quản lý lớp" để lên lịch buổi dạy mới hoặc cập nhật phòng học trực tuyến.';
    }
    return switch (selectedFilter) {
      'live' =>
        'Khi đến giờ học, buổi học của bé sẽ xuất hiện tại đây để tham gia ngay.',
      'ended' =>
        'Các buổi học đã hoàn thành hoặc có bản ghi hình sẽ được lưu tại đây.',
      _ =>
        'Hãy kiểm tra mục "Lớp đăng ký" để đăng ký lớp học trực tuyến cho bé hoặc kéo xuống để làm mới.',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(apiDataProvider(sessionsPath));
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(apiDataProvider(sessionsPath));
        ref.invalidate(apiDataProvider(classesPath));
        try {
          await ref.read(apiDataProvider(sessionsPath).future);
        } catch (_) {}
      },
      child: asyncData.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 16),
            Center(
              child: Text(
                'Đang tải danh sách buổi học trực tuyến...',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không thể tải lịch học trực tuyến',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              apiError(err),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: () => ref.invalidate(apiDataProvider(sessionsPath)),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
        data: (raw) {
          final items = raw is Map && raw['items'] is List
              ? List<Map<String, dynamic>>.from(
                  (raw['items'] as List).map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ),
                )
              : raw is List
              ? List<Map<String, dynamic>>.from(
                  raw.map((e) => Map<String, dynamic>.from(e as Map)),
                )
              : <Map<String, dynamic>>[];

          if (items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.video_chat_outlined,
                  size: 64,
                  color: Colors.deepPurple.shade200,
                ),
                const SizedBox(height: 16),
                Text(
                  _emptyTitle(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _emptySubtitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.invalidate(apiDataProvider(sessionsPath)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Làm mới'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onExploreClasses,
                      icon: const Icon(Icons.school_outlined),
                      label: Text(
                        isStaff ? 'Quản lý lớp học' : 'Xem lớp học đang mở',
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final session = items[index];
              return _LiveSessionCard(
                session: session,
                isStaff: isStaff,
                childId: childId ?? session['childId']?.toString(),
              );
            },
          );
        },
      ),
    );
  }
}

class _LiveSessionCard extends ConsumerStatefulWidget {
  const _LiveSessionCard({
    required this.session,
    required this.isStaff,
    required this.childId,
  });

  final Map<String, dynamic> session;
  final bool isStaff;
  final String? childId;

  @override
  ConsumerState<_LiveSessionCard> createState() => _LiveSessionCardState();
}

class _LiveSessionCardState extends ConsumerState<_LiveSessionCard> {
  void _openDetail(BuildContext context) {
    final s = widget.session;
    final id = s['id']?.toString() ?? '';
    final cid = widget.childId;
    final query = !widget.isStaff && cid != null && cid.isNotEmpty
        ? '?childId=$cid'
        : '';
    context.push('/parent/live/sessions/$id$query');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final effectiveStatus = s['effectiveStatus'] ?? s['status'];
    final statusColor = liveEffectiveStatusColor(effectiveStatus);
    final statusText = liveEffectiveStatusLabel(effectiveStatus);
    final canJoin = s['canJoin'] == true;
    final hasRoomUrl = s['hasRoomUrl'] == true;
    final blockedReason = s['joinBlockedReason']?.toString();
    final providerText =
        s['providerLabel']?.toString() ?? 'Phòng học trực tuyến';
    final className = s['className']?.toString() ?? 'Lớp học trực tuyến';
    final courseTitle = s['courseTitle']?.toString() ?? '';
    final instructorName =
        s['instructorName']?.toString() ?? 'Giáo viên ArtKids';
    final lessonTitle = s['lessonTitle']?.toString();
    final studentSummary = formatStudentSummary(s, isStaff: widget.isStaff);

    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: effectiveStatus == 'live'
              ? const Color(0xFF00897B).withValues(alpha: 0.5)
              : Colors.grey.shade200,
          width: effectiveStatus == 'live' ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          effectiveStatus == 'live'
                              ? Icons.fiber_manual_record
                              : Icons.circle_outlined,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isStaff && !hasRoomUrl
                          ? Colors.orange.shade50
                          : Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isStaff && !hasRoomUrl
                              ? Icons.link_off_rounded
                              : providerIcon(providerText),
                          size: 15,
                          color: widget.isStaff && !hasRoomUrl
                              ? Colors.orange.shade900
                              : Colors.deepPurple.shade700,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            widget.isStaff
                                ? (hasRoomUrl
                                      ? 'Đã có liên kết · $providerText'
                                      : 'Chưa cấu hình liên kết phòng học')
                                : providerText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.isStaff && !hasRoomUrl
                                  ? Colors.orange.shade900
                                  : Colors.deepPurple.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                s['title']?.toString() ?? 'Buổi học trực tuyến',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                courseTitle.isNotEmpty
                    ? '$className · $courseTitle'
                    : className,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.deepPurple.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              if (lessonTitle != null && lessonTitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Bài học: $lessonTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
              const Divider(height: 22),
              if (widget.isStaff) ...[
                if (courseTitle.isNotEmpty) ...[
                  _InfoRow(
                    icon: Icons.palette_outlined,
                    label: 'Môn học',
                    value: courseTitle,
                  ),
                  const SizedBox(height: 6),
                ],
                _InfoRow(
                  icon: Icons.groups_2_outlined,
                  label: 'Học viên',
                  value: studentSummary,
                ),
              ] else
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Giáo viên',
                  value: instructorName,
                ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Ngày học',
                value: formatSessionDate(s['startsAt']),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Khung giờ',
                value: formatSessionTimeRange(s['startsAt'], s['endsAt']),
              ),
              const SizedBox(height: 12),
              if (canJoin)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await joinLiveSession(
                        context,
                        ref,
                        sessionId: s['id'].toString(),
                        isStaff: widget.isStaff,
                        childId: widget.childId,
                      );
                    },
                    icon: const Icon(Icons.videocam_rounded),
                    label: Text(
                      widget.isStaff ? 'Vào phòng dạy' : 'Tham gia lớp học',
                    ),
                  ),
                )
              else if (blockedReason != null && blockedReason.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.amber.shade900,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          blockedReason,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.amber.shade900,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openDetail(context),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: Text(
                    widget.isStaff
                        ? 'Quản lý & chi tiết buổi dạy'
                        : 'Xem chi tiết buổi học',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 125),
          child: Text(
            '$label: ',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class LiveSessionDetailScreen extends ConsumerStatefulWidget {
  const LiveSessionDetailScreen({
    super.key,
    required this.sessionId,
    this.childId,
  });

  final String sessionId;
  final String? childId;

  @override
  ConsumerState<LiveSessionDetailScreen> createState() =>
      _LiveSessionDetailScreenState();
}

class _LiveSessionDetailScreenState
    extends ConsumerState<LiveSessionDetailScreen> {
  bool _leaving = false;
  bool _mutatingState = false;

  String _detailPath(String? resolvedChildId, bool isStaff) {
    if (!isStaff && resolvedChildId != null && resolvedChildId.isNotEmpty) {
      return '/live/sessions/${widget.sessionId}?childId=$resolvedChildId';
    }
    return '/live/sessions/${widget.sessionId}';
  }

  Future<void> _startSession() async {
    if (_mutatingState) return;
    setState(() => _mutatingState = true);
    try {
      await mutate(
        context,
        ref,
        '/live/sessions/${widget.sessionId}/state',
        {'status': 'live'},
        success: 'Đã chuyển buổi dạy sang trạng thái Đang diễn ra.',
      );
    } finally {
      if (mounted) setState(() => _mutatingState = false);
    }
  }

  Future<void> _completeSession(String? currentRecordingUrl) async {
    if (_mutatingState) return;
    final values = await askFields(
      context,
      'Xác nhận kết thúc buổi học',
      [
        EntryField(
          'recordingUrl',
          'Đường dẫn bản ghi hình HTTPS (tùy chọn)',
          value: currentRecordingUrl ?? '',
          required: false,
        ),
      ],
    );
    if (values == null || !mounted) return;
    final rec = (values['recordingUrl'] ?? '').trim();
    if (rec.isNotEmpty) {
      final uri = Uri.tryParse(rec);
      if (uri == null || !uri.hasScheme || uri.scheme != 'https') {
        toast(
          context,
          'Liên kết bản ghi hình phải bắt đầu bằng https://.',
          error: true,
        );
        return;
      }
    }
    setState(() => _mutatingState = true);
    try {
      await mutate(
        context,
        ref,
        '/live/sessions/${widget.sessionId}/state',
        {
          'status': 'completed',
          if (rec.isNotEmpty) 'recordingUrl': rec,
        },
        success: 'Đã kết thúc buổi dạy thành công.',
      );
    } finally {
      if (mounted) setState(() => _mutatingState = false);
    }
  }

  Future<void> _cancelSession(String title) async {
    if (_mutatingState) return;
    final approved = await confirm(
      context,
      'Xác nhận hủy buổi học',
      'Bạn có chắc chắn muốn hủy buổi dạy "$title"? Trạng thái sau khi hủy sẽ không thể hoàn tác.',
    );
    if (!approved || !mounted) return;
    setState(() => _mutatingState = true);
    try {
      await mutate(
        context,
        ref,
        '/live/sessions/${widget.sessionId}/state',
        {'status': 'cancelled'},
        success: 'Đã hủy buổi dạy.',
      );
    } finally {
      if (mounted) setState(() => _mutatingState = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isStaff =
        auth.currentUser != null && auth.currentUser!.role != 'parent';
    final effectiveChildId = widget.childId ?? auth.selectedChild?.id;
    final path = _detailPath(effectiveChildId, isStaff);
    final asyncDetail = ref.watch(apiDataProvider(path));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9EE),
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Chi tiết buổi học'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: () => ref.invalidate(apiDataProvider(path)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(apiDataProvider(path));
            try {
              await ref.read(apiDataProvider(path).future);
            } catch (_) {}
          },
          child: asyncDetail.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
                SizedBox(height: 16),
                Center(child: Text('Đang tải thông tin buổi học...')),
              ],
            ),
            error: (err, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 56,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể mở thông tin buổi học',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  apiError(err),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                Center(
                  child: FilledButton.icon(
                    onPressed: () => ref.invalidate(apiDataProvider(path)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ),
              ],
            ),
            data: (raw) {
              final d = Map<String, dynamic>.from(raw as Map);
              final cls = d['liveClass'] is Map
                  ? Map<String, dynamic>.from(d['liveClass'] as Map)
                  : <String, dynamic>{};
              final lesson = d['lesson'] is Map
                  ? Map<String, dynamic>.from(d['lesson'] as Map)
                  : null;
              final attendance = d['attendance'] is Map
                  ? Map<String, dynamic>.from(d['attendance'] as Map)
                  : null;
              final roster = d['roster'] is List
                  ? List<Map<String, dynamic>>.from(
                      (d['roster'] as List).map(
                        (e) => Map<String, dynamic>.from(e as Map),
                      ),
                    )
                  : <Map<String, dynamic>>[];
              final classSessions = d['classSessions'] is List
                  ? List<Map<String, dynamic>>.from(
                      (d['classSessions'] as List).map(
                        (e) => Map<String, dynamic>.from(e as Map),
                      ),
                    )
                  : <Map<String, dynamic>>[];

              final effectiveStatus = d['effectiveStatus'] ?? d['status'];
              final statusColor = liveEffectiveStatusColor(effectiveStatus);
              final statusText = liveEffectiveStatusLabel(effectiveStatus);
              final canJoin = d['canJoin'] == true;
              final hasRoomUrl = d['hasRoomUrl'] == true;
              final roomUrl = d['roomUrl']?.toString();
              final blockedReason = d['joinBlockedReason']?.toString();
              final providerText =
                  d['providerLabel']?.toString() ?? 'Phòng học trực tuyến';
              final recordingUrl = d['recordingUrl']?.toString();
              final activeChildId =
                  d['childId']?.toString() ?? effectiveChildId;
              final classId = cls['id']?.toString() ?? '';

              final canStartSession =
                  isStaff &&
                  (d['canStartSession'] == true ||
                      (d['canStartSession'] == null &&
                          d['status'] == 'scheduled'));
              final canEndSession =
                  isStaff &&
                  (d['canEndSession'] == true ||
                      (d['canEndSession'] == null && d['status'] == 'live'));
              final canCancelSession =
                  isStaff &&
                  (d['canCancelSession'] == true ||
                      (d['canCancelSession'] == null &&
                          (d['status'] == 'scheduled' ||
                              d['status'] == 'live')));
              final canEditSession =
                  isStaff &&
                  (d['canEditSession'] == true ||
                      (d['canEditSession'] == null &&
                          d['status'] == 'scheduled'));

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isStaff && !hasRoomUrl
                                      ? Colors.orange.shade50
                                      : Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isStaff && !hasRoomUrl
                                          ? Icons.link_off_rounded
                                          : providerIcon(providerText),
                                      size: 16,
                                      color: isStaff && !hasRoomUrl
                                          ? Colors.orange.shade900
                                          : Colors.deepPurple.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        isStaff
                                            ? (hasRoomUrl
                                                  ? 'Đã cấu hình · $providerText'
                                                  : 'Chưa cấu hình liên kết phòng học')
                                            : providerText,
                                        style: TextStyle(
                                          color: isStaff && !hasRoomUrl
                                              ? Colors.orange.shade900
                                              : Colors.deepPurple.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            d['title']?.toString() ?? 'Buổi học trực tuyến',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Giáo viên',
                            value:
                                cls['instructorName']?.toString() ??
                                'Giáo viên ArtKids',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Ngày học',
                            value: formatSessionDate(d['startsAt']),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Thời gian',
                            value: formatSessionTimeRange(
                              d['startsAt'],
                              d['endsAt'],
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.meeting_room_outlined,
                            label: 'Mở phòng từ',
                            value: dateLabel(d['opensAt']),
                          ),
                          if (isStaff &&
                              roomUrl != null &&
                              roomUrl.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.link_rounded,
                              label: 'Liên kết phòng dạy',
                              value: roomUrl,
                            ),
                          ],
                          if (!isStaff &&
                              d['childNickname'] != null &&
                              d['childNickname'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.child_care_rounded,
                              label: 'Học viên',
                              value: d['childNickname'].toString(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (canJoin)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  await joinLiveSession(
                                    context,
                                    ref,
                                    sessionId: widget.sessionId,
                                    isStaff: isStaff,
                                    childId: activeChildId,
                                  );
                                },
                                icon: const Icon(Icons.videocam_rounded),
                                label: Text(
                                  isStaff
                                      ? 'Vào phòng dạy'
                                      : 'Tham gia lớp học',
                                ),
                              ),
                            )
                          else if (blockedReason != null &&
                              blockedReason.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.amber.shade900,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      blockedReason,
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (isStaff &&
                              (canStartSession ||
                                  canEndSession ||
                                  canCancelSession ||
                                  canEditSession)) ...[
                            const Divider(height: 28),
                            const Text(
                              'Điều khiển buổi dạy của Gia sư',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                if (canStartSession)
                                  FilledButton.tonalIcon(
                                    onPressed: _mutatingState
                                        ? null
                                        : _startSession,
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                    ),
                                    label: const Text('Bắt đầu buổi học'),
                                  ),
                                if (canEndSession)
                                  FilledButton.tonalIcon(
                                    onPressed: _mutatingState
                                        ? null
                                        : () => _completeSession(recordingUrl),
                                    icon: const Icon(
                                      Icons.task_alt_rounded,
                                    ),
                                    label: const Text('Kết thúc buổi học'),
                                  ),
                                if (canEditSession && classId.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: _mutatingState
                                        ? null
                                        : () => showEditOrScheduleSessionDialog(
                                            context,
                                            ref,
                                            classId: classId,
                                            existingSession: d,
                                            roomLinkOnly: true,
                                          ),
                                    icon: Icon(
                                      hasRoomUrl
                                          ? Icons.edit_note_rounded
                                          : Icons.add_link_rounded,
                                    ),
                                    label: Text(
                                      hasRoomUrl
                                          ? 'Cập nhật liên kết phòng học'
                                          : 'Thêm liên kết phòng học',
                                    ),
                                  ),
                                if (canEditSession && classId.isNotEmpty)
                                  OutlinedButton.icon(
                                    onPressed: _mutatingState
                                        ? null
                                        : () => showEditOrScheduleSessionDialog(
                                            context,
                                            ref,
                                            classId: classId,
                                            existingSession: d,
                                          ),
                                    icon: const Icon(
                                      Icons.edit_calendar_rounded,
                                    ),
                                    label: const Text('Đổi lịch / Sửa buổi học'),
                                  ),
                                if (canCancelSession)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                    ),
                                    onPressed: _mutatingState
                                        ? null
                                        : () => _cancelSession(
                                            d['title']?.toString() ??
                                                'Buổi học',
                                          ),
                                    icon: const Icon(Icons.cancel_outlined),
                                    label: const Text('Hủy buổi học'),
                                  ),
                              ],
                            ),
                          ],
                          if (!isStaff &&
                              attendance != null &&
                              attendance['lastJoinedAt'] != null &&
                              activeChildId != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _leaving
                                    ? null
                                    : () async {
                                        setState(() => _leaving = true);
                                        try {
                                          await mutate(
                                            context,
                                            ref,
                                            '/live/sessions/${widget.sessionId}/leave',
                                            {'childId': activeChildId},
                                            success:
                                                'Đã ghi nhận rời phòng học.',
                                          );
                                        } finally {
                                          if (mounted) {
                                            setState(() => _leaving = false);
                                          }
                                        }
                                      },
                                icon: const Icon(Icons.exit_to_app_rounded),
                                label: const Text('Rời phòng học'),
                              ),
                            ),
                          ],
                          if (recordingUrl != null &&
                              recordingUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final uri = Uri.tryParse(recordingUrl);
                                  if (uri == null || uri.scheme != 'https') {
                                    toast(
                                      context,
                                      'Liên kết bản ghi hình không hợp lệ.',
                                      error: true,
                                    );
                                    return;
                                  }
                                  final launched = await ref.read(
                                    urlLauncherProvider,
                                  )(uri);
                                  if (!launched && context.mounted) {
                                    toast(
                                      context,
                                      'Không mở được liên kết bản ghi hình.',
                                      error: true,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.play_circle_outline_rounded,
                                ),
                                label: const Text('Xem lại bản ghi buổi học'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thông tin lớp học & Mô tả',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.groups_outlined,
                            label: 'Tên lớp',
                            value: cls['name']?.toString() ?? '',
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.school_outlined,
                            label: 'Khóa học',
                            value: cls['courseTitle']?.toString() ?? '',
                          ),
                          if (cls['ageRange'] != null &&
                              cls['ageRange'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Độ tuổi phù hợp',
                              value: cls['ageRange'].toString(),
                            ),
                          ],
                          const SizedBox(height: 6),
                          _InfoRow(
                            icon: Icons.people_alt_outlined,
                            label: 'Sĩ số',
                            value:
                                '${cls['enrolledCount'] ?? 0}/${cls['capacity'] ?? 30} học viên (${statusLabel(cls['status'])})',
                          ),
                          if (cls['courseDescription'] != null &&
                              cls['courseDescription']
                                  .toString()
                                  .isNotEmpty) ...[
                            const Divider(height: 22),
                            const Text(
                              'Mô tả khóa học:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cls['courseDescription'].toString(),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isStaff) ...[
                    const SizedBox(height: 14),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danh sách học viên & Điểm danh (${roster.length}/${cls['capacity'] ?? 30})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (roster.isEmpty)
                              Text(
                                'Chưa có học viên nào đăng ký lớp học này.',
                                style: TextStyle(color: Colors.grey.shade700),
                              )
                            else
                              for (final student in roster)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: student['isCurrentlyInRoom'] == true
                                        ? Colors.teal.shade50
                                        : student['attended'] == true
                                        ? Colors.deepPurple.shade50
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          student['isCurrentlyInRoom'] == true
                                          ? Colors.teal.shade300
                                          : student['attended'] == true
                                          ? Colors.deepPurple.shade200
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor:
                                            student['attended'] == true
                                            ? const Color(0xFF00897B)
                                            : Colors.grey.shade400,
                                        child: Icon(
                                          student['attended'] == true
                                              ? Icons.check_rounded
                                              : Icons.person_outline_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student['nickname']?.toString() ??
                                                  'Học viên',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              student['isCurrentlyInRoom'] ==
                                                      true
                                                  ? 'Đang trong phòng học · Vào lúc ${dateLabel(student['firstJoinedAt'])}'
                                                  : student['attended'] == true
                                                  ? 'Đã điểm danh · Thời lượng: ${formatDurationSeconds(student['totalDurationSeconds'])}'
                                                  : 'Chưa tham gia buổi học này',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (lesson != null) ...[
                    const SizedBox(height: 14),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nội dung bài học & Tài liệu hướng dẫn',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Bài ${lesson['orderIndex'] ?? ''}: ${lesson['title'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lesson['practiceInstructions'] != null &&
                                      lesson['practiceInstructions']
                                          .toString()
                                          .trim()
                                          .isNotEmpty
                                  ? lesson['practiceInstructions'].toString()
                                  : 'Chuẩn bị giấy vẽ, bút chì, tẩy và bộ màu theo hướng dẫn của giáo viên trong buổi học.',
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                height: 1.4,
                              ),
                            ),
                            if (!isStaff && lesson['id'] != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    context.push('/kid/lesson/${lesson['id']}'),
                                icon: const Icon(Icons.menu_book_rounded),
                                label: const Text('Mở trang bài học & nộp bài'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (classSessions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lịch các buổi học của lớp (${classSessions.length} buổi)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (final cs in classSessions)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: cs['isCurrent'] == true
                                      ? Colors.deepPurple.shade50
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs['isCurrent'] == true
                                        ? Colors.deepPurple.shade300
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    cs['title']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: cs['isCurrent'] == true
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${formatSessionDateTimeRange(cs['startsAt'], cs['endsAt'])} · ${liveEffectiveStatusLabel(cs['effectiveStatus'])}',
                                    style: const TextStyle(fontSize: 12.5),
                                  ),
                                  trailing: cs['isCurrent'] == true
                                      ? const Chip(
                                          label: Text(
                                            'Đang xem',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        )
                                      : const Icon(Icons.chevron_right),
                                  onTap: cs['isCurrent'] == true
                                      ? null
                                      : () {
                                          final nextId = cs['id']?.toString();
                                          if (nextId != null) {
                                            final query =
                                                !isStaff &&
                                                    activeChildId != null &&
                                                    activeChildId.isNotEmpty
                                                ? '?childId=$activeChildId'
                                                : '';
                                            context.pushReplacement(
                                              '/parent/live/sessions/$nextId$query',
                                            );
                                          }
                                        },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LiveClassesCatalogView extends ConsumerWidget {
  const _LiveClassesCatalogView({
    required this.classesPath,
    required this.sessionsPath,
    required this.isStaff,
    required this.childId,
    required this.onSwitchToSessions,
  });

  final String classesPath;
  final String sessionsPath;
  final bool isStaff;
  final String? childId;
  final VoidCallback onSwitchToSessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncClasses = ref.watch(apiDataProvider(classesPath));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(apiDataProvider(classesPath));
        ref.invalidate(apiDataProvider(sessionsPath));
        try {
          await ref.read(apiDataProvider(classesPath).future);
        } catch (_) {}
      },
      child: asyncClasses.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 16),
            Center(child: Text('Đang tải danh sách lớp học...')),
          ],
        ),
        error: (err, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(apiError(err), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () => ref.invalidate(apiDataProvider(classesPath)),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ),
          ],
        ),
        data: (raw) {
          final classes = raw is List
              ? List<Map<String, dynamic>>.from(
                  raw.map((e) => Map<String, dynamic>.from(e as Map)),
                )
              : <Map<String, dynamic>>[];

          if (classes.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 60),
                Icon(Icons.class_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Chưa có lớp học trực tuyến nào',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: classes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final c = classes[index];
              final isEnrolled = c['isEnrolled'] == true;
              final classId = c['id']?.toString() ?? '';
              final instructorName =
                  c['instructorName']?.toString() ?? 'Giáo viên ArtKids';
              final courseTitle = c['courseTitle']?.toString() ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  title: Text(
                    c['name']?.toString() ?? 'Lớp học trực tuyến',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${courseTitle.isNotEmpty ? '$courseTitle · ' : ''}GV: $instructorName\nSĩ số: ${c['enrolledCount'] ?? 0}/${c['capacity']} học viên · ${statusLabel(c['status'])}${isEnrolled ? ' · Đã đăng ký' : ''}',
                    ),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (!isStaff && !isEnrolled && c['status'] == 'open')
                          ActionButton(
                            label: 'Đăng ký bé vào lớp',
                            icon: Icons.person_add_alt_1_rounded,
                            action: (r) => r
                                .read(dioProvider)
                                .post(
                                  '/live/classes/$classId/enrollments',
                                  data: {'childId': childId},
                                ),
                            onSuccess: (_) {
                              toast(
                                context,
                                'Đã đăng ký bé vào lớp học trực tuyến!',
                              );
                              onSwitchToSessions();
                            },
                          ),
                        if (!isStaff && isEnrolled)
                          OutlinedButton.icon(
                            onPressed: childId == null
                                ? null
                                : () async {
                                    final ok = await confirm(
                                      context,
                                      'Hủy đăng ký lớp',
                                      'Bạn có chắc muốn hủy đăng ký lớp "${c['name']}" cho bé?',
                                    );
                                    if (!ok || !context.mounted) return;
                                    await mutate(
                                      context,
                                      ref,
                                      '/live/classes/$classId/enrollments/$childId',
                                      {},
                                      method: 'DELETE',
                                      success: 'Đã hủy đăng ký lớp.',
                                    );
                                  },
                            icon: const Icon(Icons.cancel_outlined),
                            label: const Text('Hủy đăng ký lớp'),
                          ),
                        if (isStaff)
                          FilledButton.icon(
                            onPressed: () => showEditOrScheduleSessionDialog(
                              context,
                              ref,
                              classId: classId,
                            ),
                            icon: const Icon(Icons.add_alarm_rounded),
                            label: const Text('Lên lịch buổi học'),
                          ),
                        if (isStaff)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final v = await askFields(
                                context,
                                'Cập nhật lớp học',
                                [
                                  EntryField(
                                    'name',
                                    'Tên lớp học',
                                    value: c['name']?.toString() ?? '',
                                  ),
                                  EntryField(
                                    'capacity',
                                    'Sĩ số tối đa (1–30)',
                                    value: '${c['capacity'] ?? 20}',
                                    number: true,
                                  ),
                                  EntryField(
                                    'status',
                                    'Trạng thái (open / active / completed / cancelled)',
                                    value: c['status']?.toString() ?? 'open',
                                  ),
                                ],
                              );
                              if (v == null || !context.mounted) return;
                              final cap = int.tryParse(v['capacity'] ?? '');
                              if (cap == null || cap < 1 || cap > 30) {
                                toast(
                                  context,
                                  'Sĩ số lớp phải từ 1 đến 30 học viên.',
                                  error: true,
                                );
                                return;
                              }
                              await mutate(
                                context,
                                ref,
                                '/live/classes/$classId',
                                {
                                  'name': v['name']!.trim(),
                                  'capacity': cap,
                                  'status': v['status']!.trim(),
                                },
                                method: 'PUT',
                                success: 'Đã cập nhật lớp học.',
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Sửa thông tin lớp'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ApiView(
                      path: '/live/classes/$classId/sessions',
                      builder: (sessions) {
                        final list = sessions is List ? sessions : const [];
                        if (list.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('Lớp chưa có lịch buổi học nào.'),
                          );
                        }
                        return Column(
                          children: [
                            for (final s in list)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  s['title']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${formatSessionDateTimeRange(s['startsAt'], s['endsAt'])} · ${liveEffectiveStatusLabel(s['effectiveStatus'] ?? s['status'])}',
                                ),
                                trailing: ActionButton(
                                  label: isStaff ? 'Vào dạy' : 'Vào lớp',
                                  action: (r) => r
                                      .read(dioProvider)
                                      .post(
                                        '/live/sessions/${s['id']}/join',
                                        data: isStaff
                                            ? {}
                                            : {'childId': childId},
                                      ),
                                  onSuccess: (result) async {
                                    final data = result.data is Map<String, dynamic>
                                        ? result.data as Map<String, dynamic>
                                        : <String, dynamic>{};
                                    final url = data['joinUrl']?.toString();
                                    final inApp = data['inAppRoom'] == true ||
                                        url == null ||
                                        url.contains('/parent/live/sessions/');
                                    if (inApp) {
                                      await joinLiveSession(
                                        context,
                                        ref,
                                        sessionId: s['id'].toString(),
                                        isStaff: isStaff,
                                        childId: childId,
                                      );
                                    } else {
                                      final uri = Uri.tryParse(url);
                                      if (uri != null && uri.scheme == 'https') {
                                        await ref.read(urlLauncherProvider)(uri);
                                      }
                                    }
                                  },
                                ),
                                onTap: () {
                                  final sid = s['id']?.toString();
                                  if (sid != null) {
                                    final query =
                                        !isStaff &&
                                            childId != null &&
                                            childId!.isNotEmpty
                                        ? '?childId=$childId'
                                        : '';
                                    context.push(
                                      '/parent/live/sessions/$sid$query',
                                    );
                                  }
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
