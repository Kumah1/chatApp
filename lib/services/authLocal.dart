import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kumchat/PassCode/passcode_screen.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authenticate extends StatefulWidget {
  final String? answer, question, passcode, phoneNo, caption;
  final SharedPreferences? prefs;
  final NavigatorState? state;
  final DataModel? model;
  final Function? onSuccess;
  final AuthenticationType? type;
  final bool? shouldPop;
  Authenticate(
      {@required this.type,
      @required this.answer,
      @required this.model,
      @required this.question,
      @required this.passcode,
      @required this.prefs,
      @required this.phoneNo,
      @required this.state,
      @required this.caption,
      @required this.onSuccess,
      @required this.shouldPop});

  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  late int passcodeTries;

  @override
  void initState() {
    super.initState();
    passcodeTries = widget.prefs!.getInt(PASSCODE_TRIES) ?? 0;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (passcodeVisible()) {
        widget.type == AuthenticationType.passcode
            ? _showLockScreen()
            : _biometricAuthentication();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (!passcodeVisible())
      child = Material(
          color: Colors.grey,
          child: Center(
              child: Text(
            'Try again later.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          )));
    else {
      child = Container();
    }
    return Utils.getNTPWrappedWidget(child);
  }

  bool passcodeVisible() {
    int lastAttempt = widget.prefs!.getInt(LAST_ATTEMPT) ??
        DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch;
    DateTime lastTried = DateTime.fromMillisecondsSinceEpoch(lastAttempt);
    return (passcodeTries <= 3 ||
        DateTime.now().isAfter(lastTried
            .add(Duration(minutes: math.pow(2, passcodeTries - 3) as int))));
  }

  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();

  _onPasscodeEntered(String enteredPasscode) {
    if (enteredPasscode.length == 4) {
      bool isValid = Utils.getHashedAnswer(enteredPasscode) == widget.passcode;
      _verificationNotifier.add(isValid);
      if (isValid) {
        widget.prefs!.setInt(PASSCODE_TRIES, 0); // reset tries
        widget.onSuccess!();
      } else {
        passcodeTries += 1;
        widget.prefs!.setInt(PASSCODE_TRIES, passcodeTries);
        widget.prefs!
            .setInt(LAST_ATTEMPT, DateTime.now().millisecondsSinceEpoch);
        if (passcodeTries > 3) {
          Utils.toast('Try after ${math.pow(2, passcodeTries - 3)} minutes');
          Utils.toast('Authentication failed.');
          widget.state!.pop();
        }
      }
    }
  }

  _showLockScreen() {
    widget.state!.pushReplacement(MaterialPageRoute(
      builder: (context) => PasscodeScreen(
          prefs: widget.prefs,
          phoneNo: widget.phoneNo,
          wait: false,
          onSubmit: null,
          authentication: true,
          passwordDigits: 4,
          title: 'Enter the passcode',
          shouldPop: widget.shouldPop!,
          passwordEnteredCallback: _onPasscodeEntered,
          cancelLocalizedText: 'Cancel',
          deleteLocalizedText: 'Delete',
          shouldTriggerVerification: _verificationNotifier.stream,
          question: widget.question,
          answer: widget.answer),
    ));
  }

  _biometricAuthentication() {
    LocalAuthentication()
        .authenticateWithBiometrics(
            localizedReason: widget.caption, useErrorDialogs: true)
        .then((res) {
      if (res == true) {
        if (widget.shouldPop!) widget.state!.pop();
        widget.onSuccess!();
      } else
        Utils.toast('Authentication failed.');
    }).catchError((e) {
      return Future.value(null);
    });
  }
}
