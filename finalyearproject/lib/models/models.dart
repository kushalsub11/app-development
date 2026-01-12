class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? profileImage;
  final String role;
  final bool isActive;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.profileImage,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      profileImage: json['profile_image'],
      role: json['role'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'profile_image': profileImage,
      'role': role,
      'is_active': isActive,
    };
  }
}


class AdvisorModel {
  final int id;
  final int userId;
  final String? bio;
  final String? specialization;
  final int experienceYears;
  final double hourlyRate;
  final double rating;
  final int totalReviews;
  final bool isVerified;
  final UserModel? user;

  AdvisorModel({
    required this.id,
    required this.userId,
    this.bio,
    this.specialization,
    required this.experienceYears,
    required this.hourlyRate,
    required this.rating,
    required this.totalReviews,
    required this.isVerified,
    this.user,
  });

  factory AdvisorModel.fromJson(Map<String, dynamic> json) {
    return AdvisorModel(
      id: json['id'],
      userId: json['user_id'],
      bio: json['bio'],
      specialization: json['specialization'],
      experienceYears: json['experience_years'] ?? 0,
      hourlyRate: (json['hourly_rate'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}


class BookingModel {
  final int id;
  final int userId;
  final int advisorId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final String consultationType;
  final double amount;
  final String? createdAt;

  BookingModel({
    required this.id,
    required this.userId,
    required this.advisorId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.consultationType,
    required this.amount,
    this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      userId: json['user_id'],
      advisorId: json['advisor_id'],
      bookingDate: json['booking_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'pending',
      consultationType: json['consultation_type'] ?? 'chat',
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: json['created_at'],
    );
  }
}


class ReviewModel {
  final int id;
  final int bookingId;
  final int userId;
  final int advisorId;
  final int rating;
  final String? comment;
  final String? createdAt;
  final UserModel? user;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.advisorId,
    required this.rating,
    this.comment,
    this.createdAt,
    this.user,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      advisorId: json['advisor_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['created_at'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }
}


class ReportModel {
  final int id;
  final int reporterId;
  final int reportedAdvisorId;
  final String reason;
  final String? description;
  final String status;
  final String? adminNotes;
  final String? createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedAdvisorId,
    required this.reason,
    this.description,
    required this.status,
    this.adminNotes,
    this.createdAt,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      reporterId: json['reporter_id'],
      reportedAdvisorId: json['reported_advisor_id'],
      reason: json['reason'],
      description: json['description'],
      status: json['status'],
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'],
    );
  }
}


class PaymentModel {
  final int id;
  final int bookingId;
  final int userId;
  final double amount;
  final String? transactionId;
  final String status;
  final String paymentMethod;
  final String? paidAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.transactionId,
    required this.status,
    required this.paymentMethod,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      transactionId: json['transaction_id'],
      status: json['status'],
      paymentMethod: json['payment_method'] ?? 'khalti',
      paidAt: json['paid_at'],
    );
  }
}
