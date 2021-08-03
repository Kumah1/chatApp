import 'dart:core';

import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:intl/intl.dart';

import 'seen_provider.dart';

class Bubble extends StatelessWidget {
  const Bubble(
      {@required this.child,
      @required this.timestamp,
      @required this.delivered,
      @required this.isMe,
      @required this.isContinuing});

  final int? timestamp;
  final Widget? child;
  final dynamic delivered;
  final bool? isMe, isContinuing;

  humanReadableTime() => DateFormat('h:mm a')
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp!));

  String when() {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp!);
    DateTime now = DateTime.now();
    String when;
    if (date.day == now.day)
      when = 'today';
    else if (date.day == now.subtract(Duration(days: 1)).day)
      when = 'yesterday';
    else
      when = DateFormat.MMMd().format(date);
    return when;
  }

  getSeenStatus(seen) {
    if (seen is bool) return true;
    if (seen is String) return true;
    return timestamp! <= seen;
  }

  @override
  Widget build(BuildContext context) {
    var triangle = CustomPaint(
      painter: Triangle(isMe),
    );

    var positioned = isMe!
        ? Positioned(right: 15, top: 30, child: triangle)
        : Positioned(left: 15, top: 30, child: triangle);

    final bool seen = getSeenStatus(SeenProvider.of(context).value);
    final bg = isMe! ? Colors.blue[400] : Colors.blue[200];
    final mAlign = isMe! ? MainAxisAlignment.end : MainAxisAlignment.start;
    final align = isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    dynamic icon = delivered is bool && delivered
        ? (seen ? Icons.done_all : Icons.done)
        : Icons.access_time;
    final color = isMe! ? Colors.white.withOpacity(0.8) : Colors.black;
    icon = Icon(icon, size: 13.0, color: seen ? Colors.greenAccent : color);
    if (delivered is Future) {
      icon = FutureBuilder(
          future: delivered,
          builder: (context, res) {
            switch (res.connectionState) {
              case ConnectionState.done:
                return Icon((seen ? Icons.done_all : Icons.done),
                    size: 13.0, color: seen ? Colors.greenAccent : color);
              case ConnectionState.none:
              case ConnectionState.active:
              case ConnectionState.waiting:
              default:
                return Icon(Icons.access_time,
                    size: 13.0, color: seen ? Colors.greenAccent : color);
            }
          });
    }
    dynamic radius = isMe!
        ? BorderRadius.only(
            topLeft: Radius.circular(5.0),
            bottomLeft: Radius.circular(5.0),
            bottomRight: Radius.circular(10.0),
          )
        : BorderRadius.only(
            topRight: Radius.circular(5.0),
            bottomLeft: Radius.circular(10.0),
            bottomRight: Radius.circular(5.0),
          );
    dynamic margin =
        const EdgeInsets.only(left: 15.0, top: 20.0, bottom: 1.5, right: 15.0);
    if (isContinuing!) {
      radius = BorderRadius.all(Radius.circular(5.0));
      margin = const EdgeInsets.fromLTRB(15.0, 1.5, 15.0, 1.5);
    }

    return Stack(children: <Widget>[
      isContinuing! ? Text("") : positioned,
      Row(
        mainAxisAlignment: mAlign,
        crossAxisAlignment: align,
        children: <Widget>[
          Container(
            margin: margin,
            padding: const EdgeInsets.all(8.0),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
            ),
            child: Stack(
              children: <Widget>[
                Padding(
                    padding: child is Container
                        ? EdgeInsets.all(0.0)
                        : EdgeInsets.only(right: isMe! ? 65.0 : 50.0),
                    child: child),
                Positioned(
                  bottom: 0.0,
                  right: 0.0,
                  child: Row(
                    children: <Widget>[
                      Text(humanReadableTime().toString() + (isMe! ? ' ' : ''),
                          style: TextStyle(
                            color: color,
                            fontSize: 10.0,
                          )),
                      isMe! ? icon : null
                    ].where((o) => o != null).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ]);
  }
}

class Triangle extends CustomPainter {
  Triangle(this.isMe);
  final isMe;
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = isMe ? Colors.blue[400]! : Colors.blue[200]!;

    var path = Path();
    path.lineTo(-10, -10);
    path.lineTo(10, -10);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
