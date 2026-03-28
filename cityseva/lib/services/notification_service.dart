import 'package:flutter/material.dart';
import '../models/complaint_model.dart';

class NotificationService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void showStatusUpdate(String complaintTitle, ComplaintStatus status) {
    final title = _title(status);
    final color = _color(status);

    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(_icon(status), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(complaintTitle,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  static String _title(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.verified:
        return 'Complaint Verified';
      case ComplaintStatus.assigned:
        return 'Work Assigned';
      case ComplaintStatus.workStarted:
        return 'Work Started';
      case ComplaintStatus.completed:
        return 'Issue Resolved!';
      case ComplaintStatus.rejected:
        return 'Complaint Rejected';
      default:
        return 'Status Updated';
    }
  }

  static String _icon(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.verified: return '✅';
      case ComplaintStatus.assigned: return '👷';
      case ComplaintStatus.workStarted: return '🔧';
      case ComplaintStatus.completed: return '🎉';
      case ComplaintStatus.rejected: return '❌';
      default: return '📋';
    }
  }

  static Color _color(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.verified: return const Color(0xFF1565C0);
      case ComplaintStatus.assigned: return const Color(0xFFFB8C00);
      case ComplaintStatus.workStarted: return const Color(0xFFE65100);
      case ComplaintStatus.completed: return const Color(0xFF2E7D32);
      case ComplaintStatus.rejected: return const Color(0xFFE53935);
      default: return const Color(0xFF546E7A);
    }
  }
}
