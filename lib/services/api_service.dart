import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/event.dart';
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // FastAPI backend
  static const String apiVersion = '/api/v1';
  
  // Headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Auth headers
  static Map<String, String> _authHeaders(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };
  
  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/auth/register'),
        headers: _headers,
        body: json.encode(userData),
      );
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // User endpoints
  static Future<UserProfile> getCurrentUser(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/users/me'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      } else {
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<List<UserProfile>> getUsers(String token, {int skip = 0, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/users?skip=$skip&limit=$limit'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserProfile.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Event endpoints
  static Future<List<Event>> getEvents(String token, {int skip = 0, int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/events?skip=$skip&limit=$limit'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get events: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Event> createEvent(String token, Map<String, dynamic> eventData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/events'),
        headers: _authHeaders(token),
        body: json.encode(eventData),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Event.fromJson(data);
      } else {
        throw Exception('Failed to create event: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Match endpoints
  static Future<void> likeUser(String token, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/matches/like'),
        headers: _authHeaders(token),
        body: json.encode({'user_id': userId}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to like user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<void> dislikeUser(String token, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/matches/dislike'),
        headers: _authHeaders(token),
        body: json.encode({'user_id': userId}),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to dislike user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  // Chat endpoints
  static Future<List<ChatConversation>> getConversations(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/chat/conversations'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChatConversation.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<List<Message>> getMessages(String token, String conversationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$apiVersion/chat/conversations/$conversationId/messages'),
        headers: _authHeaders(token),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
  
  static Future<Message> sendMessage(String token, String conversationId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$apiVersion/chat/conversations/$conversationId/messages'),
        headers: _authHeaders(token),
        body: json.encode({'content': content}),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
