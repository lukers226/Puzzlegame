import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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

final LevelConfig level = LevelConfig(
  rows: 12,
  cols: 9,
  startingRows: 3,
  minNumber: 1,
  maxNumber: 9,
  addRowsPerPress: 1,
);

const List<Color> puzzleColors = [
  Colors.redAccent, Colors.orangeAccent, Colors.yellowAccent, Colors.green,
  Colors.tealAccent, Colors.cyan, Colors.blueAccent, Colors.purpleAccent,
  Colors.deepPurpleAccent, Colors.pinkAccent, Colors.amber, Colors.lime, Colors.lightGreen,
];
final Color fadedCellOverlay = Colors
    .transparent; // <-- No color overlay for faded (just transparent)
final Color selectedCellBorder = Colors.yellow;
final Color errorCellOverlay =
    Colors.redAccent.withOpacity(0.4); // Only error still overlays

const rewardImages = [
  'assets/images/rowclear.png',
  'assets/images/nicespotted.png',
];
const rewardAudios = [
  'audio/clear.mp3',
  'audio/clear.mp3',
];

class NumberGridPage extends StatefulWidget {
  @override
  State<NumberGridPage> createState() => _NumberGridPageState();
}

class _NumberGridPageState extends State<NumberGridPage> with TickerProviderStateMixin {
  final random = Random();
  late List<List<CellData>> grid;
  late int filledRows;
  int score = 0, addRowCredits = 6, bulbCredits = 1, stageNumber = 1, allTimeScore = 256;
  Offset? shakeOffsetA, shakeOffsetB;
  AnimationController? shakeController;
  Animation<Offset>? shakeAnimation;
  Timer? errorFlashTimer;
  Point<int>? selectedCell;

  int _rewardIndex = 0;
  bool _isRewardVisible = false;
  String? _rewardImage;
  final player = AudioPlayer();
  AnimationController? _rewardAnimCtrl;

  // Animation for first 3 rows
  List<bool> _initialRowAnimated = [false, false, false];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  List<List<CellData>> _generatePairedRowsWithOneLeft(int rows, int cols) {
    List<int> pool = [];
    int minN = level.minNumber, maxN = level.maxNumber;
    int totalCells = rows * cols;
    int totalPairs = (totalCells - 1) ~/ 2;
    for (int i = 0; i < totalPairs; i++) {
      bool sum10 = random.nextBool();
      int a = minN + random.nextInt(maxN - minN + 1);
      int b = (sum10 && 10 - a != a && 10 - a >= minN && 10 - a <= maxN)
          ? 10 - a
          : a;
      pool.add(a);
      pool.add(b);
    }
    int leftover = minN + random.nextInt(maxN - minN + 1);
    pool.add(leftover);
    pool.shuffle();
    List<List<CellData>> gridRows = [];
    int idx = 0;
    for (int r = 0; r < rows; r++) {
      List<CellData> row = [];
      for (int c = 0; c < cols; c++) {
        row.add(CellData(number: pool[idx++]));
      }
      gridRows.add(row);
    }
    return gridRows;
  }

  List<CellData> _generatePerfectPairRowWithOneMatching(int cols, int requiredPairValue) {
    List<int> pool = [];
    int minN = level.minNumber, maxN = level.maxNumber;
    int numPairs = (cols - 1) ~/ 2;
    for (int i = 0; i < numPairs; i++) {
      bool sum10 = random.nextBool();
      int a = minN + random.nextInt(maxN - minN + 1);
      int b = (sum10 && 10 - a != a && 10 - a >= minN && 10 - a <= maxN)
          ? 10 - a
          : a;
      pool.add(a);
      pool.add(b);
    }
    int matchValue;
    if (random.nextBool()) {
      matchValue = requiredPairValue;
    } else {
      int altValue = 10 - requiredPairValue;
      if (altValue >= minN && altValue <= maxN)
        matchValue = altValue;
      else
        matchValue = requiredPairValue;
    }
    pool.add(matchValue);
    pool.shuffle();
    return pool.map((n) => CellData(number: n)).toList();
  }

