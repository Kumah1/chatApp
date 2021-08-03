import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerClass extends StatefulWidget {
  final String? videoUrl;

  const VideoPlayerClass({Key? key, this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayerClass> {
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  VideoPlayerController? controller;
  double videoDuration = 0.0;
  double currentDuration = 0.0;
  String? nowTime;
  String? totalDuration;
  bool? showControls;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.network(widget.videoUrl);
    controller!.initialize().then((v) {
      setState(() {
        videoDuration = controller!.value.duration.inSeconds.toDouble();
      });
    });
    showControls = true;
    controller!.addListener(() {
      setState(() {
        currentDuration = controller!.value.position.inSeconds.toDouble();
        checkTimer();
      });
    });
  }

  @override
  void dispose() {
    controller!.dispose();
    super.dispose();
  }

  void checkTimer() {
    nowTime = [
      controller!.value.position.inHours.toInt(),
      controller!.value.position.inHours.toInt(),
      currentDuration.toInt()
    ].map((f) => f.remainder(60).toString().padLeft(2, '0')).join(':');

    totalDuration = [
      controller!.value.duration.inHours.toInt(),
      controller!.value.duration.inMinutes.toInt(),
      controller!.value.duration.inSeconds.toInt()
    ].map((f) => f.remainder(60).toString().padLeft(2, '0')).join(':');
  }

  @override
  Widget build(BuildContext context) {
    if (controller!.value.isPlaying && showControls == true) {
      Timer(Duration(seconds: 3), () {
        showControls = false;
        print('is three secods');
      });
    }
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        setState(() {
          showControls = !showControls!;
        });
      },
      child: Scaffold(
        key: _key,
        backgroundColor: Colors.black,
        appBar: showControls!
            ? AppBar(
                title: Text("Video Player"),
                backgroundColor: Colors.transparent,
                actions: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.forward,
                      color: Colors.white,
                    ),
                    onPressed: null,
                  )
                ],
              )
            : AppBar(
                backgroundColor: Colors.transparent,
              ),
        body: Column(
          children: <Widget>[
            SizedBox(
              height: 100,
            ),
            Container(
              color: Theme.of(context).primaryColor,
              child: controller!.value.initialized
                  ? AspectRatio(
                      aspectRatio: controller!.value.aspectRatio,
                      child: VideoPlayer(controller),
                    )
                  : Container(
                      height: 200,
                      color: Theme.of(context).primaryColor,
                    ),
            ),
            SizedBox(
              height: 50,
            ),
            showControls!
                ? Center(
                    child: Row(
                      children: <Widget>[
                        Text(
                          controller!.value.initialized ? '$nowTime' : '0.0',
                          style: TextStyle(color: Colors.white),
                        ),
                        Slider(
                          value: currentDuration,
                          max: videoDuration,
                          onChanged: (value) => controller!
                              .seekTo(Duration(seconds: value.toInt())),
                        ),
                        Text(
                          controller!.value.initialized
                              ? '$totalDuration'
                              : '0.0',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : Container(),
            showControls!
                ? Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          controller!.value.isPlaying
                              ? controller!.pause()
                              : currentDuration == videoDuration
                                  ? controller!.seekTo(Duration(seconds: 0))
                                  : controller!.play();
                        });
                      },
                      child: Icon(
                        controller!.value.isPlaying
                            ? Icons.pause
                            : currentDuration == videoDuration
                                ? Icons.replay
                                : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
