import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _hasChanges = false;
  String _originalBio = '';
  int _originalAvatarId = 0;
  int _selectedAvatarId = 0;

  static const List<Map<String, dynamic>> avatarStyles = [
    {'colors': [Color(0xFFD4F53C), Color(0xFF8BC34A)], 'icon': null}, // default
    {'colors': [Color(0xFFFF7E5F), Color(0xFFFEB47B)], 'icon': Icons.local_fire_department_rounded},
    {'colors': [Color(0xFF00C9FF), Color(0xFF92FE9D)], 'icon': Icons.water_drop_rounded},
    {'colors': [Color(0xFF6A11CB), Color(0xFF2575FC)], 'icon': Icons.star_rounded},
    {'colors': [Color(0xFFF12711), Color(0xFFF5AF19)], 'icon': Icons.bolt_rounded},
    {'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)], 'icon': Icons.auto_awesome_rounded},
  ];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';

    _nameController.text = user?.displayName ?? '';

    _loadUserData();

    _nameController.addListener(_checkChanges);
    _bioController.addListener(_checkChanges);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      final bio = (data['bio'] as String?) ?? '';
      final avatarId = (data['avatarId'] as int?) ?? 0;
      setState(() {
        _originalBio = bio;
        _bioController.text = bio;
        _originalAvatarId = avatarId;
        _selectedAvatarId = avatarId;
      });
    }
  }

  void _checkChanges() {
    final currentName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    setState(() {
      _hasChanges = _nameController.text.trim() != currentName ||
          _bioController.text.trim() != _originalBio ||
          _selectedAvatarId != _originalAvatarId;
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarId: _selectedAvatarId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Profile updated successfully!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF1A3A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is String ? e : 'Failed to update profile.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF3A1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final initials = _getInitials(user?.displayName ?? 'U');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Color(0xFF555555),
                      size: 20,
                    ),
                  ),
                  const Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: avatarStyles[_selectedAvatarId]['colors'],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: avatarStyles[_selectedAvatarId]['colors'][0].withValues(alpha: 0.2),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: avatarStyles[_selectedAvatarId]['icon'] == null
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0A0A0A),
                                      ),
                                    )
                                  : Icon(
                                      avatarStyles[_selectedAvatarId]['icon'],
                                      size: 40,
                                      color: const Color(0xFF0A0A0A),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: avatarStyles.length,
                              itemBuilder: (context, index) {
                                final style = avatarStyles[index];
                                final isSelected = _selectedAvatarId == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedAvatarId = index;
                                    });
                                    _checkChanges();
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: style['colors'],
                                      ),
                                      border: isSelected
                                          ? Border.all(color: Colors.white, width: 3)
                                          : Border.all(color: Colors.transparent, width: 3),
                                    ),
                                    child: Center(
                                      child: style['icon'] == null
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0A0A0A),
                                              ),
                                            )
                                          : Icon(
                                              style['icon'],
                                              size: 24,
                                              color: const Color(0xFF0A0A0A),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1F1F1F),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'FULL NAME',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.3),
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    cursorColor: const Color(0xFFD4F53C),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your full name',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: 15,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1E1E1E),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD4F53C),
                                          width: 1,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFFF6B6B),
                                          width: 1,
                                        ),
                                      ),
                                      errorStyle: const TextStyle(
                                        color: Color(0xFFFF6B6B),
                                        fontSize: 11,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Name cannot be empty';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1F1F1F),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Text(
                                    'BIO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.3),
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: TextFormField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    maxLength: 150,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    cursorColor: const Color(0xFFD4F53C),
                                    decoration: InputDecoration(
                                      hintText: 'Tell us about yourself...',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: 14,
                                      ),
                                      counterStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: 11,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1E1E1E),
                                      contentPadding: const EdgeInsets.all(14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD4F53C),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF161616),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF1F1F1F),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EMAIL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.3),
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.lock_rounded,
                                      color: Color(0xFF333333),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        user?.email ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF444444),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Email cannot be changed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: AnimatedOpacity(
                              opacity: _hasChanges ? 1.0 : 0.4,
                              duration: const Duration(milliseconds: 200),
                              child: ElevatedButton(
                                onPressed: (_isLoading || !_hasChanges)
                                    ? null
                                    : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4F53C),
                                  foregroundColor: const Color(0xFF0A0A0A),
                                  disabledBackgroundColor: const Color(0xFF2A2E10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF0A0A0A),
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }
}
