import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/services/authLocal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatController {
  static request(currentUserNo, peerNo) {
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(currentUserNo)
        .collection(CHATS_WITH)
        .doc(CHATS_WITH)
        .set({'$peerNo': ChatStatus.waiting.index}, SetOptions(merge: true));
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(peerNo)
        .collection(CHATS_WITH)
        .doc(CHATS_WITH)
        .set({'$currentUserNo': ChatStatus.requested.index},
            SetOptions(merge: true));
  }

  static accept(currentUserNo, peerNo) {
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(currentUserNo)
        .collection(CHATS_WITH)
        .doc(CHATS_WITH)
        .set({'$peerNo': ChatStatus.accepted.index}, SetOptions(merge: true));
  }

  static block(currentUserNo, peerNo) {
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(currentUserNo)
        .collection(CHATS_WITH)
        .doc(CHATS_WITH)
        .set({'$peerNo': ChatStatus.blocked.index}, SetOptions(merge: true));
    FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(Utils.getChatId(currentUserNo, peerNo))
        .set({'$currentUserNo': DateTime.now().millisecondsSinceEpoch},
            SetOptions(merge: true));
    Utils.toast('Blocked.');
  }

  static Future<ChatStatus> getStatus(currentUserNo, peerNo) async {
    var doc = await FirebaseFirestore.instance
        .collection(USERS)
        .doc(currentUserNo)
        .collection(CHATS_WITH)
        .doc(CHATS_WITH)
        .get();
    return ChatStatus.values[doc[peerNo]];
  }

  static hideChat(currentUserNo, peerNo) {
    FirebaseFirestore.instance.collection(USERS).doc(currentUserNo).set({
      HIDDEN: FieldValue.arrayUnion([peerNo])
    }, SetOptions(merge: true));
    Utils.toast('Chat hidden.');
  }

  static unhideChat(currentUserNo, peerNo) {
    FirebaseFirestore.instance.collection(USERS).doc(currentUserNo).set({
      HIDDEN: FieldValue.arrayRemove([peerNo])
    }, SetOptions(merge: true));
    Utils.toast('Chat is visible.');
  }

  static lockChat(currentUserNo, peerNo) {
    FirebaseFirestore.instance.collection(USERS).doc(currentUserNo).set({
      LOCKED: FieldValue.arrayUnion([peerNo])
    }, SetOptions(merge: true));
    Utils.toast('Chat locked.');
  }

  static unlockChat(currentUserNo, peerNo) {
    FirebaseFirestore.instance.collection(USERS).doc(currentUserNo).set({
      LOCKED: FieldValue.arrayRemove([peerNo])
    }, SetOptions(merge: true));
    Utils.toast('Chat unlocked.');
  }

  static void authenticate(DataModel model, String caption,
      {@required NavigatorState? state,
      AuthenticationType type = AuthenticationType.passcode,
      @required SharedPreferences? prefs,
      @required Function? onSuccess,
      @required bool? shouldPop}) {
    Map<String, dynamic> user = model.currentUser!;
    if (user != null && model != null) {
      state!.push(MaterialPageRoute<bool>(
          builder: (context) => Authenticate(
              shouldPop: shouldPop,
              caption: caption,
              type: type,
              model: model,
              state: state,
              answer: user[ANSWER],
              passcode: user[PASSCODE],
              question: user[QUESTION],
              phoneNo: user[PHONE],
              prefs: prefs,
              onSuccess: onSuccess)));
    }
  }
}
