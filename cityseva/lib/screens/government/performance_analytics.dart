import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';

class PerformanceAnalytics extends StatefulWidget {
  const PerformanceAnalytics({super.key});

  @override
  State<PerformanceAnalytics> createState() => _PerformanceAnalyticsState();
}

class _PerformanceAnalyticsState extends State<PerformanceAnalytics> {
  String _selectedPeriod = 'All Time';
  final _periods = ['This Week', 'This Month', 'This Year', 'All Time'];

  List<Complaint> _filterByPeriod(List<Complaint> complaints) {
    final now = DateTime.now();
    return complaints.where((c) {
      switch (_selectedPeriod) {
        case 'This Week':
          return c.createdAt.isAfter(now.subtract(const Duration(days: 7)));
        case 'This Month':
          return c.createdAt.month == now.month && c.createdAt.year == now.year;
        case 'This Year':
          return c.createdAt.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Analytics')),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          final all = _filterByPeriod(provider.complaints);
          final feedbacks = provider.feedbacks;

          final total = all.length;
          final completed = all.where((c) => c.status == ComplaintStatus.completed).length;
          final inProgress = all.where((c) => c.status == ComplaintStatus.workStarted).length;
          final pending = all.where((c) =>
              c.status == ComplaintStatus.submitted || c.status == ComplaintStatus.verified).length;
          final rejected = all.where((c) => c.status == ComplaintStatus.rejected).length;
          final resolutionRate = total == 0 ? 0.0 : (completed / total) * 100;

          // Avg resolution time in days
          final completedComplaints = all.where((c) => c.status == ComplaintStatus.completed).toList();
          double avgResolutionDays = 0;
          if (completedComplaints.isNotEmpty) {
            final totalDays = completedComplaints.fold<int>(
                0, (sum, c) => sum + c.updatedAt.difference(c.createdAt).inDays);
            avgResolutionDays = totalDays / completedComplaints.length;
          }

          // Feedback stats
          final avgRating = feedbacks.isEmpty
              ? 0.0
              : feedbacks.fold<int>(0, (s, f) => s + f.rating) / feedbacks.length;
          final onTimeCount = feedbacks.where((f) => f.completedOnTime).length;
          final onTimeRate = feedbacks.isEmpty ? 0.0 : (onTimeCount / feedbacks.length) * 100;

          // Department breakdown
          final deptMap = <Department, int>{};
          for (final c in all.where((c) => c.status == ComplaintStatus.completed)) {
            deptMap[c.department] = (deptMap[c.department] ?? 0) + 1;
          }
          final sortedDepts = deptMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period filter
              _buildPeriodFilter(),
              const SizedBox(height: 20),

              // Top KPI cards
              _buildSectionTitle('Overview'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _kpiCard('Total Complaints', total.toString(), Icons.assignment_outlined, AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: _kpiCard('Resolved', completed.toString(), Icons.check_circle_outline, AppColors.success)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _kpiCard('In Progress', inProgress.toString(), Icons.construction_outlined, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _kpiCard('Pending', pending.toString(), Icons.hourglass_empty_outlined, AppColors.warning)),
                ],
              ),
              const SizedBox(height: 20),

              // Resolution rate
              _buildSectionTitle('Resolution Rate'),
              const SizedBox(height: 12),
              _buildResolutionCard(resolutionRate, completed, total, rejected),
              const SizedBox(height: 20),

              // Avg resolution time
              _buildSectionTitle('Avg. Resolution Time'),
              const SizedBox(height: 12),
              _buildResolutionTimeCard(avgResolutionDays, completedComplaints.length),
              const SizedBox(height: 20),

              // Citizen feedback
              _buildSectionTitle('Citizen Feedback'),
              const SizedBox(height: 12),
              _buildFeedbackCard(avgRating, onTimeRate, feedbacks.length),
              const SizedBox(height: 20),

              // Department performance
              if (sortedDepts.isNotEmpty) ...[
                _buildSectionTitle('Top Performing Departments'),
                const SizedBox(height: 12),
                _buildDepartmentBreakdown(sortedDepts, completed),
                const SizedBox(height: 20),
              ],

              // Performance score
              _buildSectionTitle('Overall Performance Score'),
              const SizedBox(height: 12),
              _buildPerformanceScore(resolutionRate, avgRating, onTimeRate),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periods.map((p) {
          final selected = _selectedPeriod == p;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = p),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
              ),
              child: Text(p,
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary));
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionCard(double rate, int completed, int total, int rejected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: rate >= 70 ? AppColors.success : rate >= 40 ? AppColors.warning : AppColors.error)),
              _performanceBadge(rate),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                  rate >= 70 ? AppColors.success : rate >= 40 ? AppColors.warning : AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _miniStat('Resolved', completed.toString(), AppColors.success),
              _miniStat('Total', total.toString(), AppColors.primary),
              _miniStat('Rejected', rejected.toString(), AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionTimeCard(double avgDays, int count) {
    String performance;
    Color color;
    if (avgDays == 0) {
      performance = 'No data yet';
      color = AppColors.textSecondary;
    } else if (avgDays <= 3) {
      performance = 'Excellent ⚡';
      color = AppColors.success;
    } else if (avgDays <= 7) {
      performance = 'Good 👍';
      color = AppColors.warning;
    } else {
      performance = 'Needs Improvement ⚠️';
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.timer_outlined, color: AppColors.accent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(avgDays == 0 ? '--' : '${avgDays.toStringAsFixed(1)} days',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Average resolution time', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(performance, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
          Column(
            children: [
              Text(count.toString(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Text('resolved', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(double avgRating, double onTimeRate, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: total == 0
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No feedback received yet', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          : Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                    const SizedBox(width: 8),
                    Text(avgRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Text(' / 5', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('$total reviews', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text('${onTimeRate.toStringAsFixed(0)}% work completed on time',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildDepartmentBreakdown(List<MapEntry<Department, int>> depts, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: depts.take(5).map((e) {
          final pct = total == 0 ? 0.0 : e.value / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(e.key.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.key.label,
                          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    ),
                    Text('${e.value} resolved',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPerformanceScore(double resolutionRate, double avgRating, double onTimeRate) {
    final score = ((resolutionRate * 0.4) + (avgRating * 20 * 0.3) + (onTimeRate * 0.3)).clamp(0, 100);
    Color scoreColor;
    String scoreLabel;
    String scoreEmoji;

    if (score >= 80) {
      scoreColor = AppColors.success;
      scoreLabel = 'Outstanding';
      scoreEmoji = '🏆';
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
      scoreLabel = 'Good';
      scoreEmoji = '👍';
    } else if (score >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Average';
      scoreEmoji = '📊';
    } else {
      scoreColor = AppColors.error;
      scoreLabel = 'Needs Improvement';
      scoreEmoji = '⚠️';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.8), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(scoreEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text('${score.toStringAsFixed(0)}/100',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(scoreLabel, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _scoreBreakdown('Resolution', '${resolutionRate.toStringAsFixed(0)}%'),
              _scoreBreakdown('Rating', avgRating.toStringAsFixed(1)),
              _scoreBreakdown('On Time', '${onTimeRate.toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreBreakdown(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _performanceBadge(double rate) {
    String label;
    Color color;
    if (rate >= 70) {
      label = 'High';
      color = AppColors.success;
    } else if (rate >= 40) {
      label = 'Medium';
      color = AppColors.warning;
    } else {
      label = 'Low';
      color = AppColors.error;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}
