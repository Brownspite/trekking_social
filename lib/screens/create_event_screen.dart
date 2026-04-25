import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';

class CreateEventScreen extends StatefulWidget {
  final TrekEvent? existingEvent;
  const CreateEventScreen({super.key, this.existingEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _spotsController = TextEditingController();
  
  String _selectedCategory = 'Trekking';
  final List<String> _categories = ['Trekking', 'Social', 'Meetup'];
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final event = widget.existingEvent!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _priceController.text = event.price == 'Free' ? '' : event.price.replaceAll(RegExp(r'[^\d.]'), '');
      _spotsController.text = event.maxSpots.toString();
      _selectedCategory = event.tag;
      _selectedDate = event.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(event.dateTime);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _spotsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4F53C),
              onPrimary: Color(0xFF0A0A0A),
              surface: Color(0xFF161616),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4F53C),
              onPrimary: Color(0xFF0A0A0A),
              surface: Color(0xFF161616),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time.'),
          backgroundColor: Color(0xFF3A1A1A),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final organizerName = user?.displayName ?? 'Trekking Social Member';

      // Combine date and time
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // Format date string (e.g., "Sat 12 Apr · 07:00")
      final dateStr = DateFormat('EEE d MMM').format(dateTime);
      final timeStr = DateFormat('HH:mm').format(dateTime);
      final formattedDate = '$dateStr · $timeStr';

      // Determine UI defaults based on category
      String iconKey = 'terrain';
      String gradientKey = 'green_forest';
      
      if (_selectedCategory == 'Social') {
        iconKey = 'restaurant';
        gradientKey = 'warm_amber';
      } else if (_selectedCategory == 'Meetup') {
        iconKey = 'groups';
        gradientKey = 'blue_sky';
      }

      final maxSpots = int.tryParse(_spotsController.text) ?? 10;
      final priceInput = _priceController.text.trim();
      String price = 'Free';
      if (priceInput.isNotEmpty && priceInput.toLowerCase() != 'free') {
        final digits = priceInput.replaceAll(RegExp(r'[^\d.]'), '');
        if (digits.isNotEmpty) {
          price = '$digits Taka';
        } else {
          price = priceInput;
        }
      }

      final isEditing = widget.existingEvent != null;
      final eventId = isEditing ? widget.existingEvent!.id : '';

      final event = TrekEvent(
        id: eventId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateTime: dateTime,
        location: _locationController.text.trim(),
        price: price,
        spots: 0, // Starts at 0 joined
        maxSpots: maxSpots,
        tag: _selectedCategory,
        tagColor: const Color(0xFFD4F53C), // Model ignores this on toFirestore
        tagBg: const Color(0xFF1E1E1E),
        gradientColors: [], // Model uses gradientKey in toFirestore
        icon: Icons.event, // Model uses iconKey
        organizer: isEditing ? widget.existingEvent!.organizer : organizerName,
        creatorId: isEditing ? widget.existingEvent!.creatorId : user!.uid,
        difficulty: _selectedCategory == 'Trekking' ? 'Moderate' : null,
      );

      // We need to slightly modify toFirestore approach or pass the keys.
      // Actually, since toFirestore uses the actual IconData and Color list to find keys, 
      // we must pass the matching static ones from TrekEvent to ensure proper translation.
      // Wait, we can just create a map payload directly, or use the real colors/icons.
      // Let's instantiate it properly.
      
      final realEvent = TrekEvent.fromFirestore(
        // We simulate a document snapshot map to use the factory and get the right UI mappings
        _FakeDocSnapshot({
          'title': event.title,
          'description': event.description,
          'dateTime': Timestamp.fromDate(event.dateTime),
          'location': event.location,
          'price': event.price,
          'spots': event.spots,
          'maxSpots': event.maxSpots,
          'tag': event.tag,
          'icon': iconKey,
          'gradientPreset': gradientKey,
          'difficulty': event.difficulty,
          'highlights': isEditing ? widget.existingEvent!.highlights : <String>[],
          'organizer': event.organizer,
          'creatorId': event.creatorId,
          'attendees': isEditing ? widget.existingEvent!.attendees : <Map<String, dynamic>>[],
        })
      );

      if (isEditing) {
        await EventService().updateEvent(realEvent);
      } else {
        await EventService().createEvent(realEvent);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Event updated successfully! 🎉' : 'Event published successfully! 🎉',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF1A3A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Failed to update event: $e' : 'Failed to publish event: $e'),
            backgroundColor: const Color(0xFF3A1A1A),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingEvent != null ? 'Edit Event' : 'Create Event',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('EVENT TITLE'),
                _buildTextField(
                  controller: _titleController,
                  hint: 'Give it a catchy name',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                
                _buildLabel('CATEGORY'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1F1F1F)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      dropdownColor: const Color(0xFF1E1E1E),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                      items: _categories.map((String cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('DATE'),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161616),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF1F1F1F)),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedDate == null 
                                      ? 'Select Date' 
                                      : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                    style: TextStyle(
                                      color: _selectedDate == null ? Colors.white30 : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.white54),
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
                          _buildLabel('TIME'),
                          GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              height: 52,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF161616),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF1F1F1F)),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTime == null 
                                      ? 'Select Time' 
                                      : _selectedTime!.format(context),
                                    style: TextStyle(
                                      color: _selectedTime == null ? Colors.white30 : Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Icon(Icons.access_time_rounded, size: 18, color: Colors.white54),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('LOCATION (MEETING POINT)'),
                _buildTextField(
                  controller: _locationController,
                  hint: 'e.g., Central Station',
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('PRICE'),
                          _buildTextField(
                            controller: _priceController,
                            hint: 'e.g. 50 or Free',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('MAX SPOTS'),
                          _buildTextField(
                            controller: _spotsController,
                            hint: 'e.g. 15',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Required';
                              if (int.tryParse(val) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildLabel('DESCRIPTION'),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'Tell people what to expect...',
                  maxLines: 4,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4F53C),
                      foregroundColor: const Color(0xFF0A0A0A),
                      disabledBackgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0A0A),
                            ),
                          )
                        : Text(
                            widget.existingEvent != null ? 'Save Changes' : 'Publish Event',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: const Color(0xFFD4F53C),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 15,
        ),
        filled: true,
        fillColor: const Color(0xFF161616),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F1F1F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4F53C)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCC3333)),
        ),
      ),
    );
  }
}

class _FakeDocSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  _FakeDocSnapshot(this._data);

  @override
  String get id => '';
  
  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data[field];

  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference => throw UnimplementedError();
  
  @override
  Object? operator [](Object field) => _data[field];
}
