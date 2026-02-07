import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.advisor});
  final AdvisorModel advisor;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);
  String _consultationType = 'chat';
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _displaySlots = [];
  Map<String, dynamic>? _selectedSlot;

  double _calculateAmount() {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    final durationMins = endMins - startMins;
    
    if (durationMins <= 0) return widget.advisor.hourlyRate;
    
    final durationHours = durationMins / 60.0;
    final billingHours = durationHours < 1.0 ? 1.0 : durationHours;
    return billingHours * widget.advisor.hourlyRate;
  }

  String _getDurationText() {
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    final durationMins = endMins - startMins;
    
    if (durationMins <= 0) return 'Invalid range';
    
    if (durationMins < 60) return '$durationMins mins (Min 1 hr billing)';
    
    final hours = durationMins ~/ 60;
    final mins = durationMins % 60;
    if (mins == 0) return '$hours hr${hours > 1 ? 's' : ''}';
    return '$hours hr${hours > 1 ? 's' : ''} $mins mins';
  }


  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateDisplaySlots();
      });
    }
  }

  void _updateDisplaySlots() {
    final dayName = _getDayName(_selectedDate);
    final slots = widget.advisor.availableSlots;
    if (slots != null && slots is Map && slots.containsKey(dayName)) {
      setState(() {
        _displaySlots = List<Map<String, dynamic>>.from(slots[dayName]);
        _selectedSlot = null; // Reset selection
      });
    } else {
      setState(() {
        _displaySlots = [];
        _selectedSlot = null;
      });
    }
  }

  String _getDayName(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTime);
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _bookConsultation() async {
    // Client-side: validate the chosen time is not in the past
    final now = DateTime.now();
    final selectedDT = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    if (selectedDT.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot book a past time. Please select a future slot.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    if (endMins <= startMins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }


    setState(() => _isLoading = true);

    String startTimeStr;
    String endTimeStr;

    if (_selectedSlot != null) {
      startTimeStr = _selectedSlot!['start'];
      endTimeStr = _selectedSlot!['end'];
    } else {
      startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';
    }

    final result = await ApiService.createBooking({
      'advisor_id': widget.advisor.id,
      'booking_date':
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      'start_time': startTimeStr,
      'end_time': endTimeStr,
      'consultation_type': _consultationType,
      'amount': _calculateAmount(),
      'meeting_location': _consultationType == 'physical' ? _locationController.text.trim() : null,
    });

    if (result['success']) {
      final booking = result['booking'] as BookingModel;
      
      // Initiate Khalti Payment
      final khaltiResult = await ApiService.initiateKhaltiPayment(booking.id);
      
      setState(() => _isLoading = false);

      if (khaltiResult != null && khaltiResult['payment_url'] != null) {
        final url = Uri.parse(khaltiResult['payment_url']);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          // Show verification dialog
          if (mounted) {
            _showVerifyDialog(booking.id, khaltiResult['pidx']);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch payment URL')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initiate Khalti payment')),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Received!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your consultation has been booked successfully. You can start chatting at the scheduled time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Go to My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerifyDialog(int bookingId, String pidx) {
    bool isVerifying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Done Paying?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please click verify after you complete the payment in Khalti.'),
              if (isVerifying) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ]
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setDialogState(() => isVerifying = true);
                      final res = await ApiService.verifyKhaltiPayment(pidx, bookingId);
                      setDialogState(() => isVerifying = false);
                      
                      if (res['success']) {
                        if (mounted) {
                          Navigator.pop(ctx); // Close verify dialog
                          _showSuccessPopup();
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? 'Payment not confirmed yet. Please wait a moment.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify Payment'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF381b85),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Book Consultation',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Advisor info Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.advisor.user?.fullName[0].toUpperCase() ?? '?',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.advisor.user?.fullName ?? 'Advisor',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText),
                                ),
                                Text(
                                  'Rs. ${widget.advisor.hourlyRate.toStringAsFixed(0)}/hr',
                                  style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date Picker
                      const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkText)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.inputBorder),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppTheme.accentPurple),
                                const SizedBox(width: 12),
                                Text(
                                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const SizedBox(height: 24),
                        // Time Selection Slots
                        const Text('Available Slots', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkText)),
                        const SizedBox(height: 12),
                        if (_displaySlots.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.error.withOpacity(0.1)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: AppTheme.error, size: 20),
                                SizedBox(width: 8),
                                Expanded(child: Text('Guru has no defined slots for this day yet.', style: TextStyle(fontSize: 13, color: AppTheme.darkText))),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _displaySlots.length,
                            itemBuilder: (context, index) {
                              final slot = _displaySlots[index];
                              final isSelected = _selectedSlot == slot;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedSlot = slot;
                                    // Update internal times for billing calculation
                                    final startParts = slot['start'].split(':');
                                    final endParts = slot['end'].split(':');
                                    _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
                                    _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.accentPurple : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: isSelected ? AppTheme.accentPurple : AppTheme.inputBorder.withOpacity(0.5)),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${slot['start']} - ${slot['end']}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.darkText,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_displaySlots.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start Time', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkText)),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: _selectStartTime,
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: AppTheme.inputBorder.withOpacity(0.5)),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(_startTime.format(context), style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('End Time', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkText)),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: _selectEndTime,
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(color: AppTheme.inputBorder.withOpacity(0.5)),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(_endTime.format(context), style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                      // Consultation Type
                      const Text('Consultation Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkText)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            'chat',
                            'voice',
                            'video',
                            if (widget.advisor.isPhysicalAvailable) 'physical'
                          ].map((type) {
                            final selected = _consultationType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _consultationType = type);
                                  if (type == 'physical' && _locationController.text.isEmpty && widget.advisor.officeAddress != null) {
                                      _locationController.text = widget.advisor.officeAddress!;
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.accentPurple : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? AppTheme.accentPurple : AppTheme.inputBorder.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        type == 'chat'
                                            ? Icons.chat
                                            : type == 'voice'
                                                ? Icons.phone
                                                : type == 'video'
                                                    ? Icons.videocam
                                                    : Icons.location_on,
                                        color: selected ? Colors.white : AppTheme.greyText,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type[0].toUpperCase() + type.substring(1),
                                        style: TextStyle(
                                          color: selected ? Colors.white : AppTheme.greyText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_consultationType == 'physical') ...[
                          const SizedBox(height: 24),
                          const Text('Meeting Location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkText)),
                          const SizedBox(height: 10),
                          if (widget.advisor.officeAddress != null && widget.advisor.officeAddress!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPurple.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentPurple.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: AppTheme.accentPurple, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Guru\'s Office: ${widget.advisor.officeAddress}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.darkText),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _locationController.text = widget.advisor.officeAddress!,
                                    child: const Text('Use This'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter meeting address or temple name...',
                              prefixIcon: const Icon(Icons.map_outlined, color: AppTheme.accentPurple),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: AppTheme.inputBorder.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                      // Total
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                                Text(_getDurationText(), style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
                              ],
                            ),
                            Text(
                              'Rs. ${_calculateAmount().toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accentPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      PrimaryButton(
                        label: 'Confirm Booking',
                        isLoading: _isLoading,
                        backgroundColor: AppTheme.goldDark,
                        onPressed: _bookConsultation,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
