import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashVideoWidget extends StatefulWidget {
  @override
  State<SplashVideoWidget> createState() => _SplashVideoWidgetState();
}

class _SplashVideoWidgetState extends State<SplashVideoWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/videos/splash.mp4")
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      });
    _controller.setLooping(false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // To cover the full screen, use SizedBox.expand and FittedBox
    return _initialized
        ? SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          )
        : Container( // just a black screen before video loads
            color: Colors.black,
          );
  }
}
