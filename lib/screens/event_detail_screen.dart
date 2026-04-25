import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'public_profile_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final TrekEvent event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isJoined = false;
  bool _isLoadingUserData = true;
  Map<String, dynamic>? _currentUserData;
  List<Map<String, dynamic>> _attendees = [];
  int _spotsTaken = 0;

  static const List<Map<String, dynamic>> _avatarStyles = [
    {'colors': [Color(0xFFD4F53C), Color(0xFF8BC34A)], 'icon': null}, // default
    {'colors': [Color(0xFFFF7E5F), Color(0xFFFEB47B)], 'icon': Icons.local_fire_department_rounded},
    {'colors': [Color(0xFF00C9FF), Color(0xFF92FE9D)], 'icon': Icons.water_drop_rounded},
    {'colors': [Color(0xFF6A11CB), Color(0xFF2575FC)], 'icon': Icons.star_rounded},
    {'colors': [Color(0xFFF12711), Color(0xFFF5AF19)], 'icon': Icons.bolt_rounded},
    {'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)], 'icon': Icons.auto_awesome_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _attendees = List.from(widget.event.attendees);
    _spotsTaken = widget.event.spots;
    _loadUserData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _currentUserData = data;
          _isJoined = (data['eventsJoined'] as List?)?.contains(widget.event.id) ?? false;
          _isLoadingUserData = false;
        });
      }
    }
  }

  Future<void> _toggleJoin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentUserData == null) return;
    
    final newJoinState = !_isJoined;
    
    final attendeeMap = {
      'uid': user.uid,
      'name': user.displayName ?? 'User',
      'avatarId': _currentUserData!['avatarId'] ?? 0,
    };

    setState(() {
      _isJoined = newJoinState;
      if (newJoinState) {
        _attendees.add(attendeeMap);
        _spotsTaken++;
      } else {
        _attendees.removeWhere((a) => a['uid'] == user.uid);
        _spotsTaken--;
      }
    });

    try {
      await EventService().toggleEventJoin(widget.event.id, user.uid, newJoinState, attendeeMap);
      if (mounted && newJoinState) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'You\'re in! 🎉 See you there.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF1A3A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isJoined = !newJoinState;
          if (!newJoinState) {
            _attendees.add(attendeeMap);
            _spotsTaken++;
          } else {
            _attendees.removeWhere((a) => a['uid'] == user.uid);
            _spotsTaken--;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                backgroundColor: const Color(0xFF0A0A0A),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: e.gradientColors,
                      ),
                    ),
                    child: Stack(
                      children: [
                        ...List.generate(5, (i) {
                          return Positioned(
                            right: -20 + (i * 40.0),
                            top: 30 + (i * 35.0),
                            child: Container(
                              width: 80 + (i * 15.0),
                              height: 80 + (i * 15.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.03 + (i * 0.008)),
                              ),
                            ),
                          );
                        }),
                        Center(
                          child: Icon(
                            e.icon,
                            size: 80,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF0A0A0A),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildTag(e.tag, e.tagColor, e.tagBg),
                              if (e.difficulty != null) ...[
                                const SizedBox(width: 8),
                                _buildTag(
                                  e.difficulty!,
                                  _difficultyColor(e.difficulty!),
                                  _difficultyBg(e.difficulty!),
                                ),
                              ],
                              if (e.isFree) ...[
                                const SizedBox(width: 8),
                                _buildTag(
                                  'Free',
                                  const Color(0xFF4AAA3A),
                                  const Color(0xFF0F2A0F),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),

                          Text(
                            e.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            'by ${e.organizer}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.4),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.calendar_today_rounded,
                                  'Date',
                                  e.date.split(' · ').first,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.access_time_rounded,
                                  'Time',
                                  e.date.split(' · ').last,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildInfoCard(
                                  Icons.location_on_rounded,
                                  'Location',
                                  e.location.split(',').first,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          _buildSpotsSection(e),
                          const SizedBox(height: 24),

                          const Text(
                            'About',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            e.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.6),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (e.highlights.isNotEmpty) ...[
                            const Text(
                              'Highlights',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...e.highlights.map((h) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4F53C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFFD4F53C),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    h,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ],

                          if (_attendees.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Attendees',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _attendees.length,
                                itemBuilder: (context, index) {
                                  final attendee = _attendees[index];
                                  final avatarId = attendee['avatarId'] as int? ?? 0;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => PublicProfileScreen(uid: attendee['uid'])));
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: _avatarStyles[avatarId]['colors'],
                                        ),
                                        border: Border.all(color: const Color(0xFF222222), width: 1),
                                      ),
                                      child: _avatarStyles[avatarId]['icon'] == null
                                        ? Center(child: Text(attendee['name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0A0A0A), fontSize: 16)))
                                        : Icon(_avatarStyles[avatarId]['icon'], color: const Color(0xFF0A0A0A), size: 20),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          _buildLocationCard(e),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0A).withOpacity(0),
                    const Color(0xFF0A0A0A),
                    const Color(0xFF0A0A0A),
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'per person',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: GestureDetector(
                        onTap: _isLoadingUserData ? null : _toggleJoin,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isJoined
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFD4F53C),
                            borderRadius: BorderRadius.circular(14),
                            border: _isJoined
                                ? Border.all(
                                    color: const Color(0xFF333333),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isJoined
                                    ? Icons.check_circle_rounded
                                    : Icons.add_circle_outline_rounded,
                                color: _isJoined
                                    ? const Color(0xFFD4F53C)
                                    : const Color(0xFF0A0A0A),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isJoined ? 'Joined' : 'Join Event',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _isJoined
                                      ? Colors.white
                                      : const Color(0xFF0A0A0A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1F1F1F),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFD4F53C), size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpotsSection(TrekEvent e) {
    final taken = _spotsTaken;
    final spotsLeft = e.maxSpots > taken ? e.maxSpots - taken : 0;
    final pct = e.maxSpots > 0 ? taken / e.maxSpots : 0.0;
    final isAlmostFull = e.maxSpots > 0 && (spotsLeft / e.maxSpots <= 0.25);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1F1F1F),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$taken / ${e.maxSpots} joined',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAlmostFull
                      ? const Color(0xFF2A0A0A)
                      : const Color(0xFF0F2A0F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAlmostFull
                      ? '$spotsLeft spots left!'
                      : '$spotsLeft spots left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isAlmostFull
                        ? const Color(0xFFCC3333)
                        : const Color(0xFF4AAA3A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: const Color(0xFF222222),
              valueColor: AlwaysStoppedAnimation<Color>(
                isAlmostFull
                    ? const Color(0xFFCC3333)
                    : const Color(0xFFD4F53C),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(TrekEvent e) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              color: const Color(0xFFD4F53C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFD4F53C),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Meeting Point',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.open_in_new_rounded,
              color: Color(0xFF555555),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4AAA3A);
      case 'moderate':
        return const Color(0xFFCC8820);
      case 'hard':
        return const Color(0xFFCC3333);
      default:
        return const Color(0xFF4A7ACC);
    }
  }

  Color _difficultyBg(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF0F2A0F);
      case 'moderate':
        return const Color(0xFF2A1E08);
      case 'hard':
        return const Color(0xFF2A0A0A);
      default:
        return const Color(0xFF0F1E2A);
    }
  }
}
