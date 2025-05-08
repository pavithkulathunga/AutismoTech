import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:autismotech_app/screens/global.dart' as globals;

const String BASE_URL = "http://10.0.2.2:8000";
// const String BASE_URL = "http://192.168.156.69:8000"; // Change this to match your backend

/// Models for detailed progress response.
class MetricProgress {
  final String category;
  final double previous;   // Initial (baseline) percentage
  final double followup;   // Follow-up percentage
  final double improvement; // Improvement (followup - previous)

  MetricProgress({
    required this.category,
    required this.previous,
    required this.followup,
    required this.improvement,
  });

  factory MetricProgress.fromJson(Map<String, dynamic> json) {
    return MetricProgress(
      category: json['category'],
      previous: (json['previous'] as num).toDouble(),
      followup: (json['followup'] as num).toDouble(),
      improvement: (json['improvement'] as num).toDouble(),
    );
  }
}

class DetailedProgressResponse {
  final int userId;
  final List<MetricProgress> metrics;

  DetailedProgressResponse({
    required this.userId,
    required this.metrics,
  });

  factory DetailedProgressResponse.fromJson(Map<String, dynamic> json) {
    var metricsList = (json['metrics'] as List)
        .map((metric) => MetricProgress.fromJson(metric))
        .toList();
    return DetailedProgressResponse(
      userId: json['user_id'],
      metrics: metricsList,
    );
  }
}

/// API service class including functions for registration, login, and more.
class ApiService {
  /// Registers a new user.
  static Future<RegisterResponse> registerUser(String email, String password) async {
    final url = Uri.parse('$BASE_URL/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return RegisterResponse.fromJson(data);
    } else {
      throw Exception('Failed to register. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  /// Logs in a user.
  static Future<LoginResponse> loginUser(String email, String password) async {
    final url = Uri.parse('$BASE_URL/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoginResponse.fromJson(data);
    } else {
      throw Exception('Failed to login. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  /// Retrieves the username of the currently logged-in user using the Global userId.
  Future<String> getUsername() async {
    if (globals.globalUserId == null) {
      throw Exception("Global userId is not set.");
    }
    
    final url = Uri.parse("$BASE_URL/auth/user/${globals.globalUserId}");
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['username'] != null) {
        return data['username'] as String;
      } else {
        throw Exception("Username is null in the API response.");
      }
    } else {
      throw Exception("Failed to load username: ${response.statusCode}");
    }
  }

  /// Uploads an image for ASD detection.
  static Future<ColoringPredictionResponse> detectAndSave({
    required File imageFile,
    required String userId,
    required int age,
    required String gender,
  }) async {
    var uri = Uri.parse('$BASE_URL/api/detect_and_save');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    request.fields['user_id'] = userId;
    request.fields['age'] = age.toString();
    request.fields['gender'] = gender;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      return ColoringPredictionResponse.fromJson(jsonData);
    } else {
      throw Exception('Failed to upload image. Status: ${response.statusCode}, Body: ${response.body}');
    }
  }

  /// Sends prediction data for ASD progress.
  static Future<PredictionResponse> sendPrediction({
    required int userId,
    required Map<String, int> initialData,
    required Map<String, int> followupData,
  }) async {
    final url = Uri.parse('$BASE_URL/api/predict');
    final requestData = {
      "user_id": userId,
      "Eye_Contact_Initial": initialData["Q1_Initial"] ?? 0,
      "Follows_Instructions_Initial": initialData["Q2_Initial"] ?? 0,
      "Verbal_Improvement_Initial": initialData["Q3_Initial"] ?? 0,
      "Repeats_Words_Initial": initialData["Q4_Initial"] ?? 0,
      "Routine_Sensitivity_Initial": initialData["Q5_Initial"] ?? 0,
      "Repetitive_Actions_Initial": initialData["Q6_Initial"] ?? 0,
      "Focus_On_Objects_Initial": initialData["Q7_Initial"] ?? 0,
      "Social_Interaction_Initial": initialData["Q8_Initial"] ?? 0,
      "Outdoor_Change_Initial": initialData["Q9_Initial"] ?? 0,
      "Therapy_Engagement_Initial": initialData["Q10_Initial"] ?? 0,
      "Eye_Contact_Followup": followupData["Q1_Followup"] ?? 0,
      "Follows_Instructions_Followup": followupData["Q2_Followup"] ?? 0,
      "Verbal_Improvement_Followup": followupData["Q3_Followup"] ?? 0,
      "Repeats_Words_Followup": followupData["Q4_Followup"] ?? 0,
      "Routine_Sensitivity_Followup": followupData["Q5_Followup"] ?? 0,
      "Repetitive_Actions_Followup": followupData["Q6_Followup"] ?? 0,
      "Focus_On_Objects_Followup": followupData["Q7_Followup"] ?? 0,
      "Social_Interaction_Followup": followupData["Q8_Followup"] ?? 0,
      "Outdoor_Change_Followup": followupData["Q9_Followup"] ?? 0,
      "Therapy_Engagement_Followup": followupData["Q10_Followup"] ?? 0,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PredictionResponse.fromJson(data);
    } else {
      throw Exception("Failed to submit responses: ${response.statusCode}, ${response.body}");
    }
  }

  /// Fetches the overall prediction for a user.
  static Future<OverallPredictionResponse> getOverallPrediction({required int userId}) async {
    final url = Uri.parse('$BASE_URL/api/average_progress/$userId');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OverallPredictionResponse.fromJson(data);
    } else {
      throw Exception("Failed to fetch overall prediction: ${response.statusCode}, ${response.body}");
    }
  }

  /// Fetches detailed progress for a user using the detailed progress endpoint.
  static Future<DetailedProgressResponse> getDetailedProgress() async {
    // Check if the global user ID is set.
    if (globals.globalUserId == null) {
      throw Exception("Global userId is not set.");
    }
    // Construct URL using the global user id.
    final url = Uri.parse('$BASE_URL/api/detailed_progress/${globals.globalUserId}');
    final response = await http.get(url, headers: {'Content-Type': 'application/json'});
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DetailedProgressResponse.fromJson(data);
    } else {
      throw Exception("Failed to fetch detailed progress: ${response.statusCode}, ${response.body}");
    }
  }
}

/// **Response Models**

class RegisterResponse {
  final int id;
  final String email;
  final String createdAt;

