import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// --- Cell Data ---
enum CellState { normal, selected, faded, error }
class CellData {
  final int? number;
  CellState state;
  bool rowBonusGiven;
  CellData({this.number, this.state = CellState.normal, this.rowBonusGiven = false});
}

class LevelConfig {
  final int rows, cols, startingRows, minNumber, maxNumber, addRowsPerPress;
  LevelConfig({
    required this.rows,
    required this.cols,
    required this.startingRows,
    required this.minNumber,
    required this.maxNumber,
    required this.addRowsPerPress,
  });
}

// --- CONFIG ---
final LevelConfig level = LevelConfig(
  rows: 12,
  cols: 9,
  startingRows: 3,
  minNumber: 1,
  maxNumber: 9,
  addRowsPerPress: 1,
);

// --- Colors ---
const List<Color> puzzleColors = [
  Colors.redAccent, Colors.orangeAccent, Colors.yellowAccent, Colors.green,
  Colors.tealAccent, Colors.cyan, Colors.blueAccent, Colors.purpleAccent,
  Colors.deepPurpleAccent, Colors.pinkAccent, Colors.amber, Colors.lime, Colors.lightGreen,
];
final Color fadedCellOverlay = Colors.white.withOpacity(0.60);
final Color selectedCellBorder = Colors.yellow;
final Color errorCellOverlay = Colors.redAccent.withOpacity(0.4);

class NumberGridPage extends StatefulWidget {
  @override
  State<NumberGridPage> createState() => _NumberGridPageState();
}

class _NumberGridPageState extends State<NumberGridPage> with TickerProviderStateMixin {
  final random = Random();
  late List<List<CellData>> grid;
  late int filledRows;
  int score = 0;
  int addRowCredits = 6;
  int bulbCredits = 1;
  int stageNumber = 1;
  int allTimeScore = 256;
  Offset? shakeOffsetA, shakeOffsetB;
  AnimationController? shakeController;
  Animation<Offset>? shakeAnimation;
  Timer? errorFlashTimer;
  Point<int>? selectedCell;

  @override
  void initState() {
    super.initState();
    _startGame();
  }
  void _startGame() {
    filledRows = level.startingRows;
    grid = List.generate(level.rows, (r) => List.generate(level.cols, (c) => (r < filledRows) ? _randomCell() : CellData(number: null)));
    score = 0;
    addRowCredits = 6;
    bulbCredits = 1;
    selectedCell = null;
    _stopErrorAnim();
    setState(() {});
  }
  CellData _randomCell() => CellData(number: random.nextInt(level.maxNumber - level.minNumber + 1) + level.minNumber);

  void _selectCell(int row, int col) {
    final cell = grid[row][col];
    if (cell.state == CellState.faded || cell.number == null) return;
    if (selectedCell == null) { setState(() => selectedCell = Point(row, col)); }
    else {
      if (selectedCell!.x == row && selectedCell!.y == col) { setState(() => selectedCell = null); return; }
      _tryMatch(selectedCell!.x, selectedCell!.y, row, col);
    }
  }
  void _tryMatch(int r1, int c1, int r2, int c2) async {
    final cell1 = grid[r1][c1];
    final cell2 = grid[r2][c2];
    if (cell1.state == CellState.faded || cell2.state == CellState.faded) return;
    bool match = _checkMatch(cell1.number!, cell2.number!);
    if (match) {
      setState(() { grid[r1][c1].state = CellState.faded; grid[r2][c2].state = CellState.faded; selectedCell = null; score += 10; });
      await Future.delayed(Duration(milliseconds: 350)); _checkRowBonus();
    } else { _playShakeAnim(r1, c1, r2, c2); setState(() => selectedCell = null); }
  }
  bool _checkMatch(int a, int b) => (a == b) || (a + b == 10);

