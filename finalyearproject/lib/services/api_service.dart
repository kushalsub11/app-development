import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  // ---------- User APIs ----------
  static Future<UserModel?> getCurrentUser() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.userMe), headers: headers);
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error getting current user: $e');
    }
    return null;
  }

  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.userMe),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------- Advisor APIs ----------
  static Future<List<AdvisorModel>> getAdvisors() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.advisors));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => AdvisorModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting advisors: $e');
    }
    return [];
  }

  static Future<AdvisorModel?> getAdvisorDetail(int advisorId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.advisors}/$advisorId'));
      if (response.statusCode == 200) {
        return AdvisorModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error getting advisor: $e');
    }
    return null;
  }

  static Future<bool> updateAdvisorProfile(Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.advisorProfile),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------- Booking APIs ----------
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.bookings),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'booking': BookingModel.fromJson(body)};
      }
      return {'success': false, 'message': body['detail'] ?? 'Booking failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<BookingModel>> getMyBookings() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.myBookings), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => BookingModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting bookings: $e');
    }
    return [];
  }

  static Future<List<BookingModel>> getAdvisorBookings() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.advisorBookings), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => BookingModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting advisor bookings: $e');
    }
    return [];
  }

  static Future<bool> updateBookingStatus(int bookingId, String status) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.bookings}/$bookingId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------- Review APIs ----------
  static Future<Map<String, dynamic>> createReview(Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.reviews),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': body['detail'] ?? 'Review failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<List<ReviewModel>> getAdvisorReviews(int advisorId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.reviews}/advisor/$advisorId'));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => ReviewModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting reviews: $e');
    }
    return [];
  }

  // ---------- Report APIs ----------
  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.reports),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': body['detail'] ?? 'Report failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ---------- Payment APIs ----------
  static Future<Map<String, dynamic>> createPayment(Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.payments),
        headers: headers,
        body: jsonEncode(data),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true};
      }
      return {'success': false, 'message': body['detail'] ?? 'Payment failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ---------- Admin APIs ----------
  static Future<Map<String, dynamic>?> getAdminDashboard() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.adminDashboard), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting dashboard: $e');
    }
    return null;
  }

  static Future<List<UserModel>> getAllUsers() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.allUsers), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => UserModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting users: $e');
    }
    return [];
  }

  static Future<List<AdvisorModel>> getAllAdvisorsAdmin() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse('${ApiConfig.advisors}/all'), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => AdvisorModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting all advisors: $e');
    }
    return [];
  }

  static Future<bool> toggleUserActive(int userId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.allUsers}/$userId/toggle-active'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> verifyAdvisor(int advisorId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.advisors}/$advisorId/verify'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<ReportModel>> getAllReports() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.reports), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => ReportModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting reports: $e');
    }
    return [];
  }

  static Future<bool> updateReport(int reportId, Map<String, dynamic> data) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.reports}/$reportId'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<BookingModel>> getAllBookings() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse('${ApiConfig.bookings}/all'), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => BookingModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting all bookings: $e');
    }
    return [];
  }

  // ---------- Chat APIs ----------
  static Future<ChatRoomModel?> getOrCreateChatRoom(int bookingId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.chatRoom}/$bookingId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return ChatRoomModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error getting chat room: $e');
    }
    return null;
  }

  // ---------- Call APIs ----------
  static Future<Map<String, dynamic>?> initiateCall(int bookingId, String type) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.initiateCall),
        headers: headers,
        body: jsonEncode({
          'booking_id': bookingId,
          'call_type': type,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error initiating call: Status ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error initiating call (Network Exception): $e');
    }
    return null;
  }

  static Future<bool> endCall(int callLogId, int durationSeconds) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.endCall),
        headers: headers,
        body: jsonEncode({
          'call_log_id': callLogId,
          'duration_seconds': durationSeconds,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ---------- Khalti APIs ----------
  static Future<Map<String, dynamic>?> initiateKhaltiPayment(int bookingId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.khaltiInitiate}$bookingId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error initiating Khalti payment: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> verifyKhaltiPayment(String pidx, int bookingId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.khaltiVerify}?pidx=$pidx&booking_id=$bookingId'),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}