  RegisterResponse({required this.id, required this.email, required this.createdAt});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'],
      email: json['email'],
      createdAt: json['created_at'],
    );
  }
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;

  LoginResponse({required this.accessToken, required this.tokenType, required this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      userId: json['user_id'],
    );
  }
}

class ColoringPredictionResponse {
  final int id;
  final String userId;
  final int age;
  final String gender;
  final String predictedLabel;
  final double confidence;
  final String createdAt;

  ColoringPredictionResponse({
    required this.id,
    required this.userId,
    required this.age,
    required this.gender,
    required this.predictedLabel,
    required this.confidence,
    required this.createdAt,
  });

  factory ColoringPredictionResponse.fromJson(Map<String, dynamic> json) {
    return ColoringPredictionResponse(
      id: json['id'],
      userId: json['user_id'],
      age: json['age'],
      gender: json['gender'],
      predictedLabel: json['predicted_label'],
      confidence: (json['confidence'] as num).toDouble(),
      createdAt: json['created_at'],
    );
  }
}

class PredictionResponse {
  final int id;
  final int userId;
  final int prediction;
  final double improvementPercentage;
  final String createdAt;

  PredictionResponse({
    required this.id,
    required this.userId,
    required this.prediction,
    required this.improvementPercentage,
    required this.createdAt,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      id: json['id'],
      userId: json['user_id'],
      prediction: json['prediction'],
      improvementPercentage: (json['improvement_percentage'] as num).toDouble(),
      createdAt: json['created_at'],
    );
  }
}

class OverallPredictionResponse {
  final int userId;
  final double overallImprovementPercentage;
  final int overallPrediction;
  final int cnnProgressPercentage;

  OverallPredictionResponse({
    required this.userId,
    required this.overallImprovementPercentage,
    required this.overallPrediction,
    required this.cnnProgressPercentage,
  });

  factory OverallPredictionResponse.fromJson(Map<String, dynamic> json) {
    return OverallPredictionResponse(
      userId: json['user_id'] is String
          ? int.parse(json['user_id'])
          : (json['user_id'] as num).toInt(),
      overallImprovementPercentage: (json['average_progress'] as num).toDouble(),
      overallPrediction: (json['overall_prediction_score'] as num).toInt(),
      cnnProgressPercentage: (json['cnn_progress_percentage'] as num).toInt(),
    );
  }
}

