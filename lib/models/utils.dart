import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kumchat/models/const.dart';
import 'package:ntp/ntp.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share/share.dart';

import 'DataModel.dart';

class Utils {
  static Future<bool> checkAndRequestPermission(Permission permission) async {
    Completer<bool> completer = new Completer<bool>();
    final status = await permission.request();
    if (status != PermissionStatus.granted) {
      PermissionStatus _status = await permission.request();
      bool granted = _status.isGranted;
      completer.complete(granted);
    } else
      completer.complete(true);

    return completer.future;
  }

  static Future<int> getNTPOffset() {
    return NTP.getNtpOffset();
  }

  static String getNickname(Map<String, dynamic> user) =>
      user[ALIAS_NAME] ?? user[NICKNAME];

  static Widget avatar(Map<String, dynamic> user,
      {File? image, double radius = 22.5}) {
    if (image == null) {
      if (user[ALIAS_AVATAR] == null)
        return (user[PHOTO_URL] == "" || user[PHOTO_URL] == ' ')
            ? CircleAvatar(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: Text(getInitials(getNickname(user))),
                radius: radius,
              )
            : CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user[PHOTO_URL]),
                radius: radius);
      return CircleAvatar(
        backgroundImage: Image.file(File(user[ALIAS_AVATAR])).image,
        radius: radius,
      );
    }
    return CircleAvatar(
        backgroundImage: Image.file(image).image, radius: radius);
  }

  static String getInitials(String name) {
    try {
      List<String> names = name
          .trim()
          .replaceAll(new RegExp(r'[\W]'), '')
          .toUpperCase()
          .split(' ');
      names.retainWhere((s) => s.trim().isNotEmpty);
      if (names.length >= 2)
        return names.elementAt(0)[0] + names.elementAt(1)[0];
      else if (names.elementAt(0).length >= 2)
        return names.elementAt(0).substring(0, 2);
      else
        return names.elementAt(0)[0];
    } catch (e) {
      return '?';
    }
  }

  static Widget getNTPWrappedWidget(Widget child) {
    return FutureBuilder(
        future: NTP.getNtpOffset(),
        builder: (context, AsyncSnapshot<int> snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            if (snapshot.data! > Duration(minutes: 1).inMilliseconds ||
                snapshot.data! < -Duration(minutes: 1).inMilliseconds)
              return Material(
                  color: new Color(0xFF1E1E1E),
                  child: Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 30.0),
                          child: Text(
                            "Your clock time is out of sync with the server time. Please set it right to continue.",
                            style: TextStyle(
                                color: new Color(0xFFE0E0E0), fontSize: 18),
                          ))));
          }
          return child;
        });
  }

  static void showRationale(rationale) async {
    Utils.toast(rationale);
    await Future.delayed(Duration(seconds: 2));
    Utils.toast(
        'If you change your mind, you can grant the permission through App Settings > Permissions');
  }

  static void toast(String message) {
    Fluttertoast.showToast(
        msg: message,
        backgroundColor: new Color(0xFF1E1E1E).withOpacity(0.95),
        textColor: new Color(0xFFE0E0E0));
  }

  static void internetLookUp() {
    try {
      InternetAddress.lookup('example.com').catchError((e) {
        Utils.toast('No internet connection.');
      });
    } catch (_) {
      Utils.toast('No internet connection.');
    }
  }

  static AuthenticationType getAuthenticationType(
      bool biometricEnabled, DataModel model) {
    if (biometricEnabled && model.currentUser != null) {
      return AuthenticationType.values[model.currentUser![AUTHENTICATION_TYPE]];
    }
    return AuthenticationType.passcode;
  }

  static String getChatId(String currentUserNo, String peerNo) {
    if (currentUserNo.hashCode <= peerNo.hashCode)
      return '$currentUserNo-$peerNo';
    return '$peerNo-$currentUserNo';
  }

  static ChatStatus getChatStatus(int index) => ChatStatus.values[index];

  static String normalizePhone(String phone) =>
      phone.replaceAll(new RegExp(r"\s+\b|\b\s"), "");

  static String getHashedAnswer(String answer) {
    answer = answer.toLowerCase().replaceAll(new RegExp(r"[^a-z0-9]"), "");
    var bytes = utf8.encode(answer); // data being hashed
    Digest digest = sha1.convert(bytes);
    return digest.toString();
  }

  static String getHashedString(String str) {
    var bytes = utf8.encode(str); // data being hashed
    Digest digest = sha1.convert(bytes);
    return digest.toString();
  }

  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    // Print the exception to the console
    print('Caught error: $error');

    // Print the full stacktrace in debug mode
    print(stackTrace);
  }

  static void invite() {
    Share.share(
        'Let\'s chat on KumChat, join me at - https://play.google.com/store/apps/details?id=com.kumah.kumchat');
  }
}
