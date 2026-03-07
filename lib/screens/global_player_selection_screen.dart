import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/settings_service.dart';
import '../services/score_service.dart';

class GlobalPlayerSelectionScreen extends StatefulWidget {
  final int minPlayers;
  final int? maxPlayers;
  final String gameTitle;
  final Function(BuildContext context, List<String> selectedPlayers)
  onStartGame;

  const GlobalPlayerSelectionScreen({
    super.key,
    required this.gameTitle,
    required this.onStartGame,
    this.minPlayers = 2,
    this.maxPlayers,
  });

  @override
  State<GlobalPlayerSelectionScreen> createState() =>
      _GlobalPlayerSelectionScreenState();
}

class _GlobalPlayerSelectionScreenState
    extends State<GlobalPlayerSelectionScreen> {
  final TextEditingController _playerCtrl = TextEditingController();
  List<String> _allSavedPlayers = [];
  final Set<String> _selectedPlayers = {};

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  void _loadPlayers() {
    setState(() {
      _allSavedPlayers = SettingsService.getSavedPlayers();
    });
  }

  void _addPlayer() {
    final name = _playerCtrl.text.trim();
    if (name.isNotEmpty && !_allSavedPlayers.contains(name)) {
      setState(() {
        _allSavedPlayers.insert(0, name);
        _selectedPlayers.add(name);
      });
      SettingsService.savePlayers(_allSavedPlayers);
      _playerCtrl.clear();
    }
  }

  void _removePlayer(String name) {
    setState(() {
      _allSavedPlayers.remove(name);
      _selectedPlayers.remove(name);
    });
    SettingsService.savePlayers(_allSavedPlayers);
  }

  void _toggleSelection(String name) {
    setState(() {
      if (_selectedPlayers.contains(name)) {
        _selectedPlayers.remove(name);
      } else {
        if (widget.maxPlayers == null ||
            _selectedPlayers.length < widget.maxPlayers!) {
          _selectedPlayers.add(name);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'الحد الأقصى ${widget.maxPlayers} لاعبين',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _startGame() {
    if (_selectedPlayers.length >= widget.minPlayers) {
      // Sync with ScoreService
      final scoreService = ScoreService();
      // If we are starting fresh or players changed, we might want to reset
      // For now, let's just ensure they are in the service
      final selectedList = _selectedPlayers.toList();

      // Auto-init scoreboard if it's empty or different
      if (scoreService.players.isEmpty) {
        scoreService.setPlayers(selectedList);
      }

      widget.onStartGame(context, selectedList);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تحتاج على الأقل ${widget.minPlayers} لاعبين للبدء',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _selectedPlayers.length >= widget.minPlayers;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          widget.gameTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اختار مين هيلعب معاك',
                style: GoogleFonts.cairo(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'العدد المطلوب: من ${widget.minPlayers} إلى ${widget.maxPlayers ?? "أي عدد"}',
                style: GoogleFonts.cairo(fontSize: 14, color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Add new player field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _playerCtrl,
                      style: GoogleFonts.cairo(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'اكتب اسم لاعب جديد...',
                        hintStyle: GoogleFonts.cairo(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _addPlayer,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6), // Teal
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF14B8A6,
                            ).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Saved Players List
              Expanded(
                child: _allSavedPlayers.isEmpty
                    ? Center(
                        child: Text(
                          'مفيش لاعبين متسجلين..\nضيف أسماء الشلة عشان تختارهم!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.white54,
                          ),
                        ).animate().fadeIn(),
                      )
                    : ListView.builder(
                        itemCount: _allSavedPlayers.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final name = _allSavedPlayers[index];
                          final isSelected = _selectedPlayers.contains(name);

                          return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () => _toggleSelection(name),
                                  title: Text(
                                    name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  leading: Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? const Color(0xFF6366F1)
                                        : Colors.white54,
                                    size: 28,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _removePlayer(name),
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.1);
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // Start Button
              ElevatedButton(
                    onPressed: canStart ? _startGame : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Indigo
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: canStart ? 8 : 0,
                      shadowColor: const Color(
                        0xFF6366F1,
                      ).withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'يلا نبدأ! (${_selectedPlayers.length})',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                  .animate(target: canStart ? 1 : 0)
                  .scale(begin: const Offset(0.95, 0.95)),
            ],
          ),
        ),
      ),
    );
  }
}
