import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/game_controller.dart';
import 'bloc/game_bloc.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GameController _controller = GameController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameBloc>(
      create: (_) => GameBloc(_controller),
      child: MaterialApp(
        title: 'Number Puzzle Game',
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
