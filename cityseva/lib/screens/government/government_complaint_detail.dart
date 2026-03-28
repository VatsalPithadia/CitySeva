import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';

class GovernmentComplaintDetail extends StatefulWidget {
  final Complaint complaint;

  const GovernmentComplaintDetail({super.key, required this.complaint});

  @override
  State<GovernmentComplaintDetail> createState() => _GovernmentComplaintDetailState();
}

class _GovernmentComplaintDetailState extends State<GovernmentComplaintDetail> {
  final _noteCtrl = TextEditingController();
  File? _completionImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCompletionImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload Completion Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _completionImage = File(picked.path));
  }

  Future<void> _markComplete() async {
    if (_completionImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a completion photo')));
      return;
    }
    setState(() => _isLoading = true);
    await context.read<ComplaintProvider>().updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.completed,
          note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : 'Work completed successfully',
          completionImagePath: _completionImage!.path,
        );
    setState(() => _isLoading = false);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complaint marked as completed!'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _startWork() async {
    await context.read<ComplaintProvider>().updateComplaintStatus(
          widget.complaint.id,
          ComplaintStatus.workStarted,
          note: 'Work has been started by the department',
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Work started!'), backgroundColor: AppColors.success),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    return Scaffold(
      appBar: AppBar(title: const Text('Work Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(c),
          const SizedBox(height: 16),
          _buildDetails(c),
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
        gradient: LinearGradient(colors: [color.withOpacity(0.8), color]),
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
                Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(c.department.label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                if (c.assignedTo != null)
                  Text('Team: ${c.assignedTo}', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)),
            child: Text(c.status.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
            const Text('Issue Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const Divider(height: 20),
            Text(c.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(c.address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ],
            ),
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
            const Text('Issue Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
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

  Widget _buildWorkPanel(Complaint c) {
    if (c.status == ComplaintStatus.completed) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              const SizedBox(height: 8),
              const Text('Work Completed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.success)),
              if (c.completionImagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(c.completionImagePath!), height: 180, width: double.infinity, fit: BoxFit.cover),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Work Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const Divider(height: 20),
            if (c.status == ComplaintStatus.assigned) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startWork,
                  icon: const Icon(Icons.construction),
                  label: const Text('Start Work'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
            if (c.status == ComplaintStatus.workStarted) ...[
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
              GestureDetector(
                onTap: _pickCompletionImage,
                child: Container(
                  height: _completionImage != null ? 180 : 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid),
                  ),
                  child: _completionImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_completionImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _completionImage = null),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.primary.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            const Text('Upload Completion Photo *', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                            const Text('Required to mark as complete', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _markComplete,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle),
                  label: const Text('Mark as Completed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
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
