import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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
    setState(() => _isLoading = true);

    final result = await ApiService.createBooking({
      'advisor_id': widget.advisor.id,
      'booking_date':
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
      'start_time':
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
      'consultation_type': _consultationType,
      'amount': widget.advisor.hourlyRate,
    });

    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking created successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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

                      // Time Pickers
                      Row(
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
                        const SizedBox(height: 20),

                      // Consultation Type
                      const Text('Consultation Type', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.darkText)),
                        const SizedBox(height: 10),
                        Row(
                          children: ['chat', 'voice', 'video'].map((type) {
                            final selected = _consultationType == type;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _consultationType = type),
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
                                                : Icons.videocam,
                                        color: selected ? Colors.white : AppTheme.greyText,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        type[0].toUpperCase() + type.substring(1),
                                        style: TextStyle(
                                          color: selected ? Colors.white : AppTheme.greyText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
                            const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkText)),
                            Text(
                              'Rs. ${widget.advisor.hourlyRate.toStringAsFixed(0)}',
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
