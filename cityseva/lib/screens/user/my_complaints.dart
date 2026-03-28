import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import 'complaint_detail.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  ComplaintStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        actions: [
          PopupMenuButton<ComplaintStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filterStatus = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...ComplaintStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.label))),
            ],
          ),
        ],
      ),
      body: Consumer<ComplaintProvider>(
        builder: (context, provider, _) {
          var complaints = provider.myComplaints;
          if (_filterStatus != null) {
            complaints = complaints.where((c) => c.status == _filterStatus).toList();
          }

          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus != null ? 'No ${_filterStatus!.label} complaints' : 'No complaints yet',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('Submit a complaint from the Home tab', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (_, i) => _ComplaintCard(complaint: complaints[i]),
          );
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;

  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(complaint.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaint: complaint))),
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd MMM yyyy').format(complaint.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const Spacer(),
                  _buildProgressIndicator(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (complaint.status == ComplaintStatus.rejected) {
      return const Text('Rejected', style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.bold));
    }
    const total = 5;
    final current = complaint.status.step + 1;
    return Row(
      children: List.generate(total, (i) => Container(
        margin: const EdgeInsets.only(left: 3),
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: i < current ? _statusColor(complaint.status) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      )),
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
