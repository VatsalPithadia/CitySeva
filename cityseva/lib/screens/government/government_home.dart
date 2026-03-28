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

class _GovernmentHomeState extends State<GovernmentHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PerformanceAnalytics())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<ComplaintProvider>().refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<ComplaintProvider>().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Verified'),
            Tab(text: 'Assigned'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          // Verified = ready for government to assign
          final verified = provider.complaints
              .where((c) => c.status == ComplaintStatus.verified)
              .toList();
          final assigned = provider.complaints
              .where((c) => c.status == ComplaintStatus.assigned)
              .toList();
          final inProgress = provider.complaints
              .where((c) => c.status == ComplaintStatus.workStarted)
              .toList();
          final completed = provider.complaints
              .where((c) => c.status == ComplaintStatus.completed)
              .toList();

          return Column(
            children: [
              _buildStatsBar(provider.complaints),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(verified, 'No verified complaints pending',
                        showAssignButton: true),
                    _buildList(assigned, 'No assigned complaints',
                        showStartButton: true),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('Verified',
              all.where((c) => c.status == ComplaintStatus.verified).length,
              AppColors.accent),
          _statItem('Assigned',
              all.where((c) => c.status == ComplaintStatus.assigned).length,
              AppColors.warning),
          _statItem('In Progress',
              all.where((c) => c.status == ComplaintStatus.workStarted).length,
              Colors.orange),
          _statItem('Completed',
              all.where((c) => c.status == ComplaintStatus.completed).length,
              AppColors.success),
        ],
      ),
    );
  }

  Widget _statItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(count.toString(),
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildList(List<Complaint> complaints, String emptyMsg,
      {bool showAssignButton = false, bool showStartButton = false}) {
    if (complaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(emptyMsg,
                style: const TextStyle(color: AppColors.textSecondary)),
            if (showAssignButton) ...[
              const SizedBox(height: 8),
              const Text('Verified complaints from authority will appear here',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ComplaintProvider>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: complaints.length,
        itemBuilder: (_, i) => _GovComplaintCard(
          complaint: complaints[i],
          showAssignButton: showAssignButton,
          showStartButton: showStartButton,
        ),
      ),
    );
  }
}

class _GovComplaintCard extends StatefulWidget {
  final Complaint complaint;
  final bool showAssignButton;
  final bool showStartButton;

  const _GovComplaintCard({
    required this.complaint,
    this.showAssignButton = false,
    this.showStartButton = false,
  });

  @override
  State<_GovComplaintCard> createState() => _GovComplaintCardState();
}

class _GovComplaintCardState extends State<_GovComplaintCard> {
  final _assignCtrl = TextEditingController();

  @override
  void dispose() {
    _assignCtrl.dispose();
    super.dispose();
  }

  void _showAssignDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Assign to Department'),
        content: TextField(
          controller: _assignCtrl,
          decoration: const InputDecoration(
            labelText: 'Team / Department Name',
            hintText: 'e.g. Road Dept. Team A',
            prefixIcon: Icon(Icons.engineering_outlined),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_assignCtrl.text.trim().isEmpty) return;
              context.read<ComplaintProvider>().updateComplaintStatus(
                    widget.complaint.id,
                    ComplaintStatus.assigned,
                    note: 'Assigned to ${_assignCtrl.text.trim()}',
                    assignedTo: _assignCtrl.text.trim(),
                  );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Assigned to ${_assignCtrl.text.trim()}'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final color = _statusColor(c.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    GovernmentComplaintDetail(complaint: c))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(c.department.icon,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(c.department.label,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(c.status.label,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(c.address,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              if (c.assignedTo != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.engineering_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Team: ${c.assignedTo}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
              // Action buttons
              if (widget.showAssignButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAssignDialog,
                    icon: const Icon(Icons.assignment_ind, size: 16),
                    label: const Text('Assign to Department',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
              if (widget.showStartButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<ComplaintProvider>()
                          .updateComplaintStatus(
                            c.id,
                            ComplaintStatus.workStarted,
                            note: 'Work has been started by the department',
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Work started!'),
                            backgroundColor: AppColors.success),
                      );
                    },
                    icon: const Icon(Icons.construction, size: 16),
                    label: const Text('Start Work',
                        style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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
      case ComplaintStatus.submitted:
        return AppColors.primary;
      case ComplaintStatus.verified:
        return AppColors.accent;
      case ComplaintStatus.assigned:
        return AppColors.warning;
      case ComplaintStatus.workStarted:
        return Colors.orange;
      case ComplaintStatus.completed:
        return AppColors.success;
      case ComplaintStatus.rejected:
        return AppColors.error;
    }
  }
}
