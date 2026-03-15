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
  String _consultationType = 'chat';
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _displaySlots = [];
  List<Map<String, dynamic>> _occupiedSlots = [];
  Map<String, dynamic>? _selectedSlot;
  int _selectedDuration = 30; // Default 30 mins
  final List<int> _durations = [15, 30, 45, 60, 90, 120, 150, 180];

  double _calculateAmount() {
    final amount = (_selectedDuration / 60.0) * widget.advisor.hourlyRate;
    return amount;
  }

  String _getDurationText() {
    if (_selectedDuration < 60) return '$_selectedDuration mins';
    final hours = _selectedDuration ~/ 60;
    final mins = _selectedDuration % 60;
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
      _selectedDate = picked;
      await _updateDisplaySlots();
    }
  }

  Future<void> _updateDisplaySlots() async {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final occupied = await ApiService.getOccupiedSlots(widget.advisor.id, dateStr);
    
    final dayName = _getDayName(_selectedDate);
    final slots = widget.advisor.availableSlots;
    
    if (mounted) {
      setState(() {
        _occupiedSlots = occupied;
        if (slots != null && slots is Map && slots.containsKey(dayName)) {
          _displaySlots = List<Map<String, dynamic>>.from(slots[dayName]);
        } else {
          _displaySlots = [];
        }
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

    // Duration is always selected from a fixed list, no need to check end time < start time here
    // as it's handled by the duration-based calculation.

    setState(() => _isLoading = true);

    String startTimeStr;
    String endTimeStr;

    startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    
    final endDateTime = DateTime(2000, 1, 1, _startTime.hour, _startTime.minute).add(Duration(minutes: _selectedDuration));
    endTimeStr = '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}';

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

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        _showRequestSentPopup();
      }
    } else {
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

  void _showRequestSentPopup() {
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
                  color: AppTheme.goldDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request Sent!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your booking request has been sent to the Guru. Please wait up to 5 minutes for their acceptance.',
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
                  ),
                  child: const Text('Go to Home', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: AppTheme.darkText))),
        ],
      ),
    );
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
                          _buildErrorContainer('Guru has no defined slots for this day yet.')
                        else ...[
                          const Text('1. Pick a Working Block', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
                          const SizedBox(height: 8),
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
                                    final startParts = slot['start'].split(':');
                                    _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
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
                          if (_selectedSlot != null) ...[
                            const SizedBox(height: 24),
                            const Text('2. Customize Your Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Start At', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () async {
                                          final picked = await showTimePicker(context: context, initialTime: _startTime);
                                          if (picked != null) setState(() => _startTime = picked);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppTheme.inputBorder.withOpacity(0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 18, color: AppTheme.accentPurple),
                                              const SizedBox(width: 8),
                                              Text(_startTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Duration', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.inputBorder.withOpacity(0.5)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _selectedDuration,
                                            isExpanded: true,
                                            items: _durations.map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text('$d mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            )).toList(),
                                            onChanged: (v) => setState(() => _selectedDuration = v!),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_occupiedSlots.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text('Unavailable Times (Already Booked):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _occupiedSlots.map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${s['start']} - ${s['end']}', style: const TextStyle(fontSize: 11, color: AppTheme.error, fontWeight: FontWeight.bold)),
                              )).toList(),
                            ),
                          ],
                        ],
                        if (_displaySlots.isEmpty && (widget.advisor.availableSlots == null || widget.advisor.availableSlots.isEmpty))
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
                                      const Text('Duration', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkText)),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: AppTheme.inputBorder.withOpacity(0.5)),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<int>(
                                            value: _selectedDuration,
                                            isExpanded: true,
                                            items: _durations.map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text('$d mins', style: const TextStyle(fontWeight: FontWeight.w600)),
                                            )).toList(),
                                            onChanged: (v) => setState(() => _selectedDuration = v!),
                                          ),
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
                        label: 'Send Booking Request',
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
