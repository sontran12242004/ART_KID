import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/child_progress_report.dart';
import '../providers/parent_dashboard_provider.dart';

/// Widget hiển thị báo cáo tiến độ học của bé — Parent Mode
class ChildProgressCard extends ConsumerWidget {
  const ChildProgressCard({
    super.key,
    this.childId = 'child-1',
    this.childName = 'Bé Bo',
    this.report,
  });

  final String childId;
  final String childName;
  final ChildProgressReport? report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (report != null) {
      return _buildCard(report!);
    }

    final progressAsync = ref.watch(childProgressReportProvider(childId));

    return progressAsync.when(
      data: _buildCard,
      loading: () => const Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Lỗi: $error'),
        ),
      ),
    );
  }

  Widget _buildCard(ChildProgressReport data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Tiến độ của $childName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _StatRow(
              icon: Icons.school,
              label: 'Bài học đã hoàn thành',
              value: '${data.completedLessonsCount}',
            ),
            _StatRow(
              icon: Icons.brush,
              label: 'Tổng tác phẩm tranh vẽ',
              value: '${data.totalArtworksCount}',
            ),
            _StatRow(
              icon: Icons.military_tech,
              label: 'Huy hiệu đạt được',
              value: '${data.totalBadgesCount}',
            ),
            _StatRow(
              icon: Icons.timer,
              label: 'Thời gian học tuần này',
              value: '${data.learningMinutesThisWeek} phút',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
