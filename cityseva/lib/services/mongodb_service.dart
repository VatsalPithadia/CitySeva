import 'dart:convert';
import 'package:http/http.dart' as http;

class MongoDBService {
  static const _baseUrl = 'https://cityseva-backend.onrender.com/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Users ────────────────────────────────────────────────────────────────────

  static Future<bool> saveUser(Map<String, dynamic> user) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/users'),
            headers: _headers,
            body: jsonEncode(user),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Complaints ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllComplaints() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/complaints'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => _sanitize(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> insertComplaint(Map<String, dynamic> complaint) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/complaints'),
            headers: _headers,
            body: jsonEncode(complaint),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveComplaint(Map<String, dynamic> complaint) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_baseUrl/complaints/${complaint['id']}'),
            headers: _headers,
            body: jsonEncode(complaint),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Feedbacks ────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllFeedbacks() async {
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/feedbacks'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => _sanitize(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> saveFeedback(Map<String, dynamic> feedback) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/feedbacks'),
            headers: _headers,
            body: jsonEncode(feedback),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Remove MongoDB _id field
  static Map<String, dynamic> _sanitize(Map<String, dynamic> doc) {
    final map = Map<String, dynamic>.from(doc);
    map.remove('_id');
    map.remove('__v');
    map.remove('createdAt');
    map.remove('updatedAt');
    return map;
  }
}
