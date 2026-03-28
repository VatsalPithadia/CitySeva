import 'dart:convert';
import 'package:http/http.dart' as http;

class MongoDBService {
  // ─── Replace these with your MongoDB Atlas values ───────────────────────────
  static const _appId = 'YOUR_APP_ID';         // e.g. cityseva-abcde
  static const _apiKey = 'YOUR_DATA_API_KEY';  // from Atlas App Services
  static const _cluster = 'Cluster0';          // your cluster name
  static const _database = 'cityseva';
  // ────────────────────────────────────────────────────────────────────────────

  static const _baseUrl =
      'https://data.mongodb-api.com/app/$_appId/endpoint/data/v1/action';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'api-key': _apiKey,
      };

  // ── Generic helpers ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> findAll(String collection,
      {Map<String, dynamic>? filter}) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/find'),
          headers: _headers,
          body: jsonEncode({
            'dataSource': _cluster,
            'database': _database,
            'collection': collection,
            'filter': filter ?? {},
            'sort': {'createdAt': -1},
            'limit': 1000,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data['documents'] ?? []);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> findOne(
      String collection, Map<String, dynamic> filter) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/findOne'),
          headers: _headers,
          body: jsonEncode({
            'dataSource': _cluster,
            'database': _database,
            'collection': collection,
            'filter': filter,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['document'];
    }
    return null;
  }

  static Future<bool> insertOne(
      String collection, Map<String, dynamic> document) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/insertOne'),
          headers: _headers,
          body: jsonEncode({
            'dataSource': _cluster,
            'database': _database,
            'collection': collection,
            'document': document,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode == 201 || res.statusCode == 200;
  }

  static Future<bool> updateOne(String collection,
      Map<String, dynamic> filter, Map<String, dynamic> update) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/updateOne'),
          headers: _headers,
          body: jsonEncode({
            'dataSource': _cluster,
            'database': _database,
            'collection': collection,
            'filter': filter,
            'update': {'\$set': update},
            'upsert': true,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode == 200;
  }

  static Future<bool> deleteOne(
      String collection, Map<String, dynamic> filter) async {
    final res = await http
        .post(
          Uri.parse('$_baseUrl/deleteOne'),
          headers: _headers,
          body: jsonEncode({
            'dataSource': _cluster,
            'database': _database,
            'collection': collection,
            'filter': filter,
          }),
        )
        .timeout(const Duration(seconds: 10));
    return res.statusCode == 200;
  }

  // ── Collection-specific methods ──────────────────────────────────────────────

  // Users
  static Future<Map<String, dynamic>?> getUser(String email) =>
      findOne('users', {'email': email});

  static Future<bool> saveUser(Map<String, dynamic> user) =>
      updateOne('users', {'id': user['id']}, user);

  // Complaints
  static Future<List<Map<String, dynamic>>> getAllComplaints() =>
      findAll('complaints');

  static Future<List<Map<String, dynamic>>> getUserComplaints(
          String userId) =>
      findAll('complaints', filter: {'userId': userId});

  static Future<bool> saveComplaint(Map<String, dynamic> complaint) =>
      updateOne('complaints', {'id': complaint['id']}, complaint);

  static Future<bool> insertComplaint(Map<String, dynamic> complaint) =>
      insertOne('complaints', complaint);

  // Feedbacks
  static Future<List<Map<String, dynamic>>> getAllFeedbacks() =>
      findAll('feedbacks');

  static Future<bool> saveFeedback(Map<String, dynamic> feedback) =>
      insertOne('feedbacks', feedback);
}