  List<CellData> _generatePairRow(int cols) {
    List<int> pool = [];
    int minN = level.minNumber, maxN = level.maxNumber;
    int nPairs = cols ~/ 2;
    for (int i = 0; i < nPairs; i++) {
      bool sum10 = random.nextBool();
      int a = minN + random.nextInt(maxN - minN + 1);
      int b = (sum10 && 10 - a != a && 10 - a >= minN && 10 - a <= maxN)
          ? 10 - a
          : a;
      pool.add(a);
      pool.add(b);
    }
    if (cols.isOdd) {
      int val = minN + random.nextInt(maxN - minN + 1);
      pool.add(val);
      pool.add(val);
    }
    pool.shuffle();
    return pool.take(cols).map((n) => CellData(number: n)).toList();
  }

  void _startGame() {
    grid = List.generate(
        level.rows, (_) => List.generate(level.cols, (_) => CellData(number: null)));
    List<List<CellData>> initialRows =
        _generatePairedRowsWithOneLeft(level.startingRows, level.cols);
    for (int i = 0; i < level.startingRows; i++) {
      grid[i] = initialRows[i];
    }
    filledRows = level.startingRows;
    score = 0;
    addRowCredits = 6;
    bulbCredits = 1;
    selectedCell = null;
    _stopErrorAnim();
    _hideRewardOverlay();

    _initialRowAnimated = [false, false, false];
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 220 * i), () {
        if (mounted) setState(() => _initialRowAnimated[i] = true);
      });
    }
    setState(() {});
  }

  void _selectCell(int row, int col) {
    final cell = grid[row][col];
    if (cell.state == CellState.faded || cell.number == null) return;
    if (selectedCell == null) {
      setState(() => selectedCell = Point(row, col));
    } else {
      if (selectedCell!.x == row && selectedCell!.y == col) {
        setState(() => selectedCell = null);
        return;
      }
      _tryMatch(selectedCell!.x, selectedCell!.y, row, col);
    }
  }

  void _tryMatch(int r1, int c1, int r2, int c2) async {
    final cell1 = grid[r1][c1];
    final cell2 = grid[r2][c2];
    if (cell1.state == CellState.faded || cell2.state == CellState.faded) return;
    bool match = _checkMatch(cell1.number!, cell2.number!);
    if (match) {
      setState(() {
        grid[r1][c1].state = CellState.faded;
        grid[r2][c2].state = CellState.faded;
        selectedCell = null;
        score += 10;
      });
      await Future.delayed(Duration(milliseconds: 350));
      _checkRowBonus();
    } else {
      _playShakeAnim(r1, c1, r2, c2);
      setState(() => selectedCell = null);
    }
  }

  bool _checkMatch(int a, int b) => (a == b) || (a + b == 10);

  void _checkRowBonus() {
    for (int r = 0; r < filledRows; r++) {
      bool allFaded = grid[r].every((cell) => cell.number != null && cell.state == CellState.faded);
      bool alreadyGiven = grid[r].isNotEmpty && grid[r][0].rowBonusGiven;
      if (allFaded && !alreadyGiven) {
        setState(() {
          for (var cell in grid[r]) {
            cell.rowBonusGiven = true;
          }
          score += 100;
        });
        _showRewardOverlay();
      }
    }
  }

  void _showRewardOverlay() async {
    if (_isRewardVisible) return;
    _rewardImage = rewardImages[_rewardIndex % rewardImages.length];
    String audio = rewardAudios[_rewardIndex % rewardAudios.length];
    _rewardAnimCtrl?.dispose();
    _rewardAnimCtrl =
        AnimationController(duration: Duration(milliseconds: 900), vsync: this);
    setState(() {
      _isRewardVisible = true;
    });
    _rewardAnimCtrl!.forward();
    _rewardIndex++;
    await player.stop();
    await player.play(AssetSource(audio));
    Future.delayed(Duration(seconds: 3), () {
      _hideRewardOverlay();
    });
  }

  void _hideRewardOverlay() {
    if (_isRewardVisible) {
      setState(() {
        _isRewardVisible = false;
      });
      player.stop();
      _rewardAnimCtrl?.dispose();
    }
  }

  void _playShakeAnim(int r1, int c1, int r2, int c2) {
    shakeController?.dispose();
    shakeController =
        AnimationController(duration: Duration(milliseconds: 350), vsync: this);
    shakeAnimation = Tween<Offset>(begin: Offset.zero, end: Offset(0.06, 0))
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(shakeController!);
    shakeController!.addListener(() {
      setState(() {
        shakeOffsetA = shakeAnimation!.value;
        shakeOffsetB = shakeAnimation!.value * -1;
      });
    });
    setState(() {
      grid[r1][c1].state = CellState.error;
      grid[r2][c2].state = CellState.error;
    });
    shakeController!.forward().then((_) {
      setState(() {
        grid[r1][c1].state = CellState.normal;
        grid[r2][c2].state = CellState.normal;
        shakeOffsetA = null;
        shakeOffsetB = null;
      });
    });
    errorFlashTimer?.cancel();
    errorFlashTimer = Timer(Duration(milliseconds: 280), () {
      setState(() {
        grid[r1][c1].state = CellState.normal;
        grid[r2][c2].state = CellState.normal;
      });
    });
  }

  void _stopErrorAnim() {
    shakeController?.dispose();
    errorFlashTimer?.cancel();
  }

  void _addRowsToBottom() {
    if (addRowCredits <= 0) return;
    if (filledRows >= level.rows) return;
    int maxRowsAvail = level.rows - filledRows;
    int rowsToAdd = min(level.addRowsPerPress, maxRowsAvail);

    List<int> remainingNumbers = [];
    for (int r = 0; r < filledRows; r++) {
      for (int c = 0; c < level.cols; c++) {
        final cell = grid[r][c];
        if (cell.number != null && cell.state != CellState.faded) {
          remainingNumbers.add(cell.number!);
        }
      }
    }

    for (int k = 0; k < rowsToAdd; k++) {
      if (remainingNumbers.length == 1) {
        grid[filledRows] =
            _generatePerfectPairRowWithOneMatching(level.cols, remainingNumbers[0]);
      } else {
        grid[filledRows] = _generatePairRow(level.cols);
      }
      filledRows++;
    }
    addRowCredits--;
    setState(() {});
  }

  void _bulbPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hint button pressed! Implement your hint logic here.',
            style: TextStyle(fontSize: 15)),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    player.dispose();
    shakeController?.dispose();
    errorFlashTimer?.cancel();
    _rewardAnimCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellSize = (MediaQuery.of(context).size.width - 32) / level.cols;
    return Scaffold(
      backgroundColor: Colors.deepPurple[900],
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple[900]!, Colors.deepPurple[800]!, Colors.deepPurpleAccent, Colors.deepPurple[900]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // ... header, scores, etc ...
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(icon: Icon(Icons.arrow_back, color: Colors.yellow, size: 27), onPressed: () => Navigator.pop(context)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(score.toString(), style: TextStyle(color: Colors.yellow, fontSize: 42, fontWeight: FontWeight.w700, letterSpacing: 0.5, shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
                        ),
                        IconButton(icon: Icon(Icons.settings, color: Colors.yellow, size: 27), onPressed: () {}),
                      ],
                    ),
                  ),
                  Container(
                    height: 44,
                    child: IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    Text(allTimeScore.toString(), style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        initialRowAnimated: _initialRowAnimated,
                      ),
                    ),
                  ),
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
                                child: Text('$addRowCredits', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                                child: Text('$bulbCredits', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
            // Reward overlay: Image only, no background!
            if (_isRewardVisible && _rewardImage != null && _rewardAnimCtrl != null)
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: _rewardAnimCtrl!, curve: Curves.elasticOut),
                  child: Image.asset(
                    _rewardImage!,
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: MediaQuery.of(context).size.width * 0.55,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AnimatedGrid extends StatelessWidget {
  final List<List<CellData>> grid;
  final int cols;
  final double cellSize;
  final Point<int>? selectedCell;
  final Offset? shakeOffsetA;
  final Offset? shakeOffsetB;
  final Function(int, int) onTap;
  final List<bool> initialRowAnimated;

  const AnimatedGrid({
    super.key,
    required this.grid,
    required this.cols,
    required this.cellSize,
    required this.selectedCell,
    required this.shakeOffsetA,
    required this.shakeOffsetB,
    required this.onTap,
    required this.initialRowAnimated,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(cellSize * cols, cellSize * grid.length),
          painter: GridLinesPainter(cols, grid.length, cellSize),
        ),
        Table(
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
        ),
      ],
    );
  }

  Widget _buildCell(BuildContext context, int row, int col) {
    final cell = grid[row][col];
    bool isSelected = selectedCell?.x == row && selectedCell?.y == col && cell.state != CellState.faded;

    final colorIndex = cell.number == null
        ? 0
        : ((cell.number! - 1) % puzzleColors.length);
    final Color numberColor = cell.number != null
        ? puzzleColors[colorIndex]
        : Colors.black38;
    Color? overlay;
    // Only show overlay for error, not for faded
    if (cell.state == CellState.faded)
      overlay = Colors.transparent;
    else if (cell.state == CellState.error) overlay = errorCellOverlay;

    if (row < 3) {
      return AnimatedScale(
        scale: initialRowAnimated[row] ? 1.0 : 0.0,
        curve: Curves.easeOutBack,
        duration: Duration(milliseconds: 400),
        child: AnimatedOpacity(
          opacity: initialRowAnimated[row] ? 1.0 : 0.0,
          duration: Duration(milliseconds: 430),
          child: _buildNormalCell(context, cell, isSelected, numberColor, overlay, row, col),
        ),
      );
    }
    return _buildNormalCell(context, cell, isSelected, numberColor, overlay, row, col);
  }

  Widget _buildNormalCell(BuildContext context, CellData cell, bool isSelected, Color numberColor, Color? overlay, int row, int col) {
    return GestureDetector(
      onTap: cell.number != null && cell.state != CellState.faded
          ? () => onTap(row, col)
          : null,
      child: Container(
        width: cellSize,
        height: cellSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedCellBorder : Colors.white.withOpacity(0.35),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        foregroundDecoration: overlay != null && cell.state != CellState.faded
            ? BoxDecoration(
                color: overlay, borderRadius: BorderRadius.circular(10))
            : null,
        child: AnimatedOpacity(
          opacity: cell.state == CellState.faded ? 0.4 : 1,
          duration: Duration(milliseconds: 300),
          child: cell.number == null
              ? SizedBox()
              : Text(
                  cell.number.toString(),
                  style: TextStyle(
                      fontSize: 20,
                      color: cell.state == CellState.faded
                          ? Colors.grey[600]
                          : numberColor,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black38, blurRadius: 2),
                        if (cell.state != CellState.faded)
                          Shadow(color: numberColor.withOpacity(0.2), blurRadius: 4),
                      ]),
                ),
        ),
      ),
    );
  }
}

class GridLinesPainter extends CustomPainter {
  final int cols, rows;
  final double cellSize;
  GridLinesPainter(this.cols, this.rows, this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Colors.white.withOpacity(0.17)
      ..strokeWidth = 1.2;
    for (int i = 1; i < cols; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, rows * cellSize),
        p,
      );
    }
    for (int i = 1; i < rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(cols * cellSize, i * cellSize),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
