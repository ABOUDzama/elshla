import 'package:flutter/material.dart';

class GameModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  const GameModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
