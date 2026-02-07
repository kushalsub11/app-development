import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';
import 'booking_screen.dart';

class PhysicalBookingBrowserScreen extends StatefulWidget {
  const PhysicalBookingBrowserScreen({super.key});

  @override
  State<PhysicalBookingBrowserScreen> createState() => _PhysicalBookingBrowserScreenState();
}

class _PhysicalBookingBrowserScreenState extends State<PhysicalBookingBrowserScreen> {
  bool _isLoading = true;
  List<AdvisorModel> _advisors = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPhysicalAdvisors();
  }

  Future<void> _fetchPhysicalAdvisors([String? query]) async {
    setState(() => _isLoading = true);
    final results = await ApiService.getAdvisors(isPhysical: true, location: query);
    if (mounted) {
      setState(() {
        _advisors = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _startPreBookingChat(AdvisorModel advisor) async {
    try {
      // First, get or create the pre-booking ChatRoom from the backend
      final roomData = await ApiService.getOrCreatePreBookingRoom(advisor.userId);
      
      if (!mounted) return;
      
      // We create a dummy booking object specifically for the ChatScreen to consume,
      // because ChatScreen expects a Booking object to know who the advisor is.
      // We pass 0 as the ID to signify it's a pre-booking chat.
      final mockBooking = BookingModel(
        id: 0,
        userId: 0, // ChatScreen ignores this
        advisorId: advisor.id,
        bookingDate: DateTime.now().toString(),
        startTime: '00:00',
        endTime: '23:59',
        status: 'pending',
        consultationType: 'physical',
        amount: advisor.hourlyRate,
        advisorName: advisor.user?.fullName,
        advisorImage: advisor.user?.profileImage,
      );

      final currentUser = await AuthService.getSavedUser();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            booking: mockBooking,
            roomId: roomData['id'], // Pass the exact room ID generated
            otherUserName: advisor.user?.fullName ?? 'Advisor',
            currentUserId: currentUser?.id ?? 0,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start chat: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Physical Bookings'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by city, area, or location...',
                prefixIcon: const Icon(Icons.location_on, color: AppTheme.primaryPurple),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppTheme.primaryPurple),
                  onPressed: () => _fetchPhysicalAdvisors(_searchController.text),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) => _fetchPhysicalAdvisors(value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _advisors.isEmpty
                    ? const Center(
                        child: Text(
                          'No advisors offering physical booking found in this area.',
                          style: TextStyle(color: AppTheme.greyText),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _advisors.length,
                        itemBuilder: (context, index) {
                          final advisor = _advisors[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundImage: advisor.user?.profileImage != null
                                            ? NetworkImage(ApiConfig.getImageUrl(advisor.user!.profileImage!))
                                            : null,
                                        child: advisor.user?.profileImage == null
                                            ? const Icon(Icons.person, size: 30)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              advisor.user?.fullName ?? 'Advisor',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              advisor.specialization ?? 'General Astrology',
                                              style: const TextStyle(color: AppTheme.primaryPurple),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: AppTheme.greyText),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          advisor.officeAddress ?? advisor.location ?? 'Location not specified',
                                          style: const TextStyle(color: AppTheme.greyText),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.chat),
                                          label: const Text('Chat First'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.primaryPurple,
                                            side: const BorderSide(color: AppTheme.primaryPurple),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => _startPreBookingChat(advisor),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.calendar_month),
                                          label: const Text('Book Visit'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.gold,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BookingScreen(advisor: advisor),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
