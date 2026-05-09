import 'package:flutter/material.dart';

/// Centralized avatar styles used across the app.
/// Each avatar has a gradient, an optional icon, and an emoji label
/// for display when no icon is set.
///
/// Index 0-5: Cute animals
/// Index 6-11: Manly / adventurer characters
class AvatarStyles {
  AvatarStyles._();

  static const List<Map<String, dynamic>> styles = [
    // ── Cute Animals ──────────────────────────────────────────
    {
      'colors': [Color(0xFFFFB347), Color(0xFFFF6F61)],
      'icon': Icons.pets_rounded,
      'label': '🐱',
      'name': 'Cat',
    },
    {
      'colors': [Color(0xFF87CEEB), Color(0xFF4FC3F7)],
      'icon': Icons.flutter_dash,
      'label': '🐦',
      'name': 'Bird',
    },
    {
      'colors': [Color(0xFFA8E6CF), Color(0xFF56C596)],
      'icon': Icons.emoji_nature_rounded,
      'label': '🐸',
      'name': 'Frog',
    },
    {
      'colors': [Color(0xFFFFD1DC), Color(0xFFFF69B4)],
      'icon': Icons.cruelty_free_rounded,
      'label': '🐰',
      'name': 'Bunny',
    },
    {
      'colors': [Color(0xFFF9E79F), Color(0xFFF5B041)],
      'icon': Icons.bug_report_rounded,
      'label': '🐝',
      'name': 'Bee',
    },
    {
      'colors': [Color(0xFFD7BDE2), Color(0xFFBB8FCE)],
      'icon': Icons.catching_pokemon_rounded,
      'label': '🦋',
      'name': 'Butterfly',
    },

    // ── Manly / Adventurer Characters ─────────────────────────
    {
      'colors': [Color(0xFF2C3E50), Color(0xFF1ABC9C)],
      'icon': Icons.hiking_rounded,
      'label': '🏔️',
      'name': 'Hiker',
    },
    {
      'colors': [Color(0xFF8B0000), Color(0xFFFF4500)],
      'icon': Icons.local_fire_department_rounded,
      'label': '🔥',
      'name': 'Fire',
    },
    {
      'colors': [Color(0xFF1A1A2E), Color(0xFF16213E)],
      'icon': Icons.shield_rounded,
      'label': '🛡️',
      'name': 'Shield',
    },
    {
      'colors': [Color(0xFF2C3E50), Color(0xFF3498DB)],
      'icon': Icons.sailing_rounded,
      'label': '⛵',
      'name': 'Sailor',
    },
    {
      'colors': [Color(0xFF4A0E0E), Color(0xFFC0392B)],
      'icon': Icons.fitness_center_rounded,
      'label': '💪',
      'name': 'Strong',
    },
    {
      'colors': [Color(0xFF0D3B0D), Color(0xFF27AE60)],
      'icon': Icons.military_tech_rounded,
      'label': '⭐',
      'name': 'Ranger',
    },
  ];
}
