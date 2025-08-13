import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/splash/splash_bloc.dart';
import '../blocs/splash/splash_event.dart';
import '../blocs/splash/splash_state.dart';
import '../widgets/splash_video_widget.dart';
import 'home_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashBloc()..add(SplashStarted()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashFinished) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => HomeScreen()));
          }
        },
        child: Scaffold(
          body: SplashVideoWidget(),
          backgroundColor: Colors.black,
        ),
      ),
    );
  }
}
