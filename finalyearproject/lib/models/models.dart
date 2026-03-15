class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? profileImage;
  final String role;
  final bool isActive;
  final String? createdAt;
  // Birth details
  final String? dob;
  final String? tob;
  final String? pob;
  final double? lat;
  final double? lon;
  final String? birthChartSvg;
  final dynamic planetDetails;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.profileImage,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.dob,
    this.tob,
    this.pob,
    this.lat,
    this.lon,
    this.birthChartSvg,
    this.planetDetails,
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
      dob: json['dob'],
      tob: json['tob'],
      pob: json['pob'],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lon: json['lon'] != null ? (json['lon'] as num).toDouble() : null,
      birthChartSvg: json['birth_chart_svg'],
      planetDetails: json['planet_details'],
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
      'dob': dob,
      'tob': tob,
      'pob': pob,
      'lat': lat,
      'lon': lon,
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
  // Extended profile fields
  final String? location;
  final String? birthday;
  final String? contactNumber;
  final String? certificatePdf;
  final bool isBlocked;
  final String verificationStatus;
  final String? officeAddress;
  final bool isPhysicalAvailable;
  final bool isVirtualAvailable;
  final bool isOnline;
  final String? religion;
  final dynamic availableSlots;
  bool isFavorite;

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
    this.location,
    this.birthday,
    this.contactNumber,
    this.certificatePdf,
    this.isBlocked = false,
    this.verificationStatus = 'pending',
    this.officeAddress,
    this.isPhysicalAvailable = false,
    this.isVirtualAvailable = true,
    this.isOnline = true,
    this.religion,
    this.availableSlots,
    this.isFavorite = false,
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
      location: json['location'],
      birthday: json['birthday'],
      contactNumber: json['contact_number'],
      certificatePdf: json['certificate_pdf'],
      isBlocked: json['is_blocked'] ?? false,
      verificationStatus: json['verification_status'] ?? 'pending',
      religion: json['religion'],
      isPhysicalAvailable: json['is_physical_available'] ?? false,
      isVirtualAvailable: json['is_virtual_available'] ?? true,
      isOnline: json['is_online'] ?? true,
      officeAddress: json['office_address'],
      availableSlots: json['available_slots'],
      isFavorite: json['isFavorite'] ?? false,
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
  final String? meetingLocation;
  final String? createdAt;
  final String? advisorName;
  final String? advisorImage;
  final String? userName;
  final String? userImage;
  final String? acceptedAt;

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
    this.meetingLocation,
    this.createdAt,
    this.advisorName,
    this.advisorImage,
    this.userName,
    this.userImage,
    this.acceptedAt,
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
      meetingLocation: json['meeting_location'],
      createdAt: json['created_at'],
      advisorName: json['advisor_name'],
      advisorImage: json['advisor_image'],
      userName: json['user_name'],
      userImage: json['user_image'],
      acceptedAt: json['accepted_at'],
    );
  }

  /// Returns the scheduled DateTime combining bookingDate + startTime.
  /// Used to enforce the chat/call time lock.
  DateTime? get scheduledDateTime {
    try {
      final datePart = bookingDate.split('T').first.trim();
      final timeParts = startTime.split(':');
      if (timeParts.length < 2) return null;
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final dateParsed = DateTime.parse(datePart);
      return DateTime(dateParsed.year, dateParsed.month, dateParsed.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  DateTime? get endDateTime {
    try {
      final datePart = bookingDate.split('T').first.trim();
      final timeParts = endTime.split(':');
      if (timeParts.length < 2) return null;
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final dateParsed = DateTime.parse(datePart);
      return DateTime(dateParsed.year, dateParsed.month, dateParsed.day, hour, minute);
    } catch (_) {
      return null;
    }
  }
}




class ReviewModel {
  final int id;
  final int bookingId;
  final int userId;
  final int advisorId;
  final int rating;
  final String? comment;
  final String? advisorReply;
  final String? repliedAt;
  final String? createdAt;
  final UserModel? user;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.advisorId,
    required this.rating,
    this.comment,
    this.advisorReply,
    this.repliedAt,
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
      advisorReply: json['advisor_reply'],
      repliedAt: json['replied_at'],
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
  final String? reporterName;
  final String? reportedAdvisorName;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedAdvisorId,
    required this.reason,
    this.description,
    required this.status,
    this.adminNotes,
    this.createdAt,
    this.reporterName,
    this.reportedAdvisorName,
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
      reporterName: json['reporter_name'],
      reportedAdvisorName: json['reported_advisor_name'],
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

class ChatMessageModel {
  final int id;
  final int roomId;
  final int senderId;
  final String messageType;
  final String content;
  final String timestamp;
  final bool isRead;

  ChatMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    this.messageType = 'text',
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      messageType: json['message_type'] ?? 'text',
      content: json['content'],
      timestamp: json['timestamp'],
      isRead: json['is_read'] ?? false,
    );
  }
}

class ChatRoomModel {
  final int id;
  final int? bookingId;
  final int userId;
  final int advisorId;
  final bool isActive;
  final String createdAt;
  final List<ChatMessageModel> messages;
  final String? userName;
  final String? userImage;
  final String? advisorName;
  final String? advisorImage;

  ChatRoomModel({
    required this.id,
    this.bookingId,
    required this.userId,
    required this.advisorId,
    required this.isActive,
    required this.createdAt,
    required this.messages,
    this.userName,
    this.userImage,
    this.advisorName,
    this.advisorImage,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      advisorId: json['advisor_id'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      messages: json['messages'] != null 
          ? (json['messages'] as List).map((i) => ChatMessageModel.fromJson(i)).toList() 
          : [],
      userName: json['user_name'],
      userImage: json['user_image'],
      advisorName: json['advisor_name'],
      advisorImage: json['advisor_image'],
    );
  }
}

class PayoutRequestModel {
  final int id;
  final int advisorId;
  final double amount;
  final String paymentDetails;
  final String status;
  final String? adminNotes;
  final String createdAt;
  final String updatedAt;
  final AdvisorModel? advisor;

  PayoutRequestModel({
    required this.id,
    required this.advisorId,
    required this.amount,
    required this.paymentDetails,
    required this.status,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.advisor,
  });

  factory PayoutRequestModel.fromJson(Map<String, dynamic> json) {
    return PayoutRequestModel(
      id: json['id'],
      advisorId: json['advisor_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      paymentDetails: json['payment_details'] ?? '',
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      advisor: json['advisor'] != null ? AdvisorModel.fromJson(json['advisor']) : null,
    );
  }
}

class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
    );
  }
}


