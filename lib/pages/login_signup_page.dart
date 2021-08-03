/*
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kumchat/models/user_model.dart';
import 'package:kumchat/screens/home_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/services/authentication.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginSignupPage extends StatefulWidget {
  LoginSignupPage({this.auth, this.loginCallback,this.logoutCallback,this.cameras});

  final BaseAuth auth;
  final VoidCallback loginCallback;
  final VoidCallback logoutCallback;
  String username;
  final List<CameraDescription> cameras;
  //String _userId;

  @override
  State<StatefulWidget> createState() => new _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {

  final TextEditingController nameController = new TextEditingController();
  final _formKey = new GlobalKey<FormState>();


  String _email;
  String _password;
  String _errorMessage;

  bool _isLoginForm;
  bool _isLoading;

  User item;
  final reference = FirebaseDatabase.instance.reference();

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId;
      try {
        if (_isLoginForm) {
          userId = await widget.auth.signIn(_email, _password);
        } else {
          userId = await widget.auth.signUp(_email, _password);
          await reference.child('Users').child(userId).set(item.toJson(userId,widget.username));
          Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(
            userId: userId,
            auth: widget.auth,
            logoutCallback: widget.logoutCallback,
            cameras: widget.cameras,
          )));
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null && _isLoginForm) {
          widget.loginCallback();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
          _formKey.currentState.reset();
        });
      }
    }
  }

  @override
  void initState() {
    item = User("","","","","","","",);
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;
    super.initState();

  }

  void resetForm() {
    _formKey.currentState.reset();
    _errorMessage = "";
  }

  void toggleFormMode() {
    resetForm();
    setState(() {
      widget.username = nameController.text.trim();
      _isLoginForm = !_isLoginForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: Center(child: new Text('KumChat')),
        ),
        body: Stack(
          children: <Widget>[
            _showForm(),
            _showCircularProgress(),
          ],
        ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      SnackBar(content: new Text("Please wait some few seconds it will complete"));
      return Center(child: CircularProgressIndicator(
        backgroundColor: Colors.red,
      ));

    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

//  void _showVerifyEmailSentDialog() {
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        // return object of type Dialog
//        return AlertDialog(
//          title: new Text("Verify your account"),
//          content:
//              new Text("Link to verify account has been sent to your email"),
//          actions: <Widget>[
//            new FlatButton(
//              child: new Text("Dismiss"),
//              onPressed: () {
//                toggleFormMode();
//                Navigator.of(context).pop();
//              },
//            ),
//          ],
//        );
//      },
//    );
//  }

  Widget _showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              showLogo(),
              showGoogleSignIn(),
              showEmailInput(),
              showPasswordInput(),
              showPrimaryButton(),
              showSecondaryButton(),
              showErrorMessage(),
            ],
          ),
        ));
  }

  Widget showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 72.0,
          child: Image.asset('assets/kumchat2.png'),
        ),
      ),
    );
  }
  Widget showGoogleSignIn(){
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
      child: OutlineButton.icon(
        borderSide: BorderSide(
          color: Colors.red,
        ),
          textColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          icon: Icon(FontAwesomeIcons.google,color: Colors.red,),
          label: Text("SignIn with Google",style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
          onPressed: ()async{
            final user = await Auth().loginWithGoogle();
            reference.child('Users').child(user.uid).set(item.toJson(user.uid,user.displayName));
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(
              userId: user.uid,
              auth: widget.auth,
              logoutCallback: widget.logoutCallback,
            )));

          }
              /*()=> Auth().loginWithGoogle()
              .then((user){
            reference.child('Users').child(user.uid).set(item.toJson(user.uid,widget.username));
            return HomeScreen(
              userId: user.uid,
              auth: widget.auth,
              logoutCallback: widget.logoutCallback,
          );
              }).catchError((e)=>print(e)),

               */
      ),
    );
  }

  Widget showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 50.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value.trim(),
      ),
    );
  }

  Widget showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: Column(
        children: <Widget>[
          new TextFormField(
            maxLines: 1,
            obscureText: true,
            autofocus: false,
            decoration: new InputDecoration(
                hintText: 'Password',
                icon: new Icon(
                  Icons.lock,
                  color: Colors.grey,
                )),
            validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
            onSaved: (value) => _password = value.trim(),
          ),
          !_isLoginForm ? new TextFormField(
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.text,
            controller: nameController,
            decoration: InputDecoration(
                icon: new Icon(
                  Icons.person,
                  color: Colors.grey,
                ),
                labelText: "Your Username"
            ),
            validator: (val) {
              widget.username = val.trim();
              if(val.isEmpty) {
                return "this field cannot be empty";
              }
            },
          )
              : Text('')
        ],
      ),
    );
  }

  Widget showSecondaryButton() {
    return new FlatButton(
        child: new Text(
            _isLoginForm ? 'Create an account' : 'Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: toggleFormMode);
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            color: Colors.blue,
            child: new Text(_isLoginForm ? 'Login' : 'Create account',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: validateAndSubmit,
          ),
        ));
  }
}

 */