  void _checkRowBonus() {
    for (int r = 0; r < filledRows; r++) {
      bool allFaded = grid[r].every((cell) => cell.number != null && cell.state == CellState.faded);
      bool alreadyGiven = grid[r].isNotEmpty && grid[r][0].rowBonusGiven;
      if (allFaded && !alreadyGiven) {
        setState(() { for (var cell in grid[r]) { cell.rowBonusGiven = true; } score += 100; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Great! Row ${r + 1} fully matched (+100 pts)', style: TextStyle(fontSize:16)),
          duration: Duration(seconds: 1), backgroundColor: Colors.green,
        ));
      }
    }
  }
  void _playShakeAnim(int r1, int c1, int r2, int c2) {
    shakeController?.dispose();
    shakeController = AnimationController(duration: Duration(milliseconds: 350), vsync: this);
    shakeAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(0.06, 0)).chain(CurveTween(curve: Curves.elasticIn)).animate(shakeController!);
    shakeController!.addListener(() { setState(() { shakeOffsetA = shakeAnimation!.value; shakeOffsetB = shakeAnimation!.value * -1; }); });
    setState(() { grid[r1][c1].state = CellState.error; grid[r2][c2].state = CellState.error; });
    shakeController!.forward().then((_) { setState(() { grid[r1][c1].state = CellState.normal; grid[r2][c2].state = CellState.normal; shakeOffsetA = null; shakeOffsetB = null; }); });
    errorFlashTimer?.cancel();
    errorFlashTimer = Timer(Duration(milliseconds: 280), () { setState(() { grid[r1][c1].state = CellState.normal; grid[r2][c2].state = CellState.normal; }); });
  }
  void _stopErrorAnim() { shakeController?.dispose(); errorFlashTimer?.cancel(); }

  void _addRowsToBottom() {
    if (addRowCredits <= 0) return;
    int rowsToAdd = level.addRowsPerPress, slotsLeft = level.rows - filledRows;
    if (rowsToAdd > slotsLeft) rowsToAdd = slotsLeft;
    if (rowsToAdd <= 0) return;
    setState(() {
      if (filledRows < level.rows) {
        grid[filledRows] = List.generate(level.cols, (_) => _randomCell());
        filledRows++; addRowCredits--;
      }
    });
  }
  void _bulbPressed() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Hint button pressed! Implement your hint logic here.', style: TextStyle(fontSize: 15)),
      backgroundColor: Colors.orange, duration: Duration(seconds: 1),
    ));
  }

  /// --- MAIN UI ---
  @override
  Widget build(BuildContext context) {
    final cellSize = (MediaQuery.of(context).size.width - 32) / level.cols;
    return Scaffold(
      backgroundColor: Colors.deepPurple[900],
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple[900]!, Colors.deepPurple[800]!, Colors.deepPurpleAccent, Colors.deepPurple[900]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // === TOP ICONS + SCORE ===
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.yellow, size: 27),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Text(
                        score.toString(),
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 42, // big and visible
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.settings, color: Colors.yellow, size: 27),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              // === "Stage" / "All-Time" Row ===
              Container(
                height: 44, // <-- Increased height to avoid overflow
                child: IntrinsicHeight( // <-- Allows the columns to size themselves
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //crossAxisAlignment: CrossAxisAlignment.end, // Not needed for IntrinsicHeight
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Stage", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.0)),
                            SizedBox(height: 2),
                            Text("$stageNumber", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("All-Time", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.0)),
                            SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emoji_events, color: Colors.white, size: 18),
                                SizedBox(width: 2),
                                Text(
                                  allTimeScore.toString(),
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ==== GRID ====
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: AnimatedGrid(
                    grid: grid,
                    cols: level.cols,
                    cellSize: cellSize,
                    selectedCell: selectedCell,
                    shakeOffsetA: shakeOffsetA,
                    shakeOffsetB: shakeOffsetB,
                    onTap: _selectCell,
                  ),
                ),
              ),
              // ==== BUTTON ROW ====
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FloatingActionButton(
                          heroTag: 'addbtn',
                          elevation: 0,
                          backgroundColor: Colors.deepPurple[700],
                          onPressed: addRowCredits > 0 ? _addRowsToBottom : null,
                          child: Icon(Icons.add, color: Colors.white, size: 34),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: addRowCredits > 0 ? Colors.red : Colors.grey,
                            child: Text(
                              '$addRowCredits',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 38),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FloatingActionButton(
                          heroTag: 'bulbbtn',
                          elevation: 0,
                          backgroundColor: Colors.deepPurple[700],
                          onPressed: bulbCredits > 0 ? _bulbPressed : null,
                          child: Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 30),
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: bulbCredits > 0 ? Colors.red : Colors.grey,
                            child: Text(
                              '$bulbCredits',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
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
      ),
    );
  }
}

// --- GRID UI (unchanged) ---
class AnimatedGrid extends StatelessWidget {
  final List<List<CellData>> grid;
  final int cols;
  final double cellSize;
  final Point<int>? selectedCell;
  final Offset? shakeOffsetA;
  final Offset? shakeOffsetB;
  final Function(int, int) onTap;
  const AnimatedGrid({
    super.key,
    required this.grid,
    required this.cols,
    required this.cellSize,
    required this.selectedCell,
    required this.shakeOffsetA,
    required this.shakeOffsetB,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Table(
      defaultColumnWidth: FixedColumnWidth(cellSize),
      children: [
        for (var row = 0; row < grid.length; row++)
          TableRow(
            children: [
              for (var col = 0; col < cols; col++)
                _buildCell(context, row, col),
            ],
          ),
      ],
    );
  }
  Widget _buildCell(BuildContext context, int row, int col) {
    final cell = grid[row][col];
    bool isSelectedA = selectedCell?.x == row && selectedCell?.y == col && shakeOffsetA != null;
    bool isSelectedB = shakeOffsetB != null && !isSelectedA;
    final isSelected = selectedCell?.x == row && selectedCell?.y == col && cell.state != CellState.faded;
    final baseColor = cell.number != null
        ? puzzleColors[(cell.number! - (cell.number! ~/ puzzleColors.length) * puzzleColors.length) % puzzleColors.length]
        : Colors.black12;
    Color? overlay;
    if (cell.state == CellState.faded) overlay = fadedCellOverlay;
    else if (cell.state == CellState.error) overlay = errorCellOverlay;
    return GestureDetector(
      onTap: cell.number != null && cell.state != CellState.faded ? () => onTap(row, col) : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 260),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(2),
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: (cell.number == null)
              ? Colors.black.withOpacity(0.14)
              : baseColor.withOpacity(cell.state == CellState.faded ? 0.42 : 1),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: selectedCellBorder, width: 2)
              : Border.all(color: Colors.white.withOpacity(0.25), width: 1.0),
        ),
        foregroundDecoration: BoxDecoration(
          color: overlay,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        transform: isSelectedA
            ? Matrix4.translationValues(shakeOffsetA!.dx * 20, 0, 0)
            : isSelectedB
                ? Matrix4.translationValues(shakeOffsetB!.dx * 20, 0, 0)
                : null,
        child: AnimatedOpacity(
          opacity: cell.state == CellState.faded ? 0.5 : 1,
          duration: Duration(milliseconds: 300),
          child: cell.number == null
              ? SizedBox()
              : Text(
                  cell.number.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    color: cell.state == CellState.faded ? Colors.grey[700] : Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 2)],
                  ),
                ),
        ),
      ),
    );
  }
}
