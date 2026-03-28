import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../services/ai_service.dart';
import '../../utils/app_theme.dart';

class AuthorityComplaintDetail extends StatefulWidget {
  final Complaint complaint;

  const AuthorityComplaintDetail({super.key, required this.complaint});

  @override
  State<AuthorityComplaintDetail> createState() => _AuthorityComplaintDetailState();
}

class _AuthorityComplaintDetailState extends State<AuthorityComplaintDetail> {
  final _noteCtrl = TextEditingController();
  final _assignCtrl = TextEditingController();
  AIAnalysisResult? _aiResult;
  bool _aiLoading = false;
  bool _aiRan = false;

  @override
  void initState() {
    super.initState();
    if (widget.complaint.status == ComplaintStatus.submitted) {
      _runAIAnalysis();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _assignCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAIAnalysis() async {
    setState(() => _aiLoading = true);
    final provider = context.read<ComplaintProvider>();
    final result = await AIService.analyzeComplaint(
      widget.complaint,
      provider.complaints,
    );
    if (mounted) {
      setState(() {
        _aiResult = result;
        _aiLoading = false;
        _aiRan = true;
        // Auto-fill note with AI suggestion
        if (_noteCtrl.text.isEmpty) {
          _noteCtrl.text = result.summary;
        }
      });
    }
  }

  void _updateStatus(ComplaintStatus status) {
    if (status == ComplaintStatus.assigned && _assignCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter assignee name')));
      return;
    }
    context.read<ComplaintProvider>().updateComplaintStatus(
          widget.complaint.id,
          status,
          note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : status.label,
          assignedTo: status == ComplaintStatus.assigned ? _assignCtrl.text.trim() : null,
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to ${status.label}'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    return Scaffold(
      appBar: AppBar(title: const Text('Review Complaint')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(c),
          const SizedBox(height: 16),
          _buildDetails(c),
          if (c.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImages(c),
          ],
          if (c.status == ComplaintStatus.submitted) ...[
            const SizedBox(height: 16),
            _buildAIPanel(),
          ],
          const SizedBox(height: 16),
          _buildActionPanel(c),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(Complaint c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(c.department.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text(c.department.label,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 4),
                Text('ID: ${c.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
              ],
            ),
          ),
          _statusBadge(c.status),
        ],
      ),
    );
  }

  Widget _buildDetails(Complaint c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaint Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const Divider(height: 20),
            _row('Description', c.description),
            const SizedBox(height: 12),
            _row('Location', c.address),
            const SizedBox(height: 12),
            _row('GPS', '${c.latitude.toStringAsFixed(5)}, ${c.longitude.toStringAsFixed(5)}'),
            const SizedBox(height: 12),
            _row('User ID', c.userId.substring(0, 8).toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildImages(Complaint c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Submitted Photos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: c.imagePaths.length,
                itemBuilder: (_, i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: FileImage(File(c.imagePaths[i])), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPanel() {
    if (_aiLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🤖 AI Analysis Running...',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Analyzing complaint validity, keywords & patterns',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_aiResult == null) {
      return GestureDetector(
        onTap: _runAIAnalysis,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Text('🤖', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Run AI Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                    Text('Tap to analyze complaint validity with AI', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.play_circle_outline, color: Color(0xFF7B1FA2)),
            ],
          ),
        ),
      );
    }

    final r = _aiResult!;
    final verdictColor = r.verdict == 'Valid'
        ? AppColors.success
        : r.verdict == 'Suspicious'
            ? AppColors.warning
            : AppColors.error;

    final verdictEmoji = r.verdict == 'Valid' ? '✅' : r.verdict == 'Suspicious' ? '⚠️' : '❌';
    final priorityColor = r.priorityLevel == 'High'
        ? AppColors.error
        : r.priorityLevel == 'Medium'
            ? AppColors.warning
            : AppColors.success;

    return Column(
      children: [
        // AI Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('AI Validity Analysis',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              GestureDetector(
                onTap: _runAIAnalysis,
                child: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),

        // Score + Verdict
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: verdictColor.withValues(alpha: 0.06),
            border: Border.all(color: verdictColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              // Score circle
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: r.validityScore / 100,
                      strokeWidth: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(verdictColor),
                    ),
                    Text('${r.validityScore}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: verdictColor)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('$verdictEmoji ${r.verdict}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: verdictColor)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                          ),
                          child: Text('${r.priorityLevel} Priority',
                              style: TextStyle(fontSize: 10, color: priorityColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r.summary,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Signals & Red Flags
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              if (r.positiveSignals.isNotEmpty) ...[
                _signalSection('✅ Positive Signals', r.positiveSignals, AppColors.success),
                const SizedBox(height: 12),
              ],
              if (r.redFlags.isNotEmpty)
                _signalSection('🚩 Red Flags', r.redFlags, AppColors.error),
            ],
          ),
        ),

        // Duplicate warning
        if (r.isDuplicate)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.copy_outlined, color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('⚠️ Duplicate Alert: ${r.duplicateNote}',
                      style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

        // AI Suggested Action
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C).withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFF7B1FA2), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Recommendation',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    Text(r.suggestedAction,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4A148C), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // Quick apply button
              TextButton(
                onPressed: () {
                  if (r.suggestedAction == 'Verify & Forward') {
                    _updateStatus(ComplaintStatus.verified);
                  } else if (r.suggestedAction == 'Reject') {
                    _updateStatus(ComplaintStatus.rejected);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Apply', style: TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _signalSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        ...items.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildActionPanel(Complaint c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Take Action',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const Divider(height: 20),
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note / Remarks',
                hintText: 'Add a note...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 2,
            ),
            if (c.status == ComplaintStatus.verified) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _assignCtrl,
                decoration: const InputDecoration(
                  labelText: 'Assign To *',
                  hintText: 'e.g. Road Dept. Team A',
                  prefixIcon: Icon(Icons.engineering_outlined),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _buildActionButtons(c),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Complaint c) {
    switch (c.status) {
      case ComplaintStatus.submitted:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus(ComplaintStatus.rejected),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus(ComplaintStatus.verified),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Verify & Forward'),
              ),
            ),
          ],
        );
      case ComplaintStatus.verified:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(ComplaintStatus.assigned),
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Assign to Department'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.success),
              const SizedBox(width: 8),
              Text('Current status: ${c.status.label}',
                  style: const TextStyle(color: AppColors.success)),
            ],
          ),
        );
    }
  }

  Widget _statusBadge(ComplaintStatus s) {
    final color = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(s.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
