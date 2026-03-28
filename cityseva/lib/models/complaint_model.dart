enum ComplaintStatus { submitted, verified, assigned, workStarted, completed, rejected }

enum Department { waterSupply, roadInfrastructure, streetLights, sanitation, parks, electricity, other }

extension DepartmentExt on Department {
  String get label {
    switch (this) {
      case Department.waterSupply: return 'Water Supply';
      case Department.roadInfrastructure: return 'Road & Infrastructure';
      case Department.streetLights: return 'Street Lights';
      case Department.sanitation: return 'Sanitation';
      case Department.parks: return 'Parks & Recreation';
      case Department.electricity: return 'Electricity';
      case Department.other: return 'Other';
    }
  }
  String get icon {
    switch (this) {
      case Department.waterSupply: return '💧';
      case Department.roadInfrastructure: return '🛣️';
      case Department.streetLights: return '💡';
      case Department.sanitation: return '🗑️';
      case Department.parks: return '🌳';
      case Department.electricity: return '⚡';
      case Department.other: return '📋';
    }
  }
}

extension ComplaintStatusExt on ComplaintStatus {
  String get label {
    switch (this) {
      case ComplaintStatus.submitted: return 'Submitted';
      case ComplaintStatus.verified: return 'Verified';
      case ComplaintStatus.assigned: return 'Assigned';
      case ComplaintStatus.workStarted: return 'Work Started';
      case ComplaintStatus.completed: return 'Completed';
      case ComplaintStatus.rejected: return 'Rejected';
    }
  }
  int get step {
    switch (this) {
      case ComplaintStatus.submitted: return 0;
      case ComplaintStatus.verified: return 1;
      case ComplaintStatus.assigned: return 2;
      case ComplaintStatus.workStarted: return 3;
      case ComplaintStatus.completed: return 4;
      case ComplaintStatus.rejected: return -1;
    }
  }
}

class Complaint {
  final String id;
  final String userId;
  final String title;
  final String description;
  final Department department;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> imagePaths;
  ComplaintStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  String? assignedTo;
  String? authorityNote;
  String? completionImagePath;
  List<StatusUpdate> statusHistory;

  Complaint({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.department,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
    this.status = ComplaintStatus.submitted,
    required this.createdAt,
    required this.updatedAt,
    this.assignedTo,
    this.authorityNote,
    this.completionImagePath,
    List<StatusUpdate>? statusHistory,
  }) : statusHistory = statusHistory ??
            [StatusUpdate(status: ComplaintStatus.submitted, timestamp: createdAt, note: 'Complaint submitted successfully')];

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        'department': department.index,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'imagePaths': imagePaths,
        'status': status.index,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'assignedTo': assignedTo,
        'authorityNote': authorityNote,
        'completionImagePath': completionImagePath,
        'statusHistory': statusHistory.map((s) => s.toMap()).toList(),
      };

  factory Complaint.fromMap(Map<String, dynamic> map) => Complaint(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        description: map['description'],
        department: Department.values[map['department']],
        address: map['address'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        imagePaths: List<String>.from(map['imagePaths']),
        status: ComplaintStatus.values[map['status']],
        createdAt: DateTime.parse(map['createdAt']),
        updatedAt: DateTime.parse(map['updatedAt']),
        assignedTo: map['assignedTo'],
        authorityNote: map['authorityNote'],
        completionImagePath: map['completionImagePath'],
        statusHistory: (map['statusHistory'] as List).map((s) => StatusUpdate.fromMap(s)).toList(),
      );
}

class StatusUpdate {
  final ComplaintStatus status;
  final DateTime timestamp;
  final String note;

  StatusUpdate({required this.status, required this.timestamp, required this.note});

  Map<String, dynamic> toMap() => {
        'status': status.index,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory StatusUpdate.fromMap(Map<String, dynamic> map) => StatusUpdate(
        status: ComplaintStatus.values[map['status']],
        timestamp: DateTime.parse(map['timestamp']),
        note: map['note'],
      );
}

class FeedbackModel {
  final String id;
  final String complaintId;
  final String userId;
  final int rating;
  final bool completedOnTime;
  final String comment;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.rating,
    required this.completedOnTime,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'complaintId': complaintId,
        'userId': userId,
        'rating': rating,
        'completedOnTime': completedOnTime,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory FeedbackModel.fromMap(Map<String, dynamic> map) => FeedbackModel(
        id: map['id'],
        complaintId: map['complaintId'],
        userId: map['userId'],
        rating: map['rating'],
        completedOnTime: map['completedOnTime'],
        comment: map['comment'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatarPath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatarPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatarPath': avatarPath,
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        phone: map['phone'],
        role: map['role'],
        avatarPath: map['avatarPath'],
      );
}
