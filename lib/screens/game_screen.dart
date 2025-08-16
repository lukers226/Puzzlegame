import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../models/cell_model.dart';
import '../services/audio_service.dart';
import 'dart:math';
import 'dart:async';

// Use this simple static config for timer durations
const levelConfigs = {
  1: Duration(minutes: 2),
  2: Duration(minutes: 2),
  3: Duration(minutes: 2),
};

class GameScreen extends StatefulWidget {
  final int levelNumber;
  final int level1Score;
  final int level2Score;

  const GameScreen({
    Key? key,
    required this.levelNumber,
    this.level1Score = 0,
    this.level2Score = 0,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  int score = 0;
  Offset? animateFrom;
  Offset? animateTo;
  String flyText = '';
  bool isAnimating = false;
  final GlobalKey scoreKey = GlobalKey();
  final GlobalKey gridKey = GlobalKey();
  int maxRows = 12;
  Set<int> fadedCellIds = {};
  late Map<int, Color> numberColors;
  CellModel? _lastTappedCell;
  int addRowBadge = 6;

  Timer? _timer;
  Duration timeLeft = Duration.zero;
  bool timeLimitDialogShown = false;

  @override
  void initState() {
    super.initState();
    _generateNumberColors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupTimer();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setupTimer() {
    Duration limit = levelConfigs[widget.levelNumber] ?? Duration(minutes: 2);
    setState(() {
      timeLeft = limit;
      timeLimitDialogShown = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (timeLeft.inSeconds > 0) {
        setState(() {
          timeLeft = timeLeft - Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        _handleTimeLimitReached();
      }
    });
  }

  void _handleTimeLimitReached() async {
    if (timeLimitDialogShown) return;
    setState(() {
      timeLimitDialogShown = true;
    });
    await AudioService().playWrong();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("⏳", style: TextStyle(fontSize: 46)),
              SizedBox(height: 12),
              Text(
                "You reached Time Limit",
                textAlign: TextAlign.center,
                style: GoogleFonts.lilitaOne(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Dispatch InitializeLevel event to Bloc
                    if (mounted) {
                      BlocProvider.of<GameBloc>(context)
                        .add(InitializeLevel(widget.levelNumber));
                      _setupTimer();
                    }
                  },
                  icon: Icon(Icons.refresh, size: 22, color: Colors.white),
                  label: Text("Try Again",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateNumberColors() {
    final random = Random();
    numberColors = {};
    for (int n = 1; n <= 9; n++) {
      numberColors[n] = Color.fromARGB(
        255,
        150 + random.nextInt(106),
        100 + random.nextInt(156),
        130 + random.nextInt(126),
      );
    }
  }

  void _showCompletionDialog(BuildContext context) async {
    await AudioService().playWin();
    String lvlText = "Level ${widget.levelNumber} Completed!";
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("🎉", style: TextStyle(fontSize: 38)),
                  SizedBox(width: 6),
                  Text("🏆", style: TextStyle(fontSize: 34)),
                  SizedBox(width: 6),
                  Text("🎉", style: TextStyle(fontSize: 38)),
                ],
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade100,
                  shape: BoxShape.circle,
                ),
                height: 80,
                width: 80,
                child: Center(
                  child: Icon(Icons.check_rounded,
                      color: Colors.green, size: 54),
                ),
              ),
              SizedBox(height: 20),
              Text(
                lvlText,
                textAlign: TextAlign.center,
                style: GoogleFonts.lilitaOne(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Congratulations!\nYou completed all pairs.",
                textAlign: TextAlign.center,
                style: GoogleFonts.lilitaOne(
                  fontSize: 17,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                  height: 1.22,
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop(true);
                  },
                  icon:
                      Icon(Icons.home_rounded, size: 24, color: Colors.white),
                  label: Text("Home"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void triggerFlyScore({required Offset from, required int add, Duration? duration}) {
    setState(() {
      flyText = "+$add";
      animateFrom = from;
      animateTo = _getScorePosition();
      isAnimating = true;
    });
    Future.delayed(duration ?? Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        score += add;
        isAnimating = false;
      });
    });
  }

  Offset _getScorePosition() {
    final RenderBox? scoreBox =
        scoreKey.currentContext?.findRenderObject() as RenderBox?;
    if (scoreBox != null) {
      return scoreBox.localToGlobal(
          Offset(scoreBox.size.width / 2, scoreBox.size.height / 2));
    }
    return Offset(48, 48);
  }

  String _formatDuration(Duration duration) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) async {
        if (_lastTappedCell != null) {
          final updatedCell = state.grid
              .expand((row) => row)
              .firstWhere((cell) => cell.id == _lastTappedCell!.id,
                  orElse: () => _lastTappedCell!);
          if (_lastTappedCell!.state != CellState.faded &&
              updatedCell.state == CellState.faded) {
            await AudioService().playSuccess();
          } else if (_lastTappedCell!.state != CellState.wrong &&
              updatedCell.state == CellState.wrong) {
            await AudioService().playWrong();
          }
        }
        if (state.completed) {
          if (mounted) Future.microtask(() => _showCompletionDialog(context));
        }
      },
      builder: (context, state) {
        if (state.grid.isEmpty || state.grid.any((row) => row.isEmpty)) {
          return Center(child: CircularProgressIndicator());
        }
        int maxCols = state.grid[0].length;
        List<CellModel?> gridCells = [];
        for (var row in state.grid) gridCells.addAll(row);
        int fillCount = maxRows * maxCols - gridCells.length;
        for (int i = 0; i < fillCount; i++) gridCells.add(null);

        final List<int> newFadedIndices = [];
        for (int i = 0; i < gridCells.length; i++) {
          final cell = gridCells[i];
          if (cell != null &&
              cell.number != 0 &&
              cell.state == CellState.faded &&
              !fadedCellIds.contains(cell.id)) {
            newFadedIndices.add(i);
            fadedCellIds.add(cell.id);
          }
        }
        if (newFadedIndices.isNotEmpty && gridKey.currentContext != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final RenderBox gridBox =
                gridKey.currentContext!.findRenderObject() as RenderBox;
            int fadedIdx = newFadedIndices[0];
            double gridWidth = gridBox.size.width;
            double cellSize = gridWidth / maxCols;
            int row = fadedIdx ~/ maxCols;
            int col = fadedIdx % maxCols;
            Offset gridPos = gridBox.localToGlobal(Offset.zero);
            Offset startPos = gridPos +
                Offset(col * cellSize + cellSize / 2,
                    row * cellSize + cellSize / 2);
            triggerFlyScore(from: startPos, add: 10);
          });
        }

        return Scaffold(
          backgroundColor: Color(0xFF251167),
          body: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child:
                              Icon(Icons.arrow_back, color: Colors.yellow, size: 32),
                        ),
                        Container(
                          key: scoreKey,
                          child: Text('$score',
                              style: GoogleFonts.lilitaOne(
                                  fontSize: 34,
                                  color: Colors.yellow,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule,
                                      color: Colors.yellowAccent, size: 20),
                                  SizedBox(width: 4),
                                  Text(
                                    _formatDuration(timeLeft),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Stage",
                                  style: GoogleFonts.lilitaOne(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500)),
                              Text("${widget.levelNumber}",
                                  style: GoogleFonts.lilitaOne(
                                      fontSize: 19, color: Colors.white)),
                            ]),
                        SizedBox(width: 54),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: maxCols / maxRows,
                        child: Container(
                          key: gridKey,
                          alignment: Alignment.center,
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          child: CustomPaint(
                            painter: GridLinesPainter(
                              rowCount: maxRows,
                              colCount: maxCols,
                              color: Colors.deepPurpleAccent.withOpacity(0.6),
                            ),
                            child: GridView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: maxCols,
                                childAspectRatio: 1,
                              ),
                              itemCount: gridCells.length,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context, idx) {
                                final cell = gridCells[idx];
                                if (cell == null || cell.number == 0) {
                                  return Container(
                                    margin: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                  );
                                }
                                Color bgColor = Colors.transparent;
                                if (cell.state == CellState.selected)
                                  bgColor = Colors.yellow.shade300;
                                if (cell.state == CellState.wrong)
                                  bgColor = Colors.redAccent.shade200;
                                if (cell.state == CellState.highlighted)
                                  bgColor = Colors.yellow.shade300;
                                final numberColor = numberColors[cell.number]!;
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return GestureDetector(
                                      onTap: cell.state == CellState.faded
                                          ? null
                                          : () async {
                                              await AudioService().playSelect();
                                              _lastTappedCell = cell;
                                              BlocProvider.of<GameBloc>(context)
                                                  .add(CellTapped(cell));
                                            },
                                      child: Container(
                                        margin: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        padding: EdgeInsets.all(
                                            constraints.maxWidth * 0.07),
                                        child: Center(
                                          child: Text(
                                            '${cell.number}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize:
                                                  constraints.maxWidth * 0.60,
                                              color: cell.state ==
                                                      CellState.faded
                                                  ? numberColor.withOpacity(0.28)
                                                  : numberColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _badgeActionButton(
                        Icons.add,
                        addRowBadge,
                        addRowBadge > 0
                            ? () {
                                BlocProvider.of<GameBloc>(context).add(AddRow());
                                setState(() {
                                  if (addRowBadge > 0) addRowBadge--;
                                });
                              }
                            : null,
                      ),
                      SizedBox(width: 34),
                      _badgeActionButton(Icons.lightbulb, 1, () {}),
                    ],
                  ),
                  SizedBox(height: 14),
                ],
              ),
              if (isAnimating && animateFrom != null && animateTo != null)
                AnimatedFlyText(
                  start: animateFrom!,
                  end: animateTo!,
                  text: flyText,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _badgeActionButton(IconData icon, int badge, VoidCallback? onPressed) {
    double buttonSize = 64;
    double badgeSize = 22;
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.deepPurpleAccent,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: Opacity(
                opacity: (onPressed != null) ? 1.0 : 0.4,
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AnimatedFlyText extends StatefulWidget {
  final Offset start;
  final Offset end;
  final String text;

  const AnimatedFlyText(
      {Key? key, required this.start, required this.end, required this.text})
      : super(key: key);

  @override
  State<AnimatedFlyText> createState() => _AnimatedFlyTextState();
}

class _AnimatedFlyTextState extends State<AnimatedFlyText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.start;
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 900));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addListener(() {
      setState(() {
        _offset = Offset(
          widget.start.dx +
              (widget.end.dx - widget.start.dx) * _animation.value,
          widget.start.dy +
              (widget.end.dy - widget.start.dy) * _animation.value,
        );
      });
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Text(
        widget.text,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.yellowAccent,
          shadows: [Shadow(blurRadius: 6, color: Colors.orangeAccent)],
        ),
      ),
    );
  }
}

class GridLinesPainter extends CustomPainter {
  final int rowCount;
  final int colCount;
  final Color color;

  GridLinesPainter(
      {required this.rowCount, required this.colCount, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;

    double cellW = size.width / colCount;
    double cellH = size.height / rowCount;

    for (int c = 0; c <= colCount; c++) {
      double x = c * cellW;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int r = 0; r <= rowCount; r++) {
      double y = r * cellH;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridLinesPainter oldDelegate) =>
      oldDelegate.rowCount != rowCount ||
      oldDelegate.colCount != colCount ||
      oldDelegate.color != color;
}
