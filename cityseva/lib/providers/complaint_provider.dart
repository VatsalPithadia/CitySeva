import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/complaint_model.dart';
import '../services/mongodb_service.dart';
import '../services/notification_service.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  List<FeedbackModel> _feedbacks = [];
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isOnline = false;

  List<Complaint> get complaints => _complaints;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  List<FeedbackModel> get feedbacks => _feedbacks;

  bool hasFeedback(String complaintId) =>
      _feedbacks.any((f) => f.complaintId == complaintId);

  List<Complaint> get myComplaints =>
      _complaints.where((c) => c.userId == _currentUser?.id).toList();

  List<Complaint> get pendingComplaints =>
      _complaints.where((c) => c.status == ComplaintStatus.submitted).toList();

  List<Complaint> get verifiedComplaints =>
      _complaints.where((c) => c.status == ComplaintStatus.verified).toList();

  ComplaintProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    // Load user from local storage first
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      _currentUser = UserModel.fromMap(jsonDecode(userJson));
    }

    // Try MongoDB first, fallback to local
    await _loadComplaints();
    await _loadFeedbacks();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadComplaints() async {
    try {
      final docs = await MongoDBService.getAllComplaints();
      if (docs.isNotEmpty) {
        _complaints = docs.map((d) => Complaint.fromMap(_sanitize(d))).toList();
        _isOnline = true;
        await _cacheComplaints();
        return;
      }
    } catch (_) {}

    // Fallback to local cache
    _isOnline = false;
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('complaints');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _complaints = list.map((e) => Complaint.fromMap(e)).toList();
    } else {
      _complaints = _getSampleComplaints();
      await _cacheComplaints();
    }
  }

  Future<void> _loadFeedbacks() async {
    try {
      final docs = await MongoDBService.getAllFeedbacks();
      if (docs.isNotEmpty) {
        _feedbacks = docs.map((d) => FeedbackModel.fromMap(_sanitize(d))).toList();
        await _cacheFeedbacks();
        return;
      }
    } catch (_) {}

    // Fallback to local cache
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('feedbacks');
    if (json != null) {
      final list = jsonDecode(json) as List;
      _feedbacks = list.map((e) => FeedbackModel.fromMap(e)).toList();
    }
  }

  // Remove MongoDB _id field which causes issues
  Map<String, dynamic> _sanitize(Map<String, dynamic> doc) {
    final map = Map<String, dynamic>.from(doc);
    map.remove('_id');
    return map;
  }

  Future<void> _cacheComplaints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'complaints', jsonEncode(_complaints.map((c) => c.toMap()).toList()));
  }

  Future<void> _cacheFeedbacks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'feedbacks', jsonEncode(_feedbacks.map((f) => f.toMap()).toList()));
  }

  Future<void> saveUser(UserModel user) async {
    _currentUser = user;
    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user', jsonEncode(user.toMap()));
    // Save to MongoDB
    try {
      await MongoDBService.saveUser(user.toMap());
    } catch (_) {}
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    await prefs.remove('auth_token');
    notifyListeners();
  }

  Future<String> submitComplaint({
    required String title,
    required String description,
    required Department department,
    required String address,
    required double latitude,
    required double longitude,
    required List<String> imagePaths,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final complaint = Complaint(
      id: id,
      userId: _currentUser?.id ?? 'guest',
      title: title,
      description: description,
      department: department,
      address: address,
      latitude: latitude,
      longitude: longitude,
      imagePaths: imagePaths,
      createdAt: now,
      updatedAt: now,
    );
    _complaints.insert(0, complaint);

    // Save to MongoDB + local cache
    try {
      await MongoDBService.insertComplaint(complaint.toMap());
    } catch (_) {}
    await _cacheComplaints();
    notifyListeners();
    return id;
  }

  Future<void> updateComplaintStatus(
    String id,
    ComplaintStatus status, {
    String? note,
    String? assignedTo,
    String? completionImagePath,
  }) async {
    final index = _complaints.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final complaint = _complaints[index];
    complaint.status = status;
    complaint.updatedAt = DateTime.now();
    if (assignedTo != null) complaint.assignedTo = assignedTo;
    if (completionImagePath != null) complaint.completionImagePath = completionImagePath;
    complaint.statusHistory.add(StatusUpdate(
      status: status,
      timestamp: DateTime.now(),
      note: note ?? status.label,
    ));

    // Save to MongoDB + local cache
    try {
      await MongoDBService.saveComplaint(complaint.toMap());
    } catch (_) {}
    await _cacheComplaints();
    NotificationService.showStatusUpdate(complaint.title, status);
    notifyListeners();
  }

  Future<void> submitFeedback(FeedbackModel feedback) async {
    _feedbacks.add(feedback);
    // Save to MongoDB + local cache
    try {
      await MongoDBService.saveFeedback(feedback.toMap());
    } catch (_) {}
    await _cacheFeedbacks();
    notifyListeners();
  }

  // Refresh data from MongoDB
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _loadComplaints();
    await _loadFeedbacks();
    _isLoading = false;
    notifyListeners();
  }

  List<Complaint> findSimilarComplaints(
      Department department, double lat, double lng) {
    return _complaints.where((c) {
      if (c.department != department) return false;
      if (c.status == ComplaintStatus.completed ||
          c.status == ComplaintStatus.rejected) return false;
      final distance =
          _calculateDistance(lat, lng, c.latitude, c.longitude);
      return distance < 0.5;
    }).toList();
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final dlat = (lat2 - lat1).abs();
    final dlng = (lng2 - lng1).abs();
    return (dlat * 111) + (dlng * 111 * 0.8);
  }

  List<Complaint> _getSampleComplaints() {
    final now = DateTime.now();
    return [
      Complaint(
        id: 'sample-1',
        userId: 'auth-user',
        title: 'Large pothole on MG Road',
        description: 'Deep pothole causing accidents near the signal',
        department: Department.roadInfrastructure,
        address: 'MG Road, Near City Mall',
        latitude: 12.9716,
        longitude: 77.5946,
        imagePaths: [],
        status: ComplaintStatus.workStarted,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        assignedTo: 'Road Dept. Team A',
        statusHistory: [
          StatusUpdate(status: ComplaintStatus.submitted, timestamp: now.subtract(const Duration(days: 3)), note: 'Complaint submitted'),
          StatusUpdate(status: ComplaintStatus.verified, timestamp: now.subtract(const Duration(days: 2)), note: 'Verified by authority'),
          StatusUpdate(status: ComplaintStatus.assigned, timestamp: now.subtract(const Duration(days: 1)), note: 'Assigned to Road Dept. Team A'),
          StatusUpdate(status: ComplaintStatus.workStarted, timestamp: now.subtract(const Duration(hours: 5)), note: 'Work in progress'),
        ],
      ),
      Complaint(
        id: 'sample-2',
        userId: 'auth-user',
        title: 'Street light not working',
        description: 'Three consecutive street lights are off since a week',
        department: Department.streetLights,
        address: 'Park Street, Block 4',
        latitude: 12.9750,
        longitude: 77.5980,
        imagePaths: [],
        status: ComplaintStatus.verified,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        statusHistory: [
          StatusUpdate(status: ComplaintStatus.submitted, timestamp: now.subtract(const Duration(days: 1)), note: 'Complaint submitted'),
          StatusUpdate(status: ComplaintStatus.verified, timestamp: now.subtract(const Duration(hours: 2)), note: 'Verified by authority'),
        ],
      ),
    ];
  }
}
