
import 'package:flutter/material.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';


class ProfileView extends StatelessWidget {
  final Map<String, dynamic> user;
  ProfileView(this.user);

  @override
  Widget build(BuildContext context) {
    final _width = MediaQuery.of(context).size.width;
    final _height = MediaQuery.of(context).size.height;
    String name = Utils.getNickname(user), about = user[ABOUT_ME] ?? '';
    return Utils.getNTPWrappedWidget(Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.blue,
        ),
        body: Center(
            child: Column(
          children: <Widget>[
            SizedBox(
              height: _height / 8,
            ),
            Utils.avatar(user, radius: 100.0),
            Padding(
              child: new Text(
                name,
                style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: _width / 10,
                    color: Colors.black),
              ),
              padding: EdgeInsets.only(top: 20),
            ),
            new Padding(
              padding: new EdgeInsets.only(top: 10),
              child: new Text(
                about.isEmpty ? 'This user is quite secretive!' : about,
                style: new TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: _width / 25,
                    color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ))));
  }
}
