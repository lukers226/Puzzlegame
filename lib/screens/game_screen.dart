import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../bloc/game_state.dart';
import '../models/cell_model.dart';
import 'dart:math';
import 'dart:async';

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

  CellModel? _lastTappedCell;
  int addRowBadge = 6;
  Timer? _timer;
  Duration timeLeft = Duration.zero;
  bool timeLimitDialogShown = false;

  bool showCompletedOverlay = false;
  bool navigatedAfterComplete = false;

  late Map<int, Color> numberColors;

  // Track which faded cells have animated this round
  Set<int> animatedCellIndices = {};

  @override
  void initState() {
    super.initState();
    score = 0;
    addRowBadge = 6;
    navigatedAfterComplete = false;
    showCompletedOverlay = false;
    _generateNumberColors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<GameBloc>(context).add(InitializeLevel(widget.levelNumber));
      _setupTimer();
    });
  }

  @override
  void didUpdateWidget(GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.levelNumber != widget.levelNumber) {
      score = 0;
      addRowBadge = 6;
      navigatedAfterComplete = false;
      showCompletedOverlay = false;
      _generateNumberColors();
      BlocProvider.of<GameBloc>(context).add(InitializeLevel(widget.levelNumber));
      _setupTimer();
    }
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
                    if (mounted) {
                      BlocProvider.of<GameBloc>(context).add(InitializeLevel(widget.levelNumber));
                      _setupTimer();
                    }
                  },
                  icon: Icon(Icons.refresh, size: 22, color: Colors.white),
                  label: Text("Try Again",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    final RenderBox? scoreBox = scoreKey.currentContext?.findRenderObject() as RenderBox?;
    if (scoreBox != null) {
      return scoreBox.localToGlobal(Offset(scoreBox.size.width / 2, scoreBox.size.height / 2));
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
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return SafeArea(
      child: BlocListener<GameBloc, GameState>(
        listenWhen: (previous, current) => previous.completed != current.completed,
        listener: (context, state) {
          if (state.completed && !showCompletedOverlay && !navigatedAfterComplete) {
            setState(() {
              showCompletedOverlay = true;
            });

            Future.microtask(() async {
              await Future.delayed(const Duration(seconds: 1));
              if (!mounted || navigatedAfterComplete) return;

              setState(() {
                showCompletedOverlay = false;
              });

              navigatedAfterComplete = true;

              if (widget.levelNumber < 3) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => GameScreen(levelNumber: widget.levelNumber + 1),
                  ),
                );
              } else {
                Navigator.of(context).pop(true);
              }
            });
          }
        },
        child: BlocConsumer<GameBloc, GameState>(
          listener: (context, state) {},
          builder: (context, state) {
            if (state.grid.isEmpty || state.grid.any((row) => row.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }
            int maxCols = state.grid[0].length;
            List<CellModel?> gridCells = [];
            for (var row in state.grid) gridCells.addAll(row);
            int fillCount = maxRows * maxCols - gridCells.length;
            for (int i = 0; i < fillCount; i++) gridCells.add(null);

            // Trigger only one +10 animation per pair (first faded cell only)
            final List<int> newFadedIndices = [];
            for (int i = 0; i < gridCells.length; i++) {
              final cell = gridCells[i];
              if (cell != null && cell.number != 0 && cell.state == CellState.faded && !animatedCellIndices.contains(i)) {
                newFadedIndices.add(i);
              }
            }
            if (newFadedIndices.isNotEmpty && gridKey.currentContext != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final RenderBox gridBox = gridKey.currentContext!.findRenderObject() as RenderBox;
                double gridWidth = gridBox.size.width;
                double cellSize = gridWidth / maxCols;
                Offset gridPos = gridBox.localToGlobal(Offset.zero);

                // Trigger animation only for the first faded cell
                final fadedIdx = newFadedIndices.first;
                int row = fadedIdx ~/ maxCols;
                int col = fadedIdx % maxCols;
                Offset startPos = gridPos + Offset(col * cellSize + cellSize / 2, row * cellSize + cellSize / 2);
                triggerFlyScore(from: startPos, add: 10);

                animatedCellIndices.addAll(newFadedIndices);
              });
            }
            // Clear animated set on grid reset
            if (gridCells.every((c) => c == null || c.state != CellState.faded)) {
              animatedCellIndices.clear();
            }

            return Stack(
              children: [
                Scaffold(
                  backgroundColor: const Color(0xFF251167),
                  body: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: const [
                              Color(0xFF1A0E4F),
                              Color(0xFF251167),
                              Color(0xFF2A1A70),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          _buildTopSection(w, h),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: maxCols / maxRows,
                                child: Container(
                                  key: gridKey,
                                  alignment: Alignment.center,
                                  margin: EdgeInsets.symmetric(vertical: h * 0.005),
                                  child: CustomPaint(
                                    painter: GridLinesPainter(
                                      rowCount: maxRows,
                                      colCount: maxCols,
                                      color: Colors.deepPurpleAccent.withOpacity(0.6),
                                    ),
                                    child: GridView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
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
                                            margin: EdgeInsets.all(w * 0.012),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(13),
                                            ),
                                          );
                                        }
                                        Color bgColor = Colors.transparent;
                                        if (cell.state == CellState.selected) bgColor = Colors.yellow.shade300;
                                        if (cell.state == CellState.wrong) bgColor = Colors.redAccent.shade200;
                                        if (cell.state == CellState.highlighted) bgColor = Colors.yellow.shade300;
                                        final numberColor = numberColors[cell.number]!;

                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            return GestureDetector(
                                              onTap: cell.state == CellState.faded
                                                  ? null
                                                  : () {
                                                      _lastTappedCell = cell;
                                                      BlocProvider.of<GameBloc>(context).add(CellTapped(cell));
                                                    },
                                              child: Container(
                                                margin: EdgeInsets.all(w * 0.012),
                                                decoration: BoxDecoration(
                                                  color: bgColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                padding: EdgeInsets.all(constraints.maxWidth * 0.03),
                                                child: Center(
                                                  child: Text(
                                                    '${cell.number}',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: constraints.maxWidth * 0.60,
                                                      color: cell.state == CellState.faded
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
                          _buildBottomSection(w, h),
                        ],
                      ),
                      if (isAnimating && animateFrom != null && animateTo != null)
                        AnimatedFlyText(start: animateFrom!, end: animateTo!, text: flyText),
                    ],
                  ),
                ),
                if (showCompletedOverlay)
                  Container(
                    color: Colors.black54,
                    alignment: Alignment.center,
                    child: Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                              child: const Center(
                                child: Icon(Icons.check_rounded, color: Colors.green, size: 54),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "Level ${widget.levelNumber} Completed!",
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
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopSection(double w, double h) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade300.withOpacity(0.3),
            Colors.indigo.shade400.withOpacity(0.2),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.02, w * 0.05, h * 0.025),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBackButton(w),
              _buildScoreDisplay(w),
              _buildTimerDisplay(w, h),
            ],
          ),
          SizedBox(height: h * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [_buildLevelInfo(w)],
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(double w) {
    return Container(
      padding: EdgeInsets.all(w * 0.025),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: w * 0.06),
      ),
    );
  }

  Widget _buildScoreDisplay(double w) {
    return Container(
      key: scoreKey,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.02),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade300, Colors.orange.shade400]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: w * 0.05),
          SizedBox(width: w * 0.015),
          Text(
            '$score',
            style: GoogleFonts.nunito(
              fontSize: w * 0.065,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.3), offset: const Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelInfo(double w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.025),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.02),
            decoration: BoxDecoration(color: Colors.purple.shade300, shape: BoxShape.circle),
            child: Text(
              "${widget.levelNumber}",
              style: GoogleFonts.nunito(fontSize: w * 0.045, color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(width: w * 0.025),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Level",
                style: GoogleFonts.nunito(
                  fontSize: w * 0.035,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Stage ${widget.levelNumber}",
                style: GoogleFonts.nunito(fontSize: w * 0.04, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay(double w, double h) {
    final isLowTime = timeLeft.inSeconds <= 30;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.02),
      decoration: BoxDecoration(
        color: isLowTime ? Colors.red.shade400.withOpacity(0.9) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLowTime ? Colors.red.shade300 : Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: isLowTime
            ? [
                BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4)),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: Colors.white, size: w * 0.05),
          SizedBox(width: w * 0.015),
          Text(
            _formatDuration(timeLeft),
            style: GoogleFonts.robotoMono(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: w * 0.045,
              shadows: [
                Shadow(color: Colors.black.withOpacity(0.3), offset: const Offset(1, 1), blurRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(double w, double h) {
    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.025, w * 0.05, h * 0.03),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade400.withOpacity(0.3),
            Colors.indigo.shade500.withOpacity(0.2),
          ],
        ),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, -8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: w * 0.06),
              SizedBox(width: w * 0.02),
              Text(
                "Power-ups",
                style: GoogleFonts.nunito(fontSize: w * 0.045, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SizedBox(height: h * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEnhancedActionButton(
                icon: Icons.add_circle_outline_rounded,
                label: "Add Row",
                badge: addRowBadge,
                onPressed: addRowBadge > 0
                    ? () {
                        BlocProvider.of<GameBloc>(context).add(AddRow());
                        setState(() {
                          if (addRowBadge > 0) addRowBadge--;
                        });
                      }
                    : null,
                w: w,
                color: Colors.green,
              ),
              _buildEnhancedActionButton(
                icon: Icons.lightbulb_outline_rounded,
                label: "Hint",
                badge: 1,
                onPressed: () {},
                w: w,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton({
    required IconData icon,
    required String label,
    required int badge,
    required VoidCallback? onPressed,
    required double w,
    required Color color,
  }) {
    final buttonSize = w * 0.16;
    final isEnabled = onPressed != null && badge > 0;

    return Column(
      children: [
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: isEnabled
                      ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.8), color])
                      : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  boxShadow: isEnabled ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 6))] : [],
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? onPressed : null,
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    child: Center(child: Icon(icon, color: Colors.white, size: buttonSize * 0.4)),
                  ),
                ),
              ),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: w * 0.06,
                    height: w * 0.06,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600]),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Center(
                      child: Text(
                        '$badge',
                        style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w800, fontSize: w * 0.028),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: w * 0.02),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: w * 0.032,
            color: isEnabled ? Colors.white : Colors.grey.shade400,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class AnimatedFlyText extends StatefulWidget {
  final Offset start;
  final Offset end;
  final String text;

  const AnimatedFlyText({Key? key, required this.start, required this.end, required this.text}) : super(key: key);

  @override
  State<AnimatedFlyText> createState() => _AnimatedFlyTextState();
}

class _AnimatedFlyTextState extends State<AnimatedFlyText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _offset;

  @override
  void initState() {
    super.initState();
    _offset = widget.start;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.addListener(() {
      setState(() {
        _offset = Offset(
          widget.start.dx + (widget.end.dx - widget.start.dx) * _animation.value,
          widget.start.dy + (widget.end.dy - widget.start.dy) * _animation.value,
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
        style: const TextStyle(
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

  GridLinesPainter({required this.rowCount, required this.colCount, required this.color});

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
      oldDelegate.rowCount != rowCount || oldDelegate.colCount != colCount || oldDelegate.color != color;
}
