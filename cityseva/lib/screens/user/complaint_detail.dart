import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';
import 'feedback_form.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComplaintProvider>();
    final alreadyFeedback = provider.hasFeedback(complaint.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildTimeline(),
          if (complaint.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImagesCard(context),
          ],
          if (complaint.completionImagePath != null) ...[
            const SizedBox(height: 16),
            _buildCompletionCard(context),
          ],
          if (complaint.status == ComplaintStatus.completed) ...[
            const SizedBox(height: 16),
            alreadyFeedback
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        SizedBox(width: 10),
                        Text('Feedback submitted. Thank you!',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FeedbackForm(complaint: complaint)),
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Give Feedback', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final color = _statusColor(complaint.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
                child: Text(complaint.status.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const Spacer(),
              Text(complaint.department.icon, style: const TextStyle(fontSize: 28)),
            ],
          ),
          const SizedBox(height: 12),
          Text(complaint.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(complaint.department.label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          const SizedBox(height: 8),
          Text('ID: ${complaint.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const Divider(height: 20),
            _infoRow(Icons.description_outlined, 'Description', complaint.description),
            const SizedBox(height: 12),
            _infoRow(Icons.place_outlined, 'Location', complaint.address),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today_outlined, 'Submitted',
                DateFormat('dd MMM yyyy, hh:mm a').format(complaint.createdAt)),
            if (complaint.assignedTo != null) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.engineering_outlined, 'Assigned To', complaint.assignedTo!),
            ],
            if (complaint.authorityNote != null) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.note_outlined, 'Authority Note', complaint.authorityNote!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    final steps = [
      ComplaintStatus.submitted,
      ComplaintStatus.verified,
      ComplaintStatus.assigned,
      ComplaintStatus.workStarted,
      ComplaintStatus.completed,
    ];

    if (complaint.status == ComplaintStatus.rejected) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.cancel, color: AppColors.error),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Complaint Rejected', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                      if (complaint.authorityNote != null)
                        Text(complaint.authorityNote!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const Divider(height: 20),
            ...steps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final currentStep = complaint.status.step;
              final isDone = currentStep >= i;
              final isCurrent = currentStep == i;
              final isLast = i == steps.length - 1;

              final historyEntry = complaint.statusHistory.where((h) => h.status == step).firstOrNull;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDone ? _statusColor(step) : Colors.grey.shade200,
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: _statusColor(step), width: 3) : null,
                        ),
                        child: Icon(
                          isDone ? Icons.check : _stepIcon(step),
                          color: isDone ? Colors.white : Colors.grey,
                          size: 16,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: isDone && currentStep > i ? _statusColor(step) : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.label,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isDone ? AppColors.textPrimary : Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          if (historyEntry != null) ...[
                            const SizedBox(height: 2),
                            Text(historyEntry.note, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(historyEntry.timestamp),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submitted Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: complaint.imagePaths.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _showFullImage(context, complaint.imagePaths[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: FileImage(File(complaint.imagePaths[i])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: AppColors.success),
                SizedBox(width: 8),
                Text('Work Completion Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showFullImage(context, complaint.completionImagePath!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(complaint.completionImagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
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

  IconData _stepIcon(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.submitted: return Icons.upload_file;
      case ComplaintStatus.verified: return Icons.verified_outlined;
      case ComplaintStatus.assigned: return Icons.assignment_ind_outlined;
      case ComplaintStatus.workStarted: return Icons.construction_outlined;
      case ComplaintStatus.completed: return Icons.check_circle_outline;
      default: return Icons.circle_outlined;
    }
  }
}
