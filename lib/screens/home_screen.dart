import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'event_detail_screen.dart';
import 'create_event_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedChip = 0;
  final EventService _eventService = EventService();
  List<TrekEvent> _events = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _headerAnimController;
  late AnimationController _cardsAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _cardsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _cardsAnimController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardsAnimController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final tags = _events.map((e) => e.tag).toSet().toList();
    tags.sort();
    return ['All', ...tags];
  }

  List<TrekEvent> get _filteredEvents {
    var events = _events;

    if (_selectedChip != 0) {
      final cats = _categories;
      if (_selectedChip < cats.length) {
        final category = cats[_selectedChip];
        events = events.where((e) => e.tag == category).toList();
      } else {
        _selectedChip = 0;
      }
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      events = events.where((e) =>
        e.title.toLowerCase().contains(q) ||
        e.location.toLowerCase().contains(q) ||
        e.tag.toLowerCase().contains(q)
      ).toList();
    }

    return events;
  }

  List<TrekEvent> get _upcomingEvents {
    final sorted = List<TrekEvent>.from(_events)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return sorted.take(4).toList();
  }

  TrekEvent get _featuredEvent => _events.first;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventScreen()),
          );
        },
        backgroundColor: const Color(0xFFD4F53C),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Color(0xFF0A0A0A), size: 28),
      ),
      body: SafeArea(
        child: StreamBuilder<List<TrekEvent>>(
        stream: _eventService.streamEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _events.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4F53C)),
            );
          }
          if (snapshot.hasData) {
            _events = snapshot.data!;
          }
          return RefreshIndicator(
            color: const Color(0xFFD4F53C),
            backgroundColor: const Color(0xFF1E1E1E),
            onRefresh: () async {
              final events = await _eventService.getEvents();
              setState(() => _events = events);
            },
            child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF555555),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.displayName?.split(' ').first ?? 'Explorer',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4F53C), Color(0xFF8BC34A)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (user?.displayName?.isNotEmpty == true
                                    ? user!.displayName![0]
                                    : 'E')
                                  .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0A0A0A),
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

            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1F1F1F),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search events, locations...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white.withOpacity(0.25),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.3),
                                size: 18,
                              ),
                            )
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (_searchQuery.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildFeaturedBanner(_featuredEvent),
                ),
              ),

            if (_searchQuery.isEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                        },
                        child: Text(
                          'See all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD4F53C).withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    itemCount: _upcomingEvents.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildUpcomingCard(_upcomingEvents[index]),
                      );
                    },
                  ),
                ),
              ),
            ],

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchQuery.isNotEmpty
                        ? 'Results'
                        : 'Explore Events',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      Text(
                        '${_filteredEvents.length} found',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildCategoryChips(),
              ),
            ),

            if (_filteredEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.white.withOpacity(0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No events found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search or category',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildAnimatedEventCard(
                        _filteredEvents[index],
                        index,
                      );
                    },
                    childCount: _filteredEvents.length,
                  ),
                ),
              ),
            ],
          ),
          );
        },
      ),
    ));
  }


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  void _openEventDetail(TrekEvent event) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EventDetailScreen(event: event),
        transitionsBuilder: (context, anim, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }


  Widget _buildFeaturedBanner(TrekEvent event) {
    return GestureDetector(
      onTap: () => _openEventDetail(event),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4F53C), Color(0xFFB8D935)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.04),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Colors.black.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'FEATURED EVENT',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black.withOpacity(0.6),
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A0A0A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event.date,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.people_rounded,
                      size: 13,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.spots} spots',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.price,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD4F53C),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingCard(TrekEvent event) {
    return GestureDetector(
      onTap: () => _openEventDetail(event),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: event.gradientColors,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                event.icon,
                size: 70,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: event.tagBg.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: event.tagColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.date.split(' · ').first,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        event.price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD4F53C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (index) {
          final isSelected = _selectedChip == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedChip = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD4F53C)
                      : const Color(0xFF161616),
                  borderRadius: BorderRadius.circular(22),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: const Color(0xFF1F1F1F),
                          width: 1,
                        ),
                ),
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF0A0A0A)
                        : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAnimatedEventCard(TrekEvent event, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildEventCard(event),
      ),
    );
  }

  Widget _buildEventCard(TrekEvent event) {
    return GestureDetector(
      onTap: () => _openEventDetail(event),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1F1F1F),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: event.gradientColors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 20,
                    top: 10,
                    child: Icon(
                      event.icon,
                      size: 60,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  Positioned(
                    left: -15,
                    bottom: -15,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        event.icon,
                        color: Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                    ),
                  ),
                  if (event.isAlmostFull)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCC3333).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${event.spots} left',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: event.tagBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.tag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: event.tagColor,
                          ),
                        ),
                      ),
                      if (event.difficulty != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1E2A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.difficulty!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A7ACC),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF444444),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD4F53C),
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            final filled = (event.spotsPercentage * 5).ceil();
                            return Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < (5 - filled)
                                    ? const Color(0xFFD4F53C).withOpacity(0.7)
                                    : const Color(0xFF2A2A2A),
                              ),
                            );
                          }),
                          const SizedBox(width: 4),
                          Text(
                            '${event.spots} spots',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.35),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
