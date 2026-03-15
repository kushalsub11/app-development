import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../main.dart';
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
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
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
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await AuthService.saveUser(userData);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
        headers: headers,
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      }
      return {'success': false, 'message': body['detail'] ?? 'Update failed'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error'};
    }
  }

  static Future<UserModel?> uploadProfileImage(String filePath) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadProfileImage));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await AuthService.saveUser(userData);
        return UserModel.fromJson(userData);
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    }
    return null;
  }

  // ---------- Advisor APIs ----------
  static Future<List<AdvisorModel>> getAdvisors({
    String? location,
    String? specialization,
    String? religion,
    bool? isPhysical,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (location != null && location.isNotEmpty) queryParams['location'] = location;
      if (specialization != null && specialization.isNotEmpty && specialization != 'All') {
        queryParams['specialization'] = specialization;
      }
      if (religion != null && religion.isNotEmpty) queryParams['religion'] = religion;
      if (isPhysical != null) queryParams['is_physical'] = isPhysical.toString();

      final uri = Uri.parse(ApiConfig.advisors).replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => AdvisorModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting advisors: $e');
    }
    return [];
  }

  static Future<List<int>> getFavorites() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me/favorites'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ids = data['favorite_advisor_ids'] ?? [];
        return ids.cast<int>();
      }
    } catch (e) {
      print('Error getting favorites: $e');
    }
    return [];
  }

  static Future<bool> toggleFavorite(int advisorId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/me/favorites/$advisorId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling favorite: $e');
    }
    return false;
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

  static Future<AdvisorModel?> uploadAdvisorCertificate(String filePath) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.advisors}/me/upload-certificate'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        return AdvisorModel.fromJson(jsonDecode(response.body));
      }
      print('Certificate upload failed: ${response.body}');
    } catch (e) {
      print('Error uploading certificate: $e');
    }
    return null;
  }

  static Future<String?> uploadChatImage(String filePath) async {
    try {
      final token = await AuthService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.chatUpload));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
    } catch (e) {
      print('Error uploading chat image: $e');
    }
    return null;
  }

  static Future<AdvisorModel?> getMyAdvisorProfile() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.advisors}/me/profile'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return AdvisorModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error getting advisor profile: $e');
    }
    return null;
  }

  static Future<bool> blockAdvisor(int advisorId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/admin/advisors/$advisorId/block'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAdvisorStats() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.advisorStats), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      }
    } catch (e) {
      print('Error getting advisor stats: $e');
    }
    return null;
  }

  // ---------- Booking APIs ----------
  static Future<List<Map<String, dynamic>>> getOccupiedSlots(int advisorId, String date) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/bookings/occupied/$advisorId?date=$date'));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (e) {
      print('Error getting occupied slots: $e');
    }
    return [];
  }

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
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
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
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
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

  static Future<bool> acceptBooking(int bookingId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.bookings}/$bookingId/accept'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> declineBooking(int bookingId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.bookings}/$bookingId/decline'),
        headers: headers,
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

  static Future<List<ReviewModel>> getMyReviewsForAdvisor() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse('${ApiConfig.advisors}/me/reviews'), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => ReviewModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting my reviews: $e');
    }
    return [];
  }

  static Future<bool> replyToReview(int reviewId, String reply) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.advisors}/me/reviews/$reviewId/reply'),
        headers: headers,
        body: jsonEncode({'reply': reply}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error replying to review: $e');
      return false;
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

  static Future<List<ReportModel>> getMyReports() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.myReports), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => ReportModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting my reports: $e');
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
      
      String errorMessage = 'Report failed';
      if (body['detail'] is String) {
        errorMessage = body['detail'];
      } else if (body['detail'] is List) {
        // Handle Pydantic validation errors
        errorMessage = (body['detail'] as List).map((e) => e['msg']).join(', ');
      }
      
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // ---------- Payment APIs ----------
  static Future<List<PaymentModel>> getMyPayments() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.myPayments), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => PaymentModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting payments: $e');
    }
    return [];
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

  static Future<ChatRoomModel?> getAdminChatHistory(int roomId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.adminChatAudit(roomId)), headers: headers);
      if (response.statusCode == 200) {
        return ChatRoomModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Error getting admin chat audit: $e');
    }
    return null;
  }

  static Future<bool> sendAdminIntervention(int roomId, String content) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.adminChatIntervene(roomId)),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error sending admin intervention: $e');
      return false;
    }
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
      print('Error getting admin advisors: $e');
    }
    return [];
  }

  static Future<List<PaymentModel>> getAllPaymentsAdmin() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.payments), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => PaymentModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting admin payments: $e');
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

  static Future<bool> refundBookingPayment(int bookingId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/bookings/$bookingId/refund'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error refunding payment: $e');
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

  static Future<List<ChatRoomModel>> getInquiryChats() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.chatInquiries), headers: headers);
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => ChatRoomModel.fromJson(e)).toList();
      }
    } catch (e) {
      print('Error getting inquiry chats: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> getOrCreatePreBookingRoom(int advisorId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        // Assuming ApiConfig has been updated with preBookingRoom url or building it directly
        Uri.parse('${ApiConfig.baseUrl}/chat/room/pre-booking/$advisorId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to load pre-booking room: ${response.body}');
    } catch (e) {
      print('Error getting pre-booking room: $e');
      rethrow;
    }
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

  // ---------- Misc APIs ----------
  static Future<Map<String, String>> getDailyCalendar() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.dailyInsight));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'nepali_date': data['nepali_date']?.toString() ?? 'Date unavailable',
          'tithi': data['tithi']?.toString() ?? '',
          'panchang': data['panchang']?.toString() ?? '',
          'english_date': data['english_date']?.toString() ?? 'Loading...',
        };
      }
    } catch (e) {
      print('Error fetching daily calendar: $e');
    }
    return {
      'nepali_date': 'Date unavailable',
      'tithi': '',
      'panchang': '',
      'english_date': '',
    };
  }

  static Future<List<dynamic>> getDailyHoroscopes() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.horoscopeDaily));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawHoroscopes = data['horoscopes'] ?? [];
        
        // Map keys to match frontend expectations
        return rawHoroscopes.map((h) => {
          'sign': _getNepaliSignName(h['name']), // Map English name to Nepali
          'content': h['text']
        }).toList();
      }
    } catch (e) {
      print('Error fetching daily horoscopes: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> generateBirthChart({
    required String dob,
    required String tob,
    required double lat,
    required double lon,
    double timezone = 5.75,
  }) async {
    try {
      final query = 'dob=$dob&tob=$tob&lat=$lat&lon=$lon&tz=$timezone';
      final response = await http.get(Uri.parse('${ApiConfig.birthChart}?$query'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error generating birth chart: $e');
    }
    return {'success': false, 'error': 'Could not generate chart'};
  }

  static String _getNepaliSignName(String englishName) {
    final Map<String, String> mapping = {
      'Mesh': 'मेष', 'Brush': 'वृष', 'Mithun': 'मिथुन', 'Karkat': 'कर्कट',
      'Singha': 'सिंह', 'Kanya': 'कन्या', 'Tula': 'तुला', 'Brischik': 'वृश्चिक',
      'Dhanu': 'धनु', 'Makar': 'मकर', 'Kumbha': 'कुम्भ', 'Meen': 'मीन'
    };
    return mapping[englishName] ?? englishName;
  }

  // ---------- Payout Requests ----------
  static Future<bool> createPayoutRequest(double amount, String paymentDetails) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.payoutRequests),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'payment_details': paymentDetails,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating payout request: $e');
      return false;
    }
  }

  static Future<List<PayoutRequestModel>> getMyPayoutRequests() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.payoutRequestsMe), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PayoutRequestModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting my payout requests: $e');
    }
    return [];
  }

  static Future<List<PayoutRequestModel>> getAllPayoutRequestsAdmin() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.adminPayoutRequests), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PayoutRequestModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting all payout requests: $e');
    }
    return [];
  }

  static Future<bool> updatePayoutStatus(int id, String status, {String? notes}) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.adminPayoutStatus(id)),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'admin_notes': notes,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating payout status: $e');
      return false;
    }
  }

  // ---------- Notifications ----------
  static Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.notifications), headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error getting notifications: $e');
    }
    return [];
  }

  static Future<bool> markNotificationAsRead(int id) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.put(Uri.parse(ApiConfig.markNotificationRead(id)), headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<int> getUnreadNotificationCount() async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse(ApiConfig.notificationUnreadCount), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      } else if (response.statusCode == 401) {
        _handleUnauthorized();
      }
    } catch (e) {
      print('Error getting unread count: $e');
    }
    return 0;
  }


  // ---------- Authorization Recovery ----------
  static void _handleUnauthorized() {
    AuthService.logout();
    
    // Use the global navigator key to force a redirect to the login screen
    if (MyApp.navigatorKey.currentState != null) {
      MyApp.navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  }
}


