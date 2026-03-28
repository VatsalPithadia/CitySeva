import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import '../auth/login_screen.dart';
import 'authority_complaint_detail.dart';

class AuthorityHome extends StatefulWidget {
  const AuthorityHome({super.key});

  @override
  State<AuthorityHome> createState() => _AuthorityHomeState();
}

class _AuthorityHomeState extends State<AuthorityHome> with SingleTickerProviderStateMixin {
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
        title: const Text('Authority Dashboard'),
        actions: [
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
            Tab(text: 'Pending'),
            Tab(text: 'Verified'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          final pending = provider.complaints.where((c) => c.status == ComplaintStatus.submitted).toList();
          final verified = provider.complaints.where((c) => c.status == ComplaintStatus.verified).toList();
          final all = provider.complaints;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, 'No pending complaints'),
              _buildList(verified, 'No verified complaints'),
              _buildList(all, 'No complaints'),
            ],
          );
        },
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
      itemBuilder: (_, i) => _AuthorityComplaintCard(complaint: complaints[i]),
    );
  }
}

class _AuthorityComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const _AuthorityComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(complaint.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthorityComplaintDetail(complaint: complaint))),
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
              Text(complaint.description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
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
              if (complaint.status == ComplaintStatus.submitted) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _quickAction(context, complaint, ComplaintStatus.rejected),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _quickAction(context, complaint, ComplaintStatus.verified),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Verify', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _quickAction(BuildContext context, Complaint complaint, ComplaintStatus status) {
    context.read<ComplaintProvider>().updateComplaintStatus(
          complaint.id,
          status,
          note: status == ComplaintStatus.verified ? 'Verified by authority' : 'Rejected by authority',
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Complaint ${status.label}'),
        backgroundColor: status == ComplaintStatus.verified ? AppColors.success : AppColors.error,
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
