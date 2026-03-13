class ApiConfig {
  // Change this to your computer's IP address when running on a physical device
  // Use 10.0.2.2 for Android emulator (maps to localhost)
  // For your physical device, we are using the detected local network IP
  static const String baseUrl = 'http://192.168.1.7:8000';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Ensure the path starts with a slash
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String verifyRegistration = '$baseUrl/auth/verify-registration';
  static const String login = '$baseUrl/auth/login';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';

  // User endpoints
  static const String userMe = '$baseUrl/users/me';
  static const String uploadProfileImage =
      '$baseUrl/users/upload-profile-image';
  static const String allUsers = '$baseUrl/users';

  // Advisor endpoints
  static const String advisors = '$baseUrl/advisors';
  static const String advisorProfile = '$baseUrl/advisors/me/profile';
  static const String advisorStats = '$baseUrl/advisors/me/stats';

  // Booking endpoints
  static const String bookings = '$baseUrl/bookings';
  static const String myBookings = '$baseUrl/bookings/my-bookings';
  static const String advisorBookings = '$baseUrl/bookings/advisor-bookings';

  // Payment endpoints
  static const String payments = '$baseUrl/payments';
  static const String myPayments = '$baseUrl/payments/my-payments';

  // Review endpoints
  static const String reviews = '$baseUrl/reviews';

  // Report endpoints
  static const String reports = '$baseUrl/reports';
  static const String myReports = '$baseUrl/reports/my-reports';

  // Horoscope endpoints
  static const String horoscopeDaily = '$baseUrl/horoscope/daily';
  static const String dailyInsight = '$baseUrl/horoscope/summary';

  // Admin endpoints
  static const String adminDashboard = '$baseUrl/admin/dashboard';

  // Chat endpoints
  static const String wsBaseUrl = 'ws://192.168.1.7:8000';
  static const String chatRoom = '$baseUrl/chat/room/booking';
  static const String chatWs = '$wsBaseUrl/chat/ws';
  static const String chatUpload = '$baseUrl/chat/upload';

  // Call endpoints
  static const String initiateCall = '$baseUrl/call/initiate';
  static const String endCall = '$baseUrl/call/end';

  // Khalti endpoints
  static const String khaltiInitiate = '$baseUrl/payments/khalti/initiate/';
  static const String khaltiVerify = '$baseUrl/payments/khalti/verify';

  // Astro endpoints
  static const String birthChart = '$baseUrl/astro/birth-chart';

  // Payout endpoints
  static const String payoutRequests = '$baseUrl/payouts';
  static const String payoutRequestsMe = '$baseUrl/payouts/me';
  static const String adminPayoutRequests = '$baseUrl/payouts/admin/all';
  static String adminPayoutStatus(int id) => '$baseUrl/payouts/admin/$id/status';

  // Notification endpoints
  static const String notifications = '$baseUrl/notifications/me';
  static String markNotificationRead(int id) => '$baseUrl/notifications/$id/read';
  static const String notificationUnreadCount = '$baseUrl/notifications/unread-count';
}
