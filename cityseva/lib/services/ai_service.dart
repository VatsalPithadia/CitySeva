import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';

class AIAnalysisResult {
  final bool isValid;
  final int validityScore; // 0-100
  final String verdict; // 'Valid', 'Suspicious', 'Invalid'
  final String summary;
  final List<String> positiveSignals;
  final List<String> redFlags;
  final String suggestedAction;
  final String department;
  final String priorityLevel; // 'High', 'Medium', 'Low'
  final bool isDuplicate;
  final String duplicateNote;

  AIAnalysisResult({
    required this.isValid,
    required this.validityScore,
    required this.verdict,
    required this.summary,
    required this.positiveSignals,
    required this.redFlags,
    required this.suggestedAction,
    required this.department,
    required this.priorityLevel,
    required this.isDuplicate,
    required this.duplicateNote,
  });
}

class AIService {
  // Google Gemini free API - get your key at https://aistudio.google.com/app/apikey
  static const _apiKey = 'AIzaSyDSlBXIiHPA5TG2skffzXAtkXKUPnqgegI';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<AIAnalysisResult> analyzeComplaint(
    Complaint complaint,
    List<Complaint> existingComplaints,
  ) async {
    // Check for duplicates locally first
    final duplicates = existingComplaints.where((c) {
      if (c.id == complaint.id) return false;
      if (c.department != complaint.department) return false;
      if (c.status == ComplaintStatus.rejected) return false;
      final dist = _distance(complaint.latitude, complaint.longitude, c.latitude, c.longitude);
      return dist < 0.5;
    }).toList();

    final duplicateNote = duplicates.isNotEmpty
        ? '${duplicates.length} similar complaint(s) found nearby (ID: ${duplicates.first.id.substring(0, 8).toUpperCase()})'
        : 'No duplicates found';

    // Build prompt for Gemini
    final prompt = '''
You are an AI assistant for CitySeva, a civic complaint management system in India.
Analyze the following citizen complaint and return a JSON response.

COMPLAINT DETAILS:
- Title: "${complaint.title}"
- Description: "${complaint.description}"
- Department: "${complaint.department.label}"
- Location: "${complaint.address}"
- Has Photos: ${complaint.imagePaths.isNotEmpty ? 'Yes (${complaint.imagePaths.length} photo(s))' : 'No'}
- User ID: "${complaint.userId.substring(0, 8).toUpperCase()}"
- Submitted At: "${complaint.createdAt.toIso8601String()}"

ANALYSIS CRITERIA:
1. Check if title and description are meaningful and related to civic issues (not random words, gibberish, or spam)
2. Check if the complaint matches the selected department
3. Check if the description has enough detail to act upon
4. Check if the location seems valid for India
5. Assess urgency and priority

Return ONLY a valid JSON object with this exact structure:
{
  "isValid": true/false,
  "validityScore": 0-100,
  "verdict": "Valid" or "Suspicious" or "Invalid",
  "summary": "2-3 sentence analysis summary",
  "positiveSignals": ["signal1", "signal2"],
  "redFlags": ["flag1", "flag2"],
  "suggestedAction": "Verify & Forward" or "Needs More Info" or "Reject",
  "priorityLevel": "High" or "Medium" or "Low",
  "priorityReason": "reason for priority"
}
''';

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Extract JSON from response
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}') + 1;
        if (jsonStart != -1 && jsonEnd > jsonStart) {
          final jsonStr = text.substring(jsonStart, jsonEnd);
          final result = jsonDecode(jsonStr);

          return AIAnalysisResult(
            isValid: result['isValid'] ?? false,
            validityScore: result['validityScore'] ?? 50,
            verdict: result['verdict'] ?? 'Suspicious',
            summary: result['summary'] ?? 'Analysis completed.',
            positiveSignals: List<String>.from(result['positiveSignals'] ?? []),
            redFlags: List<String>.from(result['redFlags'] ?? []),
            suggestedAction: result['suggestedAction'] ?? 'Needs More Info',
            department: complaint.department.label,
            priorityLevel: result['priorityLevel'] ?? 'Medium',
            isDuplicate: duplicates.isNotEmpty,
            duplicateNote: duplicateNote,
          );
        }
      }
    } catch (_) {}

    // Fallback: local rule-based analysis if API fails
    return _localAnalysis(complaint, duplicates.isNotEmpty, duplicateNote);
  }

  // Local rule-based fallback when API is unavailable
  static AIAnalysisResult _localAnalysis(
    Complaint complaint,
    bool isDuplicate,
    String duplicateNote,
  ) {
    final title = complaint.title.toLowerCase();
    final desc = complaint.description.toLowerCase();
    final combined = '$title $desc';

    // Civic keywords by department
    final keywords = {
      Department.waterSupply: ['water', 'pipe', 'leak', 'supply', 'tap', 'drainage', 'sewage', 'flood', 'overflow', 'contamination'],
      Department.roadInfrastructure: ['road', 'pothole', 'crack', 'bridge', 'footpath', 'pavement', 'divider', 'signal', 'traffic', 'construction'],
      Department.streetLights: ['light', 'lamp', 'dark', 'street', 'bulb', 'electric', 'wire', 'pole', 'broken', 'night'],
      Department.sanitation: ['garbage', 'waste', 'trash', 'dirty', 'clean', 'dustbin', 'smell', 'hygiene', 'litter', 'dump'],
      Department.parks: ['park', 'garden', 'tree', 'grass', 'bench', 'playground', 'plant', 'maintenance', 'green', 'fence'],
      Department.electricity: ['electricity', 'power', 'current', 'wire', 'transformer', 'outage', 'voltage', 'meter', 'shock', 'cable'],
      Department.other: ['issue', 'problem', 'complaint', 'repair', 'fix', 'broken', 'damage', 'request'],
    };

    final deptKeywords = keywords[complaint.department] ?? keywords[Department.other]!;
    final matchCount = deptKeywords.where((k) => combined.contains(k)).length;

    // Scoring
    int score = 40;
    final positiveSignals = <String>[];
    final redFlags = <String>[];

    // Title length check
    if (complaint.title.length >= 10) {
      score += 10;
      positiveSignals.add('Title is descriptive and meaningful');
    } else {
      redFlags.add('Title is too short or vague');
    }

    // Description length check
    if (complaint.description.length >= 30) {
      score += 15;
      positiveSignals.add('Description has sufficient detail');
    } else {
      score -= 10;
      redFlags.add('Description lacks detail');
    }

    // Keyword match
    if (matchCount >= 2) {
      score += 20;
      positiveSignals.add('Content matches ${complaint.department.label} department keywords');
    } else if (matchCount == 1) {
      score += 10;
      positiveSignals.add('Partial keyword match with department');
    } else {
      score -= 15;
      redFlags.add('Content does not match selected department');
    }

    // Photo check
    if (complaint.imagePaths.isNotEmpty) {
      score += 10;
      positiveSignals.add('Photo evidence provided');
    } else {
      redFlags.add('No photo evidence submitted');
    }

    // Location check
    if (complaint.address.length > 10) {
      score += 5;
      positiveSignals.add('Location address is specified');
    }

    // Duplicate check
    if (isDuplicate) {
      score -= 10;
      redFlags.add('Similar complaint already exists nearby');
    }

    score = score.clamp(0, 100);

    String verdict;
    String suggestedAction;
    String priorityLevel;

    if (score >= 70) {
      verdict = 'Valid';
      suggestedAction = 'Verify & Forward';
      priorityLevel = matchCount >= 3 ? 'High' : 'Medium';
    } else if (score >= 45) {
      verdict = 'Suspicious';
      suggestedAction = 'Needs More Info';
      priorityLevel = 'Low';
    } else {
      verdict = 'Invalid';
      suggestedAction = 'Reject';
      priorityLevel = 'Low';
    }

    return AIAnalysisResult(
      isValid: score >= 70,
      validityScore: score,
      verdict: verdict,
      summary: 'Local AI analysis completed. ${positiveSignals.length} positive signals and ${redFlags.length} red flags detected.',
      positiveSignals: positiveSignals,
      redFlags: redFlags,
      suggestedAction: suggestedAction,
      department: complaint.department.label,
      priorityLevel: priorityLevel,
      isDuplicate: isDuplicate,
      duplicateNote: duplicateNote,
    );
  }

  static double _distance(double lat1, double lng1, double lat2, double lng2) {
    final dlat = (lat2 - lat1).abs();
    final dlng = (lng2 - lng1).abs();
    return (dlat * 111) + (dlng * 111 * 0.8);
  }
}
