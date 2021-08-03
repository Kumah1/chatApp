import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/screens/chat.dart';

class PreChat extends StatefulWidget {
  final String? name, phone, currentUserNo;
  final DataModel? model;
  const PreChat(
      {@required this.name,
      @required this.phone,
      @required this.currentUserNo,
      @required this.model});

  @override
  _PreChatState createState() => _PreChatState();
}

class _PreChatState extends State<PreChat> {
  bool? isLoading, isUser = false;

  @override
  initState() {
    super.initState();
    getUser();
    isLoading = true;
  }

  getUser() {
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(widget.phone)
        .get()
        .then((user) {
      setState(() {
        isLoading = false;
        isUser = user.exists;
        if (isUser!) {
          var peer = user;
          widget.model!.addUser(user);
          Navigator.pushReplacement(
              context,
              new MaterialPageRoute(
                  builder: (context) => new ChatScreen(
                      unread: 0,
                      currentUserNo: widget.currentUserNo,
                      model: widget.model,
                      peerNo: peer[PHONE])));
        }
      });
    });
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading!
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
              ),
              color: Colors.black.withOpacity(0.8),
            )
          : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue, title: Text(widget.name!)),
      body: Stack(children: <Widget>[
        Container(
            child: Center(
          child: !isUser!
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(widget.name! + " is not on KumChat!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0)),
                  SizedBox(
                    height: 20.0,
                  ),
                  RaisedButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    child: Text('Invite ${widget.name}'),
                    onPressed: () {
                      Utils.invite();
                    },
                  )
                ])
              : Container(),
        )),
        // Loading
        buildLoading()
      ]),
      backgroundColor: Colors.white,
    ));
  }
}
