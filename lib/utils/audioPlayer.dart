// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// // ignore: import_of_legacy_library_into_null_safe
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:kumchat/models/const.dart';
// import 'package:kumchat/models/utils.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AudioPlayerWidget extends StatefulWidget {
//   final audioURL;
//   final peer;
//   final bool? isMe;

//   const AudioPlayerWidget({Key? key, this.audioURL, this.peer, this.isMe})
//       : super(key: key);
//   @override
//   _AudioPlayerState createState() => _AudioPlayerState();
// }

// class _AudioPlayerState extends State<AudioPlayerWidget> {
//   FlutterSound? _player;
//   Duration? nowTime;
//   Duration? TDuration;
//   String? totalDuration;
//   bool? isPlaying;

//   String photoUrl = '';
//   String nickname = '';
//   SharedPreferences? prefs;

//   @override
//   void initState() {
//     super.initState();
//     _player = FlutterSound();
//     _player!.startPlayer(widget.audioURL).catchError((error) {
//       // catch audio error ex: 404 url, wrong url ...
//       print(error);
//     });
//     _player.durationFuture.then((d) {
//       TDuration = d;
//       setState(() {
//         checkTimer();
//       });
//     });
//     readLocal();
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     super.dispose();
//   }

//   void checkTimer() {
//     /*nowTime = [_player.value.position.inHours.toInt(),
//       controller.value.position.inHours.toInt(),currentDuration.toInt()]
//         .map((f)=> f.remainder(60).toString().padLeft(2,'0') ).join(':');*/

//     totalDuration = [
//       TDuration.inHours.toInt(),
//       TDuration.inMinutes.toInt(),
//       TDuration.inSeconds.toInt()
//     ].map((f) => f.remainder(60).toString().padLeft(2, '0')).join(':');
//   }

//   void readLocal() async {
//     prefs = await SharedPreferences.getInstance();
//     photoUrl = prefs.getString(PHOTO_URL) ?? '';
//     nickname = prefs.getString(NICKNAME) ?? '';
//   }

//   Widget avatar(user) {
//     return (user ?? '').isNotEmpty
//         ? CircleAvatar(
//             backgroundImage: CachedNetworkImageProvider(user), radius: 22.5)
//         : CircleAvatar(
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//             child: Text(Utils.getInitials(nickname)),
//             radius: 22.5,
//           );
//   }

//   Widget avatarP(Map<String, dynamic> user) {
//     return (user[PHOTO_URL] ?? '').isNotEmpty
//         ? CircleAvatar(
//             backgroundImage: CachedNetworkImageProvider(user[PHOTO_URL]),
//             radius: 22.5)
//         : CircleAvatar(
//             backgroundColor: Colors.blue,
//             foregroundColor: Colors.white,
//             child: Text(Utils.getInitials(Utils.getNickname(user))),
//             radius: 22.5,
//           );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Wrap(
//       children: <Widget>[
//         Container(
//           margin: EdgeInsets.all(0.0),
//           color: Colors.white,
//           constraints: BoxConstraints(
//               maxWidth: MediaQuery.of(context).size.width * 0.75),
//           height: 88,
//           child: Center(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 StreamBuilder<FullAudioPlaybackState>(
//                   stream: _player.fullPlaybackStateStream,
//                   builder: (context, snapshot) {
//                     final fullState = snapshot.data;
//                     final state = fullState?.state;

