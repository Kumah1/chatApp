import 'package:flutter/material.dart';
import 'package:kumchat/seen_provider.dart';

class Message {
  Message(Widget child,
      {@required this.timestamp,
      @required this.from,
      @required this.onTap,
      @required this.onDismiss,
      @required this.onLongPress,
      this.saved = false})
      : child = wrapMessage(
            child: child,
            onDismiss: onDismiss,
            onTap: onTap,
            onLongPress: onLongPress,
            saved: saved);

  final String? from;
  final Widget? child;
  final int? timestamp;
  final VoidCallback? onTap, onDismiss, onLongPress;
  final bool? saved;
  static Widget wrapMessage(
      {@required Widget? child,
      @required onDismiss,
      @required onTap,
      @required onLongPress,
      @required bool? saved}) {
    return GestureDetector(
      child: child,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
