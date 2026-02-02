class ApiConfig {
  // Change this to your computer's IP address when running on a physical device
  // Use 10.0.2.2 for Android emulator (maps to localhost)
  static const String baseUrl = 'http://192.168.1.13:60156';

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String verifyRegistration = '$baseUrl/auth/verify-registration';
  static const String login = '$baseUrl/auth/login';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';

  // User endpoints
  static const String userMe = '$baseUrl/users/me';
  static const String uploadProfileImage = '$baseUrl/users/upload-profile-image';
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
  static const String wsBaseUrl = 'ws://192.168.1.13:60156';
  static const String chatRoom = '$baseUrl/chat/room/booking';
  static const String chatWs = '$wsBaseUrl/chat/ws';
  
  // Call endpoints
  static const String initiateCall = '$baseUrl/call/initiate';
  static const String endCall = '$baseUrl/call/end';

  // Khalti endpoints
  static const String khaltiInitiate = '$baseUrl/payments/khalti/initiate/';
  static const String khaltiVerify = '$baseUrl/payments/khalti/verify';

  // Astro endpoints
  static const String birthChart = '$baseUrl/astro/birth-chart';
}

