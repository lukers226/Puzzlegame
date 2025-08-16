import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/game_bloc.dart';
import 'game_screen.dart';
import '../bloc/game_event.dart';

class LevelSelectorScreen extends StatefulWidget {
  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> {
  Set<int> completedLevels = {};
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playButtonSound() async {
    await _audioPlayer.play(AssetSource('sounds/tap.mp3'), volume: 0.6);
  }

  void showLockedDialogModern(BuildContext context) {
    showGeneralDialog(
      barrierLabel: "Level Locked",
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      height: 260,
                      width: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.35),
                            Colors.deepPurple.withOpacity(0.31),
                            Colors.white.withOpacity(0.20)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 5,
                          ),
                        ],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.6,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_rounded, size: 56, color: Colors.deepOrangeAccent.shade100),
                          SizedBox(height: 16),
                          Text(
                            "Level Locked",
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              color: Colors.deepPurpleAccent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              shadows: [Shadow(color: Colors.black26, blurRadius: 4)]
                            ),
                          ),
                          SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "First complete the previous level to unlock this one.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.87),
                              ),
                            ),
                          ),
                          SizedBox(height: 22),
                          SizedBox(
                            width: 120,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)
                                ),
                                elevation: 8
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text("OK",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
                  begin: Offset(0, 1),
                  end: Offset(0, 0))
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  bool isUnlocked(int i) {
    if (i == 0) return true;
    if (i == 1) return completedLevels.contains(1);
    if (i == 2) return completedLevels.contains(2);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    List<int> levels = [1, 2, 3];
    List<String> levelNames = ["Noob", "Pro", "Master"];
    List<Color> levelColors = [
      Colors.greenAccent.shade400,
      Colors.indigoAccent.shade400,
      Colors.deepOrangeAccent.shade200
    ];
    List<IconData> planetIcons = [
      Icons.public,
      Icons.language,
      Icons.travel_explore
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade900,
            Colors.purple.shade800,
            Colors.black
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 32,
            top: 32,
            child: Icon(Icons.flash_on, color: Colors.amberAccent.withOpacity(0.12), size: 90),
          ),
          Positioned(
            right: 40,
            top: 92,
            child: Icon(Icons.circle, color: Colors.pink.withOpacity(0.05), size: 120),
          ),
          Positioned(
            right: 40,
            bottom: 100,
            child: Icon(Icons.language, color: Colors.greenAccent.withOpacity(0.09), size: 85),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              flexibleSpace: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  colors: [
                    Colors.yellowAccent,
                    Colors.deepPurpleAccent,
                  ]
                ).createShader(rect),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Text(
                      "Number Master",
                      style: GoogleFonts.lilitaOne(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 30, color: Colors.purpleAccent.withOpacity(0.18), offset: Offset(3, 8))
                        ]
                      ),
                    ),
                  ),
                ),
              ),
              toolbarHeight: 110,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, size: 18, color: Colors.yellowAccent.shade200),
                        SizedBox(width: 8),
                        Text(
                          "Assignment",
                          style: GoogleFonts.lilitaOne(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.yellowAccent.shade100,
                            letterSpacing: 1.5
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.circle, size: 18, color: Colors.yellowAccent.shade200),
                      ],
                    ),
                    SizedBox(height: 18),
                    for (int i = 0; i < levels.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(36),
                          onTap: () async {
                            await playButtonSound();
                            if (!isUnlocked(i)) {
                              showLockedDialogModern(context);
                              return;
                            }
                            BlocProvider.of<GameBloc>(context).add(InitializeLevel(levels[i]));
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => GameScreen(levelNumber: levels[i]),
                              ),
                            );
                            if (result == true) {
                              setState(() {
                                completedLevels.add(levels[i]);
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 330),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  levelColors[i].withOpacity(0.94),
                                  Colors.pinkAccent.withOpacity(i == 2 ? 0.55 : 0.30)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight
                              ),
                              borderRadius: BorderRadius.circular(36),
                              border: Border.all(
                                width: completedLevels.contains(levels[i]) ? 2 : 4,
                                color: completedLevels.contains(levels[i])
                                    ? Colors.grey.shade700
                                    : Colors.white.withOpacity(0.7),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: completedLevels.contains(levels[i])
                                      ? Colors.black45
                                      : levelColors[i].withOpacity(0.22),
                                  blurRadius: 24,
                                  offset: Offset(3, 8),
                                )
                              ],
                            ),
                            width: double.infinity,
                            height: 110,
                            child: Row(
                              children: [
                                SizedBox(width: 35),
                                Icon(
                                  planetIcons[i],
                                  color: Colors.white.withOpacity(0.92),
                                  size: 40,
                                ),
                                SizedBox(width: 30),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        levelNames[i].toUpperCase(),
                                        style: TextStyle(
                                          color: completedLevels.contains(levels[i])
                                              ? Colors.grey[400]
                                              : Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'Orbitron',
                                          letterSpacing: 1.8,
                                          fontSize: 22,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Icon(Icons.auto_awesome, color: Colors.white70, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            "Level ${levels[i]}",
                                            style: TextStyle(
                                              color: completedLevels.contains(levels[i]) ? Colors.blueGrey[200] : Colors.white.withOpacity(0.92),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Orbitron',
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(right: 22),
                                  child: completedLevels.contains(levels[i])
                                      ? Icon(Icons.verified, color: Colors.greenAccent, size: 36)
                                      : Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
