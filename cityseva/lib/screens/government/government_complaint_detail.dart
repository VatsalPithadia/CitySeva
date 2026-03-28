import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../services/gps_camera_service.dart';
import '../../utils/app_theme.dart';

class GovernmentComplaintDetail extends StatefulWidget {
  final Complaint complaint;

  const GovernmentComplaintDetail({super.key, required this.complaint});

  @override
  State<GovernmentComplaintDetail> createState() =>
      _GovernmentComplaintDetailState();
}

class _GovernmentComplaintDetailState
    extends State<GovernmentComplaintDetail> {
  final _noteCtrl = TextEditingController();
  final _assignCtrl = TextEditingController();
  File? _completionImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _assignCtrl.dispose();
    super.dispose();
  }

  // Use GPS Camera for completion photo — stamps location + time
  Future<void> _pickCompletionImage() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Completion Photo',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gps_fixed, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS Camera stamps location & time on the photo as proof of completion',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.gps_fixed, color: AppColors.primary),
              title: const Text('GPS Camera (Recommended)'),
              subtitle: const Text('Stamps location & time on photo'),
              onTap: () => Navigator.pop(context, 'gps'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    if (source == 'gps') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening GPS Camera...')),
      );
      final result = await GpsCameraService.takeGeoTaggedPhoto();
      if (result.success) {
        setState(() => _completionImage = result.file);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS photo captured with location stamp'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (!result.cancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Camera error')),
        );
      }
    } else {
      // Gallery fallback
      final picked = await showDialog<File?>(
        context: context,
        builder: (_) => const SizedBox.shrink(),
      );
      // Use image picker for gallery
      final picker = await _pickFromGallery();
      if (picker != null) setState(() => _completionImage = picker);
    }
  }

  Future<File?> _pickFromGallery() async {
    try {
      final picker = await GpsCameraService.takeGeoTaggedPhoto();
      return null; // Will use image_picker directly
    } catch (_) {
      return null;
    }
  }

  Future<void> _assignToDepartment() async {
    if (_assignCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter department/team name')));
      return;
    }
    setState(() => _isLoading = true);
    await context.read<ComplaintProvider>().updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.assigned,
          note: 'Assigned to ${_assignCtrl.text.trim()}',
          assignedTo: _assignCtrl.text.trim(),
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Assigned to ${_assignCtrl.text.trim()}'),
          backgroundColor: AppColors.success),
    );
    setState(() {});
  }

  Future<void> _startWork() async {
    setState(() => _isLoading = true);
    await context.read<ComplaintProvider>().updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.workStarted,
          note: 'Work has been started by the department',
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Work started!'),
          backgroundColor: AppColors.success),
    );
    setState(() {});
  }

  Future<void> _markComplete() async {
    if (_completionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please upload a GPS completion photo to verify work')));
      return;
    }
    setState(() => _isLoading = true);
    await context.read<ComplaintProvider>().updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.completed,
          note: _noteCtrl.text.trim().isNotEmpty
              ? _noteCtrl.text.trim()
              : 'Work completed successfully',
          completionImagePath: _completionImage!.path,
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Complaint marked as completed!'),
          backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for live updates
    final provider = context.watch<ComplaintProvider>();
    final c = provider.complaints.firstWhere(
      (x) => x.id == widget.complaint.id,
      orElse: () => widget.complaint,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Work Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(c),
          const SizedBox(height: 16),
          _buildDetails(c),
          const SizedBox(height: 16),
          _buildTimeline(c),
          if (c.imagePaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSubmittedImages(c),
          ],
          const SizedBox(height: 16),
          _buildWorkPanel(c),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(Complaint c) {
    final color = _statusColor(c.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.8), color]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(c.department.icon,
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text(c.department.label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13)),
                if (c.assignedTo != null)
                  Text('Team: ${c.assignedTo}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20)),
            child: Text(c.status.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
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
            const Text('Issue Details',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.place_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(c.address,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                    DateFormat('dd MMM yyyy, hh:mm a')
                        .format(c.createdAt),
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('ID: ${c.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Complaint c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Status Timeline',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
            const Divider(height: 20),
            ...c.statusHistory.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(h.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.status.label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                            Text(h.note,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(
                                DateFormat('dd MMM, hh:mm a')
                                    .format(h.timestamp),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedImages(Complaint c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Complaint Photos',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
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
                    image: DecorationImage(
                        image: FileImage(File(c.imagePaths[i])),
                        fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkPanel(Complaint c) {
    // Already completed
    if (c.status == ComplaintStatus.completed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 56),
              const SizedBox(height: 12),
              const Text('Work Completed!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.success)),
              if (c.completionImagePath != null) ...[
                const SizedBox(height: 16),
                const Text('Completion Photo (GPS Verified)',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(c.completionImagePath!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Work Actions',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary)),
            const Divider(height: 20),

            // Step 1: Assign (if verified)
            if (c.status == ComplaintStatus.verified) ...[
              _stepLabel('Step 1', 'Assign to Department', AppColors.warning),
              const SizedBox(height: 12),
              TextFormField(
                controller: _assignCtrl,
                decoration: const InputDecoration(
                  labelText: 'Department / Team Name *',
                  hintText: 'e.g. Road Dept. Team A',
                  prefixIcon: Icon(Icons.engineering_outlined),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _assignToDepartment,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.assignment_ind),
                label: const Text('Assign to Department',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            // Step 2: Start Work (if assigned)
            if (c.status == ComplaintStatus.assigned) ...[
              _stepLabel('Step 2', 'Start Field Work', Colors.orange),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.engineering_outlined,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          'Assigned to: ${c.assignedTo ?? 'Department'}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _startWork,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.construction),
                label: const Text('Start Work',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],

            // Step 3: Complete Work (if workStarted)
            if (c.status == ComplaintStatus.workStarted) ...[
              _stepLabel(
                  'Step 3', 'Mark Work as Completed', AppColors.success),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Completion Note',
                  hintText: 'Describe the work done...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // GPS Completion Photo
              GestureDetector(
                onTap: _pickCompletionImage,
                child: Container(
                  height: _completionImage != null ? 200 : 130,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _completionImage != null
                          ? AppColors.success
                          : AppColors.primary.withValues(alpha: 0.3),
                      width: _completionImage != null ? 2 : 1,
                    ),
                  ),
                  child: _completionImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_completionImage!,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _completionImage = null),
                                child: Container(
                                  decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.gps_fixed,
                                        color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text('GPS Verified',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gps_fixed,
                                size: 36,
                                color: AppColors.primary
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 8),
                            const Text('Upload GPS Completion Photo *',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text(
                                'Photo will be stamped with location & time',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _markComplete,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle),
                label: const Text('Mark as Completed',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepLabel(String step, String title, Color color) {
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(step,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
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
