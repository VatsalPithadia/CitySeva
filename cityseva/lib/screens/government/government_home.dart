import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import 'government_complaint_detail.dart';
import 'performance_analytics.dart';

class GovernmentHome extends StatefulWidget {
  const GovernmentHome({super.key});

  @override
  State<GovernmentHome> createState() => _GovernmentHomeState();
}

class _GovernmentHomeState extends State<GovernmentHome> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Government Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Performance Analytics',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformanceAnalytics())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<ComplaintProvider>().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Assigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          final assigned = provider.complaints.where((c) => c.status == ComplaintStatus.assigned).toList();
          final inProgress = provider.complaints.where((c) => c.status == ComplaintStatus.workStarted).toList();
          final completed = provider.complaints.where((c) => c.status == ComplaintStatus.completed).toList();

          return Column(
            children: [
              _buildStatsBar(provider.complaints),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(assigned, 'No assigned complaints'),
                    _buildList(inProgress, 'No work in progress'),
                    _buildList(completed, 'No completed complaints'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(List<Complaint> all) {
    final stats = {
      'Total': all.length,
      'Assigned': all.where((c) => c.status == ComplaintStatus.assigned).length,
      'In Progress': all.where((c) => c.status == ComplaintStatus.workStarted).length,
      'Done': all.where((c) => c.status == ComplaintStatus.completed).length,
    };
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.entries.map((e) => Column(
          children: [
            Text(e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(e.key, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _buildList(List<Complaint> complaints, String emptyMsg) {
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (_, i) => _GovComplaintCard(complaint: complaints[i]),
    );
  }
}

class _GovComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const _GovComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(complaint.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GovernmentComplaintDetail(complaint: complaint))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(complaint.department.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(complaint.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                    child: Text(complaint.status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (complaint.assignedTo != null)
                Row(
                  children: [
                    const Icon(Icons.engineering_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Assigned to: ${complaint.assignedTo}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(complaint.address,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              if (complaint.status == ComplaintStatus.assigned) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.read<ComplaintProvider>().updateComplaintStatus(
                            complaint.id,
                            ComplaintStatus.workStarted,
                            note: 'Work has been started',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Work started!'), backgroundColor: AppColors.success),
                      );
                    },
                    icon: const Icon(Icons.construction, size: 16),
                    label: const Text('Start Work', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.submitted: return AppColors.primary;
      case ComplaintStatus.verified: return AppColors.accent;
      case ComplaintStatus.assigned: return AppColors.warning;
      case ComplaintStatus.workStarted: return Colors.orange;
      case ComplaintStatus.completed: return AppColors.success;
      case ComplaintStatus.rejected: return AppColors.error;
    }
  }
}
