import 'package:flutter/material.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<TrekEvent> _events = TrekEvent.sampleEvents();
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getMonthYear(now),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1F1F1F),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_rounded,
                        color: Color(0xFFD4F53C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_events.length} events',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1F1F1F),
                  width: 1,
                ),
              ),
              child: _buildCalendarGrid(now),
            ),

            const SizedBox(height: 20),

            _buildEventSection(),
          ],
        ),
      ),
    );
  }

  List<int> get _eventDays {
    return _events.map((e) => e.dateTime.day).toList();
  }

  List<TrekEvent> get _eventsForSelectedDay {
    if (_selectedDay == null) return _events;
    return _events.where((e) => e.dateTime.day == _selectedDay).toList();
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCalendarGrid(DateTime now) {
    final daysOfWeek = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final startWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        Row(
          children: daysOfWeek.map((day) => Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF444444),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 10),
        ...List.generate(((daysInMonth + startWeekday - 1) / 7).ceil(), (week) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: List.generate(7, (weekday) {
                final dayNumber = week * 7 + weekday + 1 - (startWeekday - 1);
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 42));
                }

                final isToday = dayNumber == now.day;
                final hasEvent = _eventDays.contains(dayNumber);
                final isSelected = dayNumber == _selectedDay;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedDay == dayNumber) {
                          _selectedDay = null;
                        } else {
                          _selectedDay = dayNumber;
                        }
                      });
                    },
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFD4F53C).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isToday)
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFD4F53C)
                                    : const Color(0xFFD4F53C),
                              ),
                              child: Center(
                                child: Text(
                                  '$dayNumber',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0A0A0A),
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFD4F53C)
                                    : const Color(0xFF666666),
                              ),
                            ),
                          if (hasEvent && !isToday)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFD4F53C)
                                    : const Color(0xFF4A7ACC),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEventSection() {
    final events = _eventsForSelectedDay;
    final sectionTitle = _selectedDay != null
        ? 'EVENTS ON ${_getOrdinalDay(_selectedDay!)}'
        : 'ALL UPCOMING';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sectionTitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF555555),
                letterSpacing: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selectedDay != null)
              GestureDetector(
                onTap: () => setState(() => _selectedDay = null),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD4F53C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1F1F1F),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 32,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                Text(
                  'No events on this day',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          )
        else
          ...events.map((event) => _buildCalendarEventCard(event)),
      ],
    );
  }

  String _getOrdinalDay(int day) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final now = DateTime.now();
    return '${months[now.month - 1]} $day';
  }

  Widget _buildCalendarEventCard(TrekEvent event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1F1F1F),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: event.gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  event.icon,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: event.tagBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: event.tagColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
