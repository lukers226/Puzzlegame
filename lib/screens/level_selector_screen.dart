import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/game_bloc.dart';
import 'game_screen.dart';
import '../bloc/game_event.dart';

class LevelSelectorScreen extends StatefulWidget {
  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> {
  Set<int> completedLevels = {};
  int _currentIndex = 0; // No longer used, but you can keep if you want

  bool isUnlocked(int i) {
    if (i == 0) return true;
    if (i == 1) return completedLevels.contains(1);
    if (i == 2) return completedLevels.contains(2);
    return false;
  }

  void _startLevelOne() {
    BlocProvider.of<GameBloc>(context).add(InitializeLevel(1));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(levelNumber: 1),
      ),
    ).then((result) {
      if (result == true && mounted) {
        setState(() {
          completedLevels.add(1);
        });
      }
    });
  }

  Widget _buildHomePage() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/home.png'), // Your bg image path
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          left: screenWidth * 0.07,
          right: screenWidth * 0.07,
          bottom: screenHeight * 0.20,
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: StadiumBorder(),
                elevation: 10,
                shadowColor: Colors.deepOrangeAccent.withOpacity(0.7),
                // Remove default background to use gradient below
                backgroundColor: Colors.transparent,
              ),
              onPressed: _startLevelOne,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.shade400, Colors.deepOrangeAccent.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(29),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrangeAccent.shade200.withOpacity(0.6),
                      offset: Offset(0, 6),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(minHeight: 58),
                  child: Text(
                    "New Game",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only Home page with New Game button, no bottom navigation
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildHomePage(),
    );
  }
}
