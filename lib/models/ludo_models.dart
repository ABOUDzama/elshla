class LudoPath {
  // Define the main 52-step path coordinates for the board.
  // The board is a 15x15 grid (indices 0 to 14 for x and y).
  // A standard Ludo path starts from the player's starting square
  // and goes clockwise around the board.

  // We will define the universal path starting from the Red start position.
  // Red start offset is 0, Green is 13, Yellow is 26, Blue is 39.

  static const List<List<int>> universalPath = [
    // Starting on the left horizontal path (Red Start)
    [1, 6], [2, 6], [3, 6], [4, 6], [5, 6],
    // Turning up towards Green Base
    [6, 5], [6, 4], [6, 3], [6, 2], [6, 1], [6, 0],
    // Crossing the top
    [7, 0], [8, 0],
    // Coming down from Green Base
    [8, 1], [8, 2], [8, 3], [8, 4], [8, 5],
    // Turning right towards Yellow Base
    [9, 6], [10, 6], [11, 6], [12, 6], [13, 6], [14, 6],
    // Crossing the right
    [14, 7], [14, 8],
    // Coming left from Yellow Base
    [13, 8], [12, 8], [11, 8], [10, 8], [9, 8],
    // Turning down towards Blue Base
    [8, 9], [8, 10], [8, 11], [8, 12], [8, 13], [8, 14],
    // Crossing the bottom
    [7, 14], [6, 14],
    // Coming up from Blue Base
    [6, 13], [6, 12], [6, 11], [6, 10], [6, 9],
    // Turning left back towards Red Base
    [5, 8], [4, 8], [3, 8], [2, 8], [1, 8], [0, 8],
    // Crossing the left
    [0, 7], [0, 6],
  ];

  // Colors start at different indices in the universal path
  static const int redStart = 0;
  static const int greenStart = 13;
  static const int yellowStart = 26;
  static const int blueStart = 39;

  // After 50 steps (since step 51 is turning into the home column),
  // players turn into their respective "Home Paths" (Victory Paths)

  static const List<List<int>> redHomePath = [
    [1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7], // Center Home
  ];

  static const List<List<int>> greenHomePath = [
    [7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6], // Center Home
  ];

  static const List<List<int>> yellowHomePath = [
    [13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7], // Center Home
  ];

  static const List<List<int>> blueHomePath = [
    [7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8], // Center Home
  ];

  static const List<List<int>> safeSpots = [
    [1, 6], [2, 8], // Red area safety
    [8, 1], [6, 2], // Green area safety
    [13, 8], [12, 6], // Yellow area safety
    [6, 13], [8, 12], // Blue area safety
  ];
}

class LudoPawn {
  int id; // 0, 1, 2, 3
  String colorStr; // 'red', 'green', 'yellow', 'blue'
  int position; // -1 means at base, 0-50 for main path, 51-56 for home path
  bool isFinished;

  LudoPawn({
    required this.id,
    required this.colorStr,
    this.position = -1,
    this.isFinished = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'colorStr': colorStr,
    'position': position,
    'isFinished': isFinished,
  };

  factory LudoPawn.fromJson(Map<String, dynamic> json) => LudoPawn(
    id: json['id'],
    colorStr: json['colorStr'],
    position: json['position'],
    isFinished: json['isFinished'],
  );
}
