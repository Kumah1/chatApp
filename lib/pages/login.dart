import 'dart:async';

import 'package:camera/camera.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/screens/home_screen.dart';
import 'package:kumchat/services/security.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kumchat/CountryPicker/country_picker.dart';
import 'package:kumchat/models/utils.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kumchat/E2EE/e2ee.dart' as e2ee;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/const.dart';

// ignore: must_be_immutable
class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, required this.title, required this.cameras})
      : super(key: key);

  final String title;
  final List<CameraDescription> cameras;
  late DataModel model;

  @override
  LoginScreenState createState() => new LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  late SharedPreferences prefs;
  final _phoneNo = TextEditingController();
  final _smsCode = TextEditingController();
  final _name = TextEditingController();
  String phoneCode = '+233';
  final storage = new FlutterSecureStorage();

  Country _selected = Country(
    asset: "assets/flags/gh_flag.png",
    dialingCode: "233",
    isoCode: "GH",
    name: "Ghana",
  );
  int _currentStep = 0;

  String verificationId = "";
  bool isLoading = false;
  dynamic isLoggedIn = false;
  late User currentUser;

  @override
  void initState() {
    super.initState();
  }

  Future<void> verifyPhoneNumber() async {
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      handleSignIn(authCredential: phoneAuthCredential);
    };

    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      Utils.reportError(
          '${authException.message} Phone: ${_phoneNo.text} Country Code: $phoneCode ',
          authException.code);
      setState(() {
        isLoading = false;
      });

      Utils.toast(
          'Authentication failed - ${authException.message}. Try again later.');
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      setState(() {
        isLoading = false;
      });

      this.verificationId = verificationId;
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      setState(() {
        isLoading = false;
      });

      this.verificationId = verificationId;
    };

    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: (phoneCode + _phoneNo.text).trim(),
        timeout: const Duration(minutes: 2),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
  }

  Future<Null> handleSignIn({AuthCredential? authCredential}) async {
    prefs = await SharedPreferences.getInstance();
    if (isLoading == false) {
      this.setState(() {
        isLoading = true;
      });
    }

    var phoneNo = (phoneCode + _phoneNo.text).trim();

    AuthCredential credential;
    if (authCredential == null)
      credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _smsCode.text,
      );
    else
      credential = authCredential;
    User firebaseUser;
    try {
      firebaseUser = (await firebaseAuth
              .signInWithCredential(credential)
              .catchError((err) async {
        await Utils.reportError(err, 'signInWithCredential');
        Utils.toast(
            'Make sure your Phone Number/OTP Code is correct and try again later.');
        if (mounted)
          setState(() {
            _currentStep = 0;
          });
        // return;
      }))
          .user;
    } catch (e) {
      await Utils.reportError(e, 'signInWithCredential catch block');
      Utils.toast(
          'Make sure your Phone Number/OTP Code is correct and try again later.');
      if (mounted)
        setState(() {
          _currentStep = 0;
        });
      return;
    }

    if (firebaseUser != null) {
      // Check is already sign up
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection(USERS)
          .where(ID, isEqualTo: firebaseUser.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      final pair = await e2ee.X25519().generateKeyPair();
      await storage.write(key: PRIVATE_KEY, value: pair.secretKey!.toBase64());
      if (documents.isEmpty) {
        // Update data to server if new user
        await FirebaseFirestore.instance.collection(USERS).doc(phoneNo).set({
          PUBLIC_KEY: pair.publicKey!.toBase64(),
          COUNTRY_CODE: phoneCode,
          NICKNAME: _name.text.trim(),
          PHOTO_URL: " ",
          ID: firebaseUser.uid,
          PHONE: phoneNo,
          AUTHENTICATION_TYPE: AuthenticationType.passcode.index,
          ABOUT_ME: ''
        });

        // Write data to local
        currentUser = firebaseUser;
        await prefs.setString(ID, currentUser.uid);
        await prefs.setString(NICKNAME, _name.text.trim());
        await prefs.setString(PHOTO_URL, currentUser.photoURL);
        await prefs.setString(PHONE, phoneNo);
        await prefs.setString(COUNTRY_CODE, phoneCode);
        unawaited(Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Security(phoneNo, setPasscode: true, onSuccess: () async {
                unawaited(Navigator.pushReplacement(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => HomeScreen(
                            model: widget.model,
                            userId: firebaseUser.uid,
                            phone: phoneNo,
                            cameras: widget.cameras,
                            countryCode: phoneCode))));
                Utils.toast('Welcome to KumChat!');
              }),
            )));
      } else {
        // Always set the authentication type to passcode while signing in
        // so they would have to set up fingerprint only after going through
        // passcode first.
        // This prevents using fingerprint of other users as soon as logging in.
        FirebaseFirestore.instance.collection(USERS)
          ..doc(phoneNo)
          ..add({
            AUTHENTICATION_TYPE: AuthenticationType.passcode.index,
            PUBLIC_KEY: pair.publicKey!.toBase64()
          });
        // Write data to local
        await prefs.setString(ID, documents[0][ID]);
        await prefs.setString(NICKNAME, documents[0][NICKNAME]);
        await prefs.setString(PHOTO_URL, documents[0][PHOTO_URL]);
        await prefs.setString(ABOUT_ME, documents[0][ABOUT_ME] ?? '');
        await prefs.setString(PHONE, documents[0][PHONE]);
        unawaited(Navigator.pushReplacement(
            context,
            new MaterialPageRoute(
                builder: (context) => HomeScreen(
                    model: widget.model,
                    userId: firebaseUser.uid,
                    phone: phoneNo,
                    cameras: widget.cameras,
                    countryCode: phoneCode))));
        Utils.toast('Welcome back!');
      }
    } else {
      Utils.toast("Failed to log in.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            widget.title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: new Stepper(
                controlsBuilder: (BuildContext context,
                    {VoidCallback? onStepContinue,
                    VoidCallback? onStepCancel}) {
                  return Row();
                },
                onStepTapped: (int step) => setState(() => _currentStep = step),
                type: StepperType.vertical,
                currentStep: _currentStep,
                steps: <Step>[
                  new Step(
                    title: Text('Phone Code'),
                    content: Row(children: <Widget>[
                      CountryPicker(
                        onChanged: (Country country) {
                          setState(() {
                            _selected = country;
                            phoneCode = '+' + country.dialingCode!;
                          });
                        },
                        selectedCountry: _selected,
                      ),
                      SizedBox(width: 16.0),
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.blue),
                              textStyle: MaterialStateProperty.all(
                                  TextStyle(color: Colors.white)),
                              padding: MaterialStateProperty.all(
                                  EdgeInsets.all(8.0))),
                          onPressed: () {
                            setState(() {
                              _currentStep += 1;
                            });
                          },
                          child: Text('Next')),
                    ]),
                    isActive: _currentStep >= 0,
                    state: _currentStep >= 0
                        ? StepState.complete
                        : StepState.disabled,
                  ),
                  new Step(
                    title: Text('Personal Information'),
                    content: Column(
                      children: <Widget>[
                        TextField(
                          controller: _name,
                          keyboardType: TextInputType.text,
                          decoration:
                              InputDecoration(labelText: 'Display name'),
                        ),
                        TextField(
                          controller: _phoneNo,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              helperText: 'Enter only the numbers.',
                              prefixText: phoneCode + ' ',
                              labelText: 'Phone No.'),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10.0),
                          child: Row(children: <Widget>[
                            ElevatedButton(
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      EdgeInsets.all(8.0)),
                                  textStyle: MaterialStateProperty.all(
                                      TextStyle(color: Colors.white)),
                                  backgroundColor: MaterialStateProperty.all(
                                    Colors.blue,
                                  ),
                                ),
                                onPressed: () {
                                  RegExp e164 =
                                      new RegExp(r'^\+[1-9]\d{1,14}$');
                                  if (_name.text.trim().isNotEmpty) {
                                    String _phone =
                                        _phoneNo.text.toString().trim();
                                    if (_phone.isNotEmpty &&
                                        e164.hasMatch(phoneCode + _phone)) {
                                      verifyPhoneNumber();
                                      setState(() {
                                        isLoading = true;
                                        _currentStep += 1;
                                      });
                                    } else {
                                      Utils.toast(
                                          'Please enter a valid number.');
                                    }
                                  } else {
                                    Utils.toast('Name cannot be empty!');
                                  }
                                },
                                child: Text('Next')),
                            SizedBox(width: 8.0),
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                    textStyle: MaterialStateProperty.all(
                                        TextStyle(color: Colors.black)),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(8.0))),
                                onPressed: () {
                                  setState(() {
                                    _currentStep -= 1;
                                  });
                                },
                                child: Text('Back')),
                          ]),
                        )
                      ],
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep >= 1
                        ? StepState.complete
                        : StepState.disabled,
                  ),
                  new Step(
                    title: Text('Verify OTP'),
                    content: Column(children: <Widget>[
                      TextField(
                        maxLength: 6,
                        controller: _smsCode,
                        decoration: InputDecoration(labelText: 'OTP Code'),
                        keyboardType: TextInputType.number,
                      ),
                      TextButton(
                        style: ButtonStyle(
                            padding:
                                MaterialStateProperty.all(EdgeInsets.zero)),
                        child: Text.rich(TextSpan(
                            text: 'By clicking Next, you are accepting our ',
                            children: [
                              TextSpan(
                                  text: 'Privacy Policy.',
                                  style: TextStyle(
                                      decoration: TextDecoration.underline))
                            ])),
                        onPressed: () {
                          launch(PRIVACY_POLICY_URL);
                        },
                      ),
                      Container(
                          margin: const EdgeInsets.only(top: 10.0),
                          child: Row(children: <Widget>[
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.blue),
                                    textStyle: MaterialStateProperty.all(
                                        TextStyle(color: Colors.white)),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(8.0))),
                                onPressed: () {
                                  if (_smsCode.text.length == 6) {
                                    handleSignIn();
                                  } else
                                    Utils.toast(
                                        'Please enter the correct OTP Code');
                                },
                                child: Text('Next')),
                            SizedBox(width: 8.0),
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all(Colors.white),
                                    textStyle: MaterialStateProperty.all(
                                        TextStyle(color: Colors.black)),
                                    padding: MaterialStateProperty.all(
                                        EdgeInsets.all(8.0))),
                                onPressed: () {
                                  setState(() {
                                    _currentStep -= 1;
                                  });
                                },
                                child: Text('Back')),
                          ]))
                    ]),
                    isActive: _currentStep >= 0,
                    state: _currentStep >= 2
                        ? StepState.complete
                        : StepState.disabled,
                  ),
                ],
              ),
            ),

            // Loading
            Positioned(
              child: isLoading
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      color: Colors.grey.withOpacity(0.8),
                    )
                  : Container(),
            ),
          ],
        ),
      ),
      data: ThemeData.light(),
    );
  }
}
