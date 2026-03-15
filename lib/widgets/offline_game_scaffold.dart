import 'dart:ui';
import 'package:flutter/material.dart';
import '../screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineGameScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Color backgroundColor;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const OfflineGameScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.backgroundColor,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: backgroundColor.withValues(alpha: 0.2)),
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Solid background color - dark base
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F172A), // Slate 900
                  const Color(0xFF1E1B4B), // Indigo 950
                ],
              ),
            ),
          ),
          // Game specific color tint
          Container(
            color: backgroundColor.withValues(alpha: 0.15),
          ),
          // Top highlight blob (Neon effect)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    backgroundColor.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom highlight blob
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.15), // Indigo glow
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(child: body),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
