import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrekEvent {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final String price;
  final int spots;
  final int maxSpots;
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final List<Color> gradientColors;
  final IconData icon;
  final String? difficulty;
  final List<String> highlights;
  final String organizer;
  final double? lat;
  final double? lng;
  final List<Map<String, dynamic>> attendees;

  const TrekEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.price,
    required this.spots,
    required this.maxSpots,
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.gradientColors,
    required this.icon,
    this.difficulty,
    this.highlights = const [],
    this.organizer = 'Trekking Social',
    this.lat,
    this.lng,
    this.attendees = const [],
  });

  double get spotsPercentage => maxSpots > 0 ? spots / maxSpots : 0.0;
  int get spotsLeft => maxSpots - spots;
  bool get isAlmostFull => maxSpots > 0 && (spotsLeft / maxSpots <= 0.25);
  bool get isFree => price == 'Free';

  String get date {
    final dateFormat = DateFormat('EEE d MMM');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)} · ${timeFormat.format(dateTime)}';
  }

  static const Map<String, IconData> _iconMap = {
    'terrain': Icons.terrain_rounded,
    'restaurant': Icons.restaurant_rounded,
    'sunny': Icons.wb_sunny_rounded,
    'groups': Icons.groups_rounded,
    'landscape': Icons.landscape_rounded,
    'wine_bar': Icons.wine_bar_rounded,
  };

  static const Map<String, Color> _tagColorMap = {
    'Trekking': Color(0xFF4AAA3A),
    'Social': Color(0xFFCC8820),
    'Meetup': Color(0xFF4A7ACC),
  };

  static const Map<String, Color> _tagBgMap = {
    'Trekking': Color(0xFF0F2A0F),
    'Social': Color(0xFF2A1E08),
    'Meetup': Color(0xFF0F1E2A),
  };

  static const Map<String, List<Color>> _gradientMap = {
    'green_forest': [Color(0xFF0D3B0D), Color(0xFF1A5C1A), Color(0xFF0F2A0F)],
    'warm_amber': [Color(0xFF2A1500), Color(0xFF4A2800), Color(0xFF1E160E)],
    'purple_dawn': [Color(0xFF1A0A2E), Color(0xFF2D1B4E), Color(0xFF0F0A1E)],
    'blue_sky': [Color(0xFF0A1E3A), Color(0xFF1A3A5A), Color(0xFF0F1E2A)],
    'deep_green': [Color(0xFF1A2A1A), Color(0xFF2A4A2A), Color(0xFF0A1A0A)],
    'rose_wine': [Color(0xFF2A0A1A), Color(0xFF4A1A2A), Color(0xFF1E0A0E)],
  };

  factory TrekEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tag = data['tag'] as String? ?? 'Trekking';
    final iconKey = data['icon'] as String? ?? 'terrain';
    final gradientKey = data['gradientPreset'] as String? ?? 'green_forest';

    return TrekEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] as String? ?? '',
      price: data['price'] as String? ?? 'Free',
      spots: (data['spots'] as num?)?.toInt() ?? 0,
      maxSpots: (data['maxSpots'] as num?)?.toInt() ?? 1,
      tag: tag,
      tagColor: _tagColorMap[tag] ?? const Color(0xFF4AAA3A),
      tagBg: _tagBgMap[tag] ?? const Color(0xFF0F2A0F),
      gradientColors: _gradientMap[gradientKey] ?? _gradientMap['green_forest']!,
      icon: _iconMap[iconKey] ?? Icons.terrain_rounded,
      difficulty: data['difficulty'] as String?,
      highlights: List<String>.from(data['highlights'] ?? []),
      organizer: data['organizer'] as String? ?? 'Trekking Social',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      attendees: List<Map<String, dynamic>>.from(data['attendees'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    final iconEntry = _iconMap.entries.firstWhere(
      (e) => e.value == icon,
      orElse: () => const MapEntry('terrain', Icons.terrain_rounded),
    );
    final gradientEntry = _gradientMap.entries.firstWhere(
      (e) => e.value.length == gradientColors.length &&
          e.value.every((c) => gradientColors.contains(c)),
      orElse: () => MapEntry('green_forest', _gradientMap['green_forest']!),
    );

    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'price': price,
      'spots': spots,
      'maxSpots': maxSpots,
      'tag': tag,
      'icon': iconEntry.key,
      'gradientPreset': gradientEntry.key,
      'difficulty': difficulty,
      'highlights': highlights,
      'organizer': organizer,
      'lat': lat,
      'lng': lng,
      'attendees': attendees,
    };
  }

  static List<TrekEvent> sampleEvents() {
    return [
      TrekEvent(
        id: '1',
        title: 'Monte Rosa Trek',
        description:
            'Join us for a breathtaking trek through the Monte Rosa massif. '
            'We\'ll traverse alpine meadows, cross glacial streams, and enjoy '
            'panoramic views of the second-highest peak in the Alps. Suitable '
            'for experienced hikers with good fitness levels.',
        dateTime: DateTime(2026, 4, 12, 7, 0),
        location: 'Valle d\'Aosta',
        price: '45 Taka',
        spots: 8,
        maxSpots: 30,
        tag: 'Trekking',
        tagColor: const Color(0xFF4AAA3A),
        tagBg: const Color(0xFF0F2A0F),
        gradientColors: const [Color(0xFF0D3B0D), Color(0xFF1A5C1A), Color(0xFF0F2A0F)],
        icon: Icons.terrain_rounded,
        difficulty: 'Moderate',
        highlights: ['Alpine meadows', '1200m elevation', 'Glacier views', 'Packed lunch included'],
        organizer: 'Alpine Adventures',
        lat: 45.9367,
        lng: 7.8667,
      ),
      TrekEvent(
        id: '2',
        title: 'Community Dinner',
        description:
            'An evening of great food, wine, and conversation. Our seasonal '
            'community dinner features a 4-course Italian menu with locally '
            'sourced ingredients. Meet fellow members, share stories from '
            'recent treks, and plan future adventures together.',
        dateTime: DateTime(2026, 4, 18, 20, 0),
        location: 'Milano Centro',
        price: '30 Taka',
        spots: 12,
        maxSpots: 25,
        tag: 'Social',
        tagColor: const Color(0xFFCC8820),
        tagBg: const Color(0xFF2A1E08),
        gradientColors: const [Color(0xFF2A1500), Color(0xFF4A2800), Color(0xFF1E160E)],
        icon: Icons.restaurant_rounded,
        highlights: ['4-course menu', 'Wine pairing', 'Live music', 'Outdoor terrace'],
        organizer: 'Social Committee',
      ),
      TrekEvent(
        id: '3',
        title: 'Sunrise Hike',
        description:
            'Start your day with an unforgettable sunrise hike along the shores '
            'of Lake Como. This beginner-friendly hike offers stunning views '
            'of the lake and surrounding mountains as the sun rises over the Alps.',
        dateTime: DateTime(2026, 4, 5, 5, 30),
        location: 'Lago di Como',
        price: '20 Taka',
        spots: 5,
        maxSpots: 15,
        tag: 'Trekking',
        tagColor: const Color(0xFF4AAA3A),
        tagBg: const Color(0xFF0F2A0F),
        gradientColors: const [Color(0xFF1A0A2E), Color(0xFF2D1B4E), Color(0xFF0F0A1E)],
        icon: Icons.wb_sunny_rounded,
        difficulty: 'Easy',
        highlights: ['Sunrise viewpoint', 'Lake panorama', 'Breakfast stop', 'Photo opportunities'],
        organizer: 'Dawn Trekkers',
        lat: 46.0160,
        lng: 9.2572,
      ),
      TrekEvent(
        id: '4',
        title: 'Spring Meetup',
        description:
            'Our annual spring gathering in Parco Sempione! Bring a blanket, '
            'some snacks, and your best energy. We\'ll have group activities, '
            'plan the summer trekking calendar, and welcome new members to '
            'the community.',
        dateTime: DateTime(2026, 4, 20, 16, 0),
        location: 'Parco Sempione, Milano',
        price: 'Free',
        spots: 30,
        maxSpots: 50,
        tag: 'Meetup',
        tagColor: const Color(0xFF4A7ACC),
        tagBg: const Color(0xFF0F1E2A),
        gradientColors: const [Color(0xFF0A1E3A), Color(0xFF1A3A5A), Color(0xFF0F1E2A)],
        icon: Icons.groups_rounded,
        highlights: ['Open to all', 'Group activities', 'Summer planning', 'New members welcome'],
        organizer: 'Community Team',
      ),
      TrekEvent(
        id: '5',
        title: 'Dolomiti Weekend',
        description:
            'A two-day adventure in the heart of the Dolomites. Day one '
            'features a challenging ridge walk with via ferrata sections, '
            'followed by an overnight stay in a mountain refuge. Day two '
            'descends through lush valleys back to the starting point.',
        dateTime: DateTime(2026, 4, 26, 6, 0),
        location: 'Cortina d\'Ampezzo',
        price: '120 Taka',
        spots: 3,
        maxSpots: 12,
        tag: 'Trekking',
        tagColor: const Color(0xFF4AAA3A),
        tagBg: const Color(0xFF0F2A0F),
        gradientColors: const [Color(0xFF1A2A1A), Color(0xFF2A4A2A), Color(0xFF0A1A0A)],
        icon: Icons.landscape_rounded,
        difficulty: 'Hard',
        highlights: ['Via ferrata', 'Mountain refuge', '2-day trek', 'Equipment provided'],
        organizer: 'Alpine Adventures',
        lat: 46.5369,
        lng: 12.1358,
      ),
      TrekEvent(
        id: '6',
        title: 'Wine & Cheese Night',
        description:
            'Indulge in an exquisite selection of Italian wines paired with '
            'artisanal cheeses from across the region. Our sommelier will '
            'guide you through each pairing while sharing the stories behind '
            'the vineyards and dairies.',
        dateTime: DateTime(2026, 4, 24, 19, 30),
        location: 'Navigli District, Milano',
        price: '35 Taka',
        spots: 18,
        maxSpots: 20,
        tag: 'Social',
        tagColor: const Color(0xFFCC8820),
        tagBg: const Color(0xFF2A1E08),
        gradientColors: const [Color(0xFF2A0A1A), Color(0xFF4A1A2A), Color(0xFF1E0A0E)],
        icon: Icons.wine_bar_rounded,
        highlights: ['Sommelier-led', '6 wine selections', 'Artisan cheese', 'Cozy venue'],
        organizer: 'Social Committee',
      ),
    ];
  }
}
