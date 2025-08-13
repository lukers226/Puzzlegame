import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:puzzlegame/screens/numbergridpage.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Use a single AudioPlayer instance for taps
  final AudioPlayer _tapPlayer = AudioPlayer();

  Future<void> playTapSound() async {
    try {
      await _tapPlayer.play(AssetSource('audio/tz.mp3'), volume: 0.9);
    } catch (e) {
      // Optionally ignore or print error
    }
  }

  @override
  void dispose() {
    _tapPlayer.dispose(); // Free audio resource
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('MMMM d').format(DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF25043A), Color(0xFF3A2D8D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Top Card
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.15),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.76,
                padding: EdgeInsets.symmetric(vertical: 28, horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 24,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/trophy.png',
                      width: 86,
                      height: 86,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Daily Challenges",
                      style: GoogleFonts.lato(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 7)],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      today,
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        color: Colors.white.withOpacity(0.75),
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 21),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8A47EB),
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(vertical: 13),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          await playTapSound();
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                        child: Text(
                          "Play",
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // New Game Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.80,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF6A62E),
                    shape: StadiumBorder(),
                    elevation: 8,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () async {
                    await playTapSound();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NumberGridPage()),
                    );
                  },
                  child: Text(
                    "New Game",
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 18,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navBarItem(
                    imagePath: 'assets/images/home.png',
                    label: 'Home',
                    selected: _selectedIndex == 0,
                    onTap: () async {
                      await playTapSound();
                      setState(() => _selectedIndex = 0);
                    },
                  ),
                  _navBarItem(
                    imagePath: 'assets/images/cal.png',
                    label: 'Daily Challenges',
                    selected: _selectedIndex == 1,
                    onTap: () async {
                      await playTapSound();
                      setState(() => _selectedIndex = 1);
                    },
                  ),
                  _navBarItem(
                    imagePath: 'assets/images/gal.png',
                    label: 'Journey',
                    selected: _selectedIndex == 2,
                    onTap: () async {
                      await playTapSound();
                      setState(() => _selectedIndex = 2);
                    },
                  ),
                ],
              ),
            ),
          ),
          // Top-right icons (coin/settings)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.04,
            right: 16,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    await playTapSound();
                    // add logic for coin tap if any
                  },
                  child: Image.asset('assets/images/ac.png', width: 38, height: 38),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await playTapSound();
                    // add logic for settings tap if any
                  },
                  child: Image.asset('assets/images/setting.png', width: 38, height: 38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBarItem({
    required String imagePath,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: selected ? 44 : 28,
            height: selected ? 44 : 28,
            color: selected ? null : Colors.white70,
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: selected ? 16 : 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Example next page for 'New Game'
class NextPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Next Page', style: GoogleFonts.lato()),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Text(
          'You arrived at the next page!',
          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
