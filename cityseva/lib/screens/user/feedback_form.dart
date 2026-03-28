import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/complaint_model.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/app_theme.dart';

class FeedbackForm extends StatefulWidget {
  final Complaint complaint;
  const FeedbackForm({super.key, required this.complaint});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  int _rating = 0;
  bool? _completedOnTime;
  final _commentCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give a star rating')),
      );
      return;
    }
    if (_completedOnTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select if work was done on time')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = context.read<ComplaintProvider>();
    await provider.submitFeedback(FeedbackModel(
      id: const Uuid().v4(),
      complaintId: widget.complaint.id,
      userId: provider.currentUser?.id ?? '',
      rating: _rating,
      completedOnTime: _completedOnTime!,
      comment: _commentCtrl.text.trim(),
      createdAt: DateTime.now(),
    ));

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Complaint info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(widget.complaint.department.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.complaint.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text(widget.complaint.department.label,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Star rating
            const Text('How satisfied are you with the resolution?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      _rating >= star ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _rating >= star ? Colors.amber : Colors.grey.shade400,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _ratingLabel(_rating),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 28),

            // On time question
            const Text('Was the work completed on time?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _completedOnTime = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _completedOnTime == true ? AppColors.success.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _completedOnTime == true ? AppColors.success : AppColors.divider,
                          width: _completedOnTime == true ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: _completedOnTime == true ? AppColors.success : Colors.grey, size: 28),
                          const SizedBox(height: 4),
                          Text('Yes, On Time',
                              style: TextStyle(
                                  color: _completedOnTime == true ? AppColors.success : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _completedOnTime = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _completedOnTime == false ? AppColors.error.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _completedOnTime == false ? AppColors.error : AppColors.divider,
                          width: _completedOnTime == false ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: _completedOnTime == false ? AppColors.error : Colors.grey, size: 28),
                          const SizedBox(height: 4),
                          Text('No, Delayed',
                              style: TextStyle(
                                  color: _completedOnTime == false ? AppColors.error : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Comment
            const Text('Additional Comments (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your experience about how the government official handled this complaint...',
                hintStyle: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return '😞 Very Dissatisfied';
      case 2: return '😕 Dissatisfied';
      case 3: return '😐 Neutral';
      case 4: return '😊 Satisfied';
      case 5: return '😄 Very Satisfied';
      default: return '';
    }
  }
}