//                     final buffering = fullState?.buffering;
//                     if (state == AudioPlaybackState.playing) {
//                       isPlaying = true;
//                     } else {
//                       isPlaying = false;
//                     }
//                     return ListTile(
//                       contentPadding: EdgeInsets.all(0.0),
//                       leading: widget.isMe
//                           ? Stack(
//                               overflow: Overflow.visible,
//                               children: <Widget>[
//                                 avatar(photoUrl),
//                                 Positioned(
//                                   bottom: 0.0,
//                                   right: 0.0,
//                                   child: Container(
//                                       padding: EdgeInsets.all(0.0),
//                                       child: Icon(
//                                         Icons.mic,
//                                         color: widget.peer[LAST_SEEN] == true
//                                             ? Colors.blue[400]
//                                             : Colors.grey,
//                                       )),
//                                 ),
//                               ],
//                             )
//                           : null,
//                       title: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           (state == AudioPlaybackState.connecting ||
//                                   buffering == true)
//                               ? Container(
//                                   width: 25.0,
//                                   height: 25.0,
//                                   child: CircularProgressIndicator(),
//                                 )
//                               : (state == AudioPlaybackState.playing)
//                                   ? GestureDetector(
//                                       onTap: () => _player.pause(),
//                                       child: Icon(
//                                         Icons.pause,
//                                         size: 25.0,
//                                       ),
//                                     )
//                                   : GestureDetector(
//                                       onTap: () => _player.play(),
//                                       child: Icon(
//                                         Icons.play_arrow,
//                                         size: 25.0,
//                                       ),
//                                     ),
//                           StreamBuilder<Duration>(
//                             stream: _player.durationStream,
//                             builder: (context, snapshot) {
//                               final duration = snapshot.data ?? Duration.zero;
//                               return StreamBuilder<Duration>(
//                                 stream: _player.getPositionStream(),
//                                 builder: (context, snapshot) {
//                                   var position = snapshot.data ?? Duration.zero;
//                                   if (position > duration) {
//                                     position = duration;
//                                   }
//                                   return SeekBar(
//                                     duration: duration,
//                                     position: position,
//                                     onChangeEnd: (newPosition) {
//                                       _player.seek(newPosition);
//                                       setState(() {
//                                         nowTime = newPosition;
//                                       });
//                                     },
//                                   );
//                                 },
//                               );
//                             },
//                           ),
//                         ],
//                       ),
//                       /*
//                       trailing: widget.isMe == false
//                           ? Stack(
//                               overflow: Overflow.visible,
//                               children: <Widget>[
//                                 //avatarP(widget.peer),
//                                 Positioned(
//                                   top: 0.0,
//                                   right: 0.0,
//                                   child: Container(
//                                       child: Icon(
//                                     Icons.mic,
//                                     color:
//                                         /*widget.peer[LAST_SEEN] == true
//                                         ? Colors.blue[400]
//                                         :*/
//                                         Colors.grey,
//                                   )),
//                                 ),
//                               ],
//                             )
//                           : null,*/
//                       subtitle: Align(
//                         alignment: Alignment.centerLeft,
//                         child: isPlaying == true
//                             ? Text('$nowTime')
//                             : Text('$totalDuration'),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class SeekBar extends StatefulWidget {
//   final Duration duration;
//   final Duration position;
//   final ValueChanged<Duration> onChanged;
//   final ValueChanged<Duration> onChangeEnd;

//   SeekBar({
//     @required this.duration,
//     @required this.position,
//     this.onChanged,
//     this.onChangeEnd,
//   });

//   @override
//   _SeekBarState createState() => _SeekBarState();
// }

// class _SeekBarState extends State<SeekBar> {
//   double _dragValue;

//   @override
//   Widget build(BuildContext context) {
//     return Slider(
//       min: 0.0,
//       divisions: 10,
//       max: widget.duration.inMilliseconds.toDouble(),
//       value: _dragValue ?? widget.position.inMilliseconds.toDouble(),
//       onChanged: (value) {
//         setState(() {
//           _dragValue = value;
//         });
//         if (widget.onChanged != null) {
//           widget.onChanged(Duration(milliseconds: value.round()));
//         }
//       },
//       onChangeEnd: (value) {
//         _dragValue = null;
//         if (widget.onChangeEnd != null) {
//           widget.onChangeEnd(Duration(milliseconds: value.round()));
//         }
//       },
//     );
//   }
// }
