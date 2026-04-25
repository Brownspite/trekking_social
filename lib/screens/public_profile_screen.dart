import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfileScreen extends StatefulWidget {
  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  static const List<Map<String, dynamic>> avatarStyles = [
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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4F53C))),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('User not found', style: TextStyle(color: Colors.white))),
      );
    }

    final fullName = _userData!['fullName'] as String? ?? 'Explorer';
    final bio = _userData!['bio'] as String? ?? 'No bio yet.';
    final avatarId = _userData!['avatarId'] as int? ?? 0;
    final eventsJoined = List<String>.from(_userData!['eventsJoined'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fullName,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: avatarStyles[avatarId]['colors'],
                ),
              ),
              child: Center(
                child: avatarStyles[avatarId]['icon'] == null
                    ? Text(
                        _getInitials(fullName),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0A0A0A),
                        ),
                      )
                    : Icon(
                        avatarStyles[avatarId]['icon'],
                        size: 40,
                        color: const Color(0xFF0A0A0A),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatBox(eventsJoined.length.toString(), 'Events Joined'),
              ],
            ),
            const SizedBox(height: 40),
            // Follow / Add Friend button would go here in the future
            SizedBox(
              width: 160,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Friend request sent!'),
                      backgroundColor: Color(0xFF1A3A1A),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD4F53C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Add Friend', style: TextStyle(color: Color(0xFFD4F53C), fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String number, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F1F1F)),
      ),
      child: Column(
        children: [
          Text(number, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }
}
