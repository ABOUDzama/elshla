class RoomModel {
  final String roomCode;
  final String player1;
  final String player2;
  final String status; // 'waiting', 'playing', 'finished'
  final String gameType; // 'xo'
  final Map<String, dynamic> gameState;
  final String currentTurn; // player1 or player2
  final String? winner;

  const RoomModel({
    required this.roomCode,
    required this.player1,
    this.player2 = '',
    this.status = 'waiting',
    this.gameType = 'xo',
    this.gameState = const {},
    this.currentTurn = 'player1',
    this.winner,
  });

  factory RoomModel.fromMap(Map<dynamic, dynamic> map, String code) {
    return RoomModel(
      roomCode: code,
      player1: map['player1'] ?? '',
      player2: map['player2'] ?? '',
      status: map['status'] ?? 'waiting',
      gameType: map['gameType'] ?? 'xo',
      gameState: Map<String, dynamic>.from(map['gameState'] ?? {}),
      currentTurn: map['currentTurn'] ?? 'player1',
      winner: map['winner'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'player1': player1,
      'player2': player2,
      'status': status,
      'gameType': gameType,
      'gameState': gameState,
      'currentTurn': currentTurn,
      'winner': winner,
    };
  }

  RoomModel copyWith({
    String? player2,
    String? status,
    Map<String, dynamic>? gameState,
    String? currentTurn,
    String? winner,
  }) {
    return RoomModel(
      roomCode: roomCode,
      player1: player1,
      player2: player2 ?? this.player2,
      status: status ?? this.status,
      gameType: gameType,
      gameState: gameState ?? this.gameState,
      currentTurn: currentTurn ?? this.currentTurn,
      winner: winner ?? this.winner,
    );
  }
}
