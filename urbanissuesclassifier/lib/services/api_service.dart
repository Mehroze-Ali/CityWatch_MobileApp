import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:urbanissuesclassifier/models/complaint_model.dart';
import 'package:urbanissuesclassifier/models/user_model.dart';

class ApiService {
  // IMPORTANT: Your computer's IP address
  static const String baseUrl = 'http://192.168.100.115:3000/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String? _userId;
  UserModel? _currentUser;
  bool _isInitialized = false;

  // Initialize and load persisted data
  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _userId = prefs.getString('user_id');

    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('Error parsing persisted user: $e');
      }
    }

    _isInitialized = true;
  }

  // Set authentication token and user ID and persist them
  Future<void> setAuth(String token, String userId, {UserModel? user}) async {
    _authToken = token;
    _userId = userId;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_id', userId);

    if (user != null) {
      await prefs.setString('current_user', jsonEncode(user.toJson()));
    }
  }

  // Clear authentication and remove from persistence
  Future<void> clearAuth() async {
    _authToken = null;
    _userId = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('current_user');
  }

  // Get current user ID
  String? get userId => _userId;
  UserModel? get currentUser => _currentUser;

  // Get headers with authentication
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // REGISTER USER
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({
          'name': username, // Backend uses 'name' not 'username'
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Backend returns: { message, user }
        // But currently it only returns userId, so we handle both cases
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'userId':
              data['userId']?.toString() ?? data['user']?['id']?.toString(),
          'user': data['user'], // May be null with current backend
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // LOGIN USER
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _getHeaders(includeAuth: false),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Create UserModel from response
        final user = UserModel.fromJson(data['user']);

        // Save token and user ID and persist
        await setAuth(data['token'], user.id, user: user);

        return {
          'success': true,
          'message': 'Login successful',
          'token': data['token'],
          'user': _currentUser,
        };
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // UPDATE PROFILE
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? phone,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final body = {'name': name};
      if (phone != null) {
        body['phone'] = phone;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/$_userId'),
        headers: _getHeaders(),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update local user data if successful
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(name: name);
          // Update persisted user data
          await setAuth(_authToken!, _userId!, user: _currentUser);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': _currentUser,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET USER DETAILS
  Future<Map<String, dynamic>> getUserDetails() async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$_userId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user'] ?? data);

        // Update local and persisted user
        await setAuth(_authToken!, _userId!, user: user);

        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch user details',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // SUBMIT COMPLAINT (with image)
  Future<Map<String, dynamic>> submitComplaint({
    required File imageFile,
    required ComplaintType type,
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    required double confidenceScore,
    required String phone,
  }) async {
    try {
      if (_userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/complaints'),
      );

      // Add headers
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Add form fields matching backend expectations
      request.fields['user_id'] = _userId!;
      request.fields['type'] = type.dbValue;
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['confidence_score'] = confidenceScore.toString();
      request.fields['phone'] = phone;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Complaint submitted successfully',
          'complaintId': data['complaintId']?.toString(),
          'imageUrl': data['imageUrl'],
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to submit complaint',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // GET USER'S COMPLAINTS
  Future<Map<String, dynamic>> getUserComplaints() async {
    try {
      if (_userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
          'complaints': <ComplaintModel>[],
        };
      }

      print('🔍 Fetching complaints for user: $_userId');
      final response = await http.get(
        Uri.parse('$baseUrl/complaints/user/$_userId'),
        headers: _getHeaders(),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final complaintsJson = data['complaints'] as List;
        final complaints = complaintsJson
            .map((json) => ComplaintModel.fromJson(json))
            .toList();

        return {'success': true, 'complaints': complaints};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch complaints',
          'complaints': <ComplaintModel>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'complaints': <ComplaintModel>[],
      };
    }
  }

  // ADMIN: GET ALL COMPLAINTS
  Future<Map<String, dynamic>> getAllComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/complaints'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Backend returns array directly, not wrapped in object
        final complaintsJson = jsonDecode(response.body) as List;
        final complaints = complaintsJson
            .map((json) => ComplaintModel.fromJson(json))
            .toList();

        return {'success': true, 'complaints': complaints};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch complaints',
          'complaints': <ComplaintModel>[],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
        'complaints': <ComplaintModel>[],
      };
    }
  }

  // ADMIN: GET SINGLE COMPLAINT BY ID
  Future<Map<String, dynamic>> getComplaintById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/complaints/$id'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Handle case where it might be wrapped or direct
        final complaintJson = data['complaint'] ?? data;
        final complaint = ComplaintModel.fromJson(complaintJson);
        return {'success': true, 'complaint': complaint};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch complaint details',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ADMIN: GET COMPLAINT CONTACT
  Future<Map<String, dynamic>> getComplaintContact(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/complaints/$id/contact'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String? phone;
        if (data['phone'] != null) {
          phone = data['phone'].toString();
        } else if (data['contact'] != null && data['contact'] is Map) {
          phone = data['contact']['phone']?.toString();
        }

        return {'success': true, 'phone': phone};
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch contact details',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ADMIN: UPDATE COMPLAINT STATUS
  Future<Map<String, dynamic>> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/complaints/status'),
        headers: _getHeaders(),
        body: jsonEncode({
          'id': complaintId, // Backend uses 'id' not 'complaint_id'
          'status': status.dbValue,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ADMIN: GET STATISTICS
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/citizen/stats'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Statistics data: $data');

        return {
          'success': true,
          'stats': {
            'byType': data['byType'] ?? {},
            'byStatus': data['byStatus'] ?? {},
          },
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
