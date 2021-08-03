import 'dart:async';
import 'dart:io';

import 'package:kumchat/PassCode/passcode_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/services/security.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kumchat/Pickers/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatefulWidget {
  final bool? biometricEnabled;
  final AuthenticationType? type;
  Settings({this.biometricEnabled, this.type});
  @override
  State createState() => new SettingsState();
}

class SettingsState extends State<Settings> {
  TextEditingController? controllerNickname;
  TextEditingController? controllerAboutMe;

  SharedPreferences? prefs;

  String phone = '';
  String nickname = '';
  String aboutMe = '';
  String photoUrl = '';

  bool isLoading = false;
  File? avatarImageFile;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();
  AuthenticationType? _type;

  @override
  void initState() {
    super.initState();
    Utils.internetLookUp();
    readLocal();
    _type = widget.type;
  }

  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    phone = prefs!.getString(PHONE) ?? '';
    nickname = prefs!.getString(NICKNAME) ?? '';
    aboutMe = prefs!.getString(ABOUT_ME) ?? '';
    photoUrl = prefs!.getString(PHOTO_URL) ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerAboutMe = new TextEditingController(text: aboutMe);

    // Force refresh input
    setState(() {});
  }

  Future getImage(File image) async {
    if (image != null) {
      setState(() {
        avatarImageFile = image;
      });
    }
    return uploadFile();
  }

  Future uploadFile() async {
    String fileName = phone;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploading = reference.putFile(avatarImageFile);
    return uploading.future.then((value) => value.downloadUrl);
  }

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoading = true;
    });
    nickname =
        controllerNickname!.text.isEmpty ? nickname : controllerNickname!.text;
    aboutMe =
        controllerAboutMe!.text.isEmpty ? aboutMe : controllerAboutMe!.text;
    FirebaseFirestore.instance.collection(USERS).doc(phone).update({
      NICKNAME: nickname,
      ABOUT_ME: aboutMe,
      AUTHENTICATION_TYPE: _type!.index,
    }).then((data) async {
      await prefs!.setString(NICKNAME, nickname);
      await prefs!.setString(ABOUT_ME, aboutMe);
      setState(() {
        isLoading = false;
      });
      Utils.toast("Saved!");
    }).catchError((err) {
      setState(() {
        isLoading = false;
      });

      Utils.toast(err.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(Theme(
        data: ThemeData.light(),
        child: Scaffold(
            backgroundColor: Colors.grey,
            appBar: new AppBar(
              title: new Text(
                'Settings',
              ),
              actions: <Widget>[
                FlatButton(
                  color: Colors.lightBlue[800],
                  textColor: Colors.white,
                  onPressed: handleUpdateData,
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              ],
            ),
            body: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      // Avatar
                      Container(
                        child: Center(
                          child: Stack(
                            children: <Widget>[
                              (avatarImageFile == null)
                                  ? (photoUrl != ''
                                      ? SizedBox(
                                          height: 250,
                                          width: double.infinity,
                                          child: CachedNetworkImage(
                                            imageUrl: photoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Colors.blue),
                                                    ),
                                                    width: 50.0,
                                                    height: 50.0),
                                          ),
                                        )
                                      : Icon(
                                          Icons.account_circle,
                                          size: 250.0,
                                          color: Colors.grey,
                                        ))
                                  : Material(
                                      child: Image.file(
                                        avatarImageFile!,
                                        width: 250.0,
                                        height: 250.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(75.0)),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                              Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: FloatingActionButton(
                                      child: Icon(Icons.camera_alt),
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    HybridImagePicker(
                                                        title: 'Pick an image',
                                                        callback: getImage,
                                                        profile: true))).then(
                                            (url) {
                                          if (url != null) {
                                            photoUrl = url.toString();
                                            FirebaseFirestore.instance
                                                .collection(USERS)
                                                .doc(phone)
                                                .update({
                                              PHOTO_URL: photoUrl
                                            }).then((data) async {
                                              await prefs!.setString(
                                                  PHOTO_URL, photoUrl);
                                              setState(() {
                                                isLoading = false;
                                              });
                                              Utils.toast(
                                                  "Profile Picture Changed!");
                                            }).catchError((err) {
                                              setState(() {
                                                isLoading = false;
                                              });

                                              Utils.toast(err.toString());
                                            });
                                          }
                                        });
                                      })),
                            ],
                          ),
                        ),
                        width: double.infinity,
                        margin: EdgeInsets.all(10.0),
                      ),

                      Container(
                        margin: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 16.0),
                        child: Column(
                          children: <Widget>[
                            Stack(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(16.0),
                                  margin: EdgeInsets.only(top: 16.0),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5.0)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        margin: EdgeInsets.only(left: 96.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              "Profile",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .title,
                                            ),
                                            ListTile(
                                              contentPadding: EdgeInsets.all(0),
                                              title: Text(nickname),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 10.0),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: <Widget>[
                                    Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          image: DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                  photoUrl),
                                              fit: BoxFit.cover)),
                                      margin: EdgeInsets.only(left: 16.0),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 20.0),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Column(
                                children: <Widget>[
                                  ListTile(
                                    title: Text("User information"),
                                  ),
                                  Divider(),
                                  ListTile(
                                    title: Text("Phone"),
                                    subtitle: Text(phone),
                                    leading: Icon(Icons.phone),
                                  ),
                                  Divider(),
                                  ListTile(
                                    title: Text("Change some personal info."),
                                  ),
                                  ListTile(
                                      title: TextFormField(
                                    autovalidateMode: AutovalidateMode.always,
                                    controller: controllerNickname,
                                    validator: (v) {
                                      return v!.isEmpty
                                          ? 'Name cannot be empty!'
                                          : null;
                                    },
                                    decoration: InputDecoration(
                                        labelText: 'Display Name'),
                                  )),
                                  ListTile(
                                      title: TextFormField(
                                    controller: controllerAboutMe,
                                    decoration:
                                        InputDecoration(labelText: 'Status'),
                                  )),
                                  widget.biometricEnabled!
                                      ? Divider()
                                      : Container(width: 0, height: 0),
                                  widget.biometricEnabled!
                                      ? ListTile(
                                          title: Text('Authentication Type'),
                                          subtitle: Row(children: [
                                            Radio(
                                                groupValue: _type,
                                                value:
                                                    AuthenticationType.passcode,
                                                activeColor: Colors.blue,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _type = val
                                                        as AuthenticationType?;
                                                  });
                                                }),
                                            Text('Passcode'),
                                            Radio(
                                                groupValue: _type,
                                                value: AuthenticationType
                                                    .biometric,
                                                activeColor: Colors.blue,
                                                onChanged: (val) {
                                                  setState(() {
                                                    _type = val
                                                        as AuthenticationType?;
                                                  });
                                                }),
                                            Text('Fingerprint')
                                          ]),
                                        )
                                      : Container(width: 0, height: 0),
                                  widget.biometricEnabled!
                                      ? Divider()
                                      : Container(width: 0, height: 0),
                                  ListTile(
                                      title: Row(children: [
                                    Expanded(
                                        child: ElevatedButton.icon(
                                            icon: Icon(Icons.lock),
                                            label: Text('Change Passcode'),
                                            onPressed: _showLockScreen))
                                  ])),
                                  ListTile(
                                      title: Row(children: [
                                    Expanded(
                                        child: ElevatedButton.icon(
                                            icon: Icon(Icons.security),
                                            label: Text(
                                                'Change Security Question'),
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          Security(phone,
                                                              shouldPop: true,
                                                              onSuccess: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                              setPasscode:
                                                                  false)));
                                            }))
                                  ])),
                                  ListTile(
                                      title: TextButton(
                                    child: Text('Privacy Policy',
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline)),
                                    onPressed: () {
                                      launch(PRIVACY_POLICY_URL);
                                    },
                                  ))
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.only(left: 15.0, right: 15.0),
                ),
                // Loading
                Positioned(
                  child: isLoading
                      ? Container(
                          child: Center(
                            child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue)),
                          ),
                          color: Colors.black.withOpacity(0.8),
                        )
                      : Container(),
                ),
              ],
            ))));
  }

  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();

  _onPasscodeEntered(String enteredPasscode) {
    bool isValid = enteredPasscode.length == 4;
    _verificationNotifier.add(isValid);
  }

  _onSubmit(String newPasscode) {
    setState(() {
      isLoading = true;
    });
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(phone)
        .update({PASSCODE: Utils.getHashedString(newPasscode)}).then((_) {
      prefs!.setInt(ANSWER_TRIES, 0);
      prefs!.setInt(PASSCODE_TRIES, 0);
      setState(() {
        isLoading = false;
        Utils.toast('Updated!');
      });
    });
  }

  _showLockScreen() {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              PasscodeScreen(
            onSubmit: _onSubmit,
            wait: true,
            passwordDigits: 4,
            title: 'Enter the passcode',
            passwordEnteredCallback: _onPasscodeEntered,
            cancelLocalizedText: 'Cancel',
            deleteLocalizedText: 'Delete',
            shouldTriggerVerification: _verificationNotifier.stream,
          ),
        ));
  }
}
