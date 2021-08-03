import 'dart:async';

import 'package:app_review/app_review.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:kumchat/alias.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/contacts.dart';
import 'package:kumchat/models/network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/screens/chat.dart';
import 'package:kumchat/screens/status_screen.dart';
import 'package:kumchat/services/appInfo.dart';
import 'package:kumchat/services/authentication.dart';
import 'package:flutter/widgets.dart';
import 'package:kumchat/settings.dart' as AppSettings;
import 'package:kumchat/src/pages/index.dart';
import 'package:kumchat/src/pages/multichannel.dart';
import 'package:kumchat/utils/audioPlayer.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rating_dialog/rating_dialog.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/services/chat_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  final BaseAuth? auth;
  final DataModel? model;
  final VoidCallback? logoutCallback;
  final String? userId;
  final String? phone;
  final String? countryCode;
  List<CameraDescription> cameras = [];
  HomeScreen(
      {Key? key,
      this.auth,
      this.model,
      this.countryCode,
      required this.phone,
      this.userId,
      this.logoutCallback,
      required this.cameras})
      : super(key: key);
  static HomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeScreenState>();
  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  HomeScreenState() {
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }
  TabController? _tabController;
  bool showFab = true, biometricEnabled = false;

  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  static DateTime now = DateTime.now();
  String formattedDate = DateFormat('HH:mm').format(now);

  String image =
      "https://firebasestorage.googleapis.com/v0/b/f-kumchat.appspot."
      "com/o/kumchat2.png?alt=media&token=507a3cb6-0621-488a-8597-28502a9feedc";

  SharedPreferences? prefs;

  DataModel? _cachedModel;

  var fireBaseSubscription;
  FirebaseDatabase? database;

  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;
  bool showHidden = false;
  StreamSubscription? spokenSubscription;
  List<StreamSubscription> unreadSubscriptions = [];

  List<StreamController> controllers = [];
  FirebaseMessaging notifications = FirebaseMessaging.instance;

  DataModel? model;

  @override
  void initState() {
    getPrefs();
    model = new DataModel(widget.phone!);
    Utils.internetLookUp();
    database = FirebaseDatabase.instance;
    WidgetsBinding.instance!.addObserver(this);
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 1, length: 5);
    _tabController!.addListener(() {
      if (_tabController!.index == 1) {
        showFab = true;
      } else {
        showFab = false;
      }
      setState(() {});
    });
    //getSignInUser();
    LocalAuthentication().canCheckBiometrics.then((res) {
      if (res) biometricEnabled = true;
    });
    getSUserNotification();
  }

  getPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  getSUserNotification() async {
    setIsActive();
    String fcmToken = await notifications.getToken();
    if (prefs!.getBool(IS_TOKEN_GENERATED) != true) {
      await FirebaseFirestore.instance.collection(USERS).doc(widget.phone).set({
        NOTIFICATION_TOKENS: FieldValue.arrayUnion([fcmToken])
      }, SetOptions(merge: true));
      unawaited(prefs!.setBool(IS_TOKEN_GENERATED, true));
    }
  }

  @override
  void dispose() {
    _userQuery.close();
    _filter.dispose();
    offlineTime(formattedDate);
    WidgetsBinding.instance!.removeObserver(this);
    controllers.forEach((controller) {
      controller.close();
    });
    cancelUnreadSubscriptions();
    setLastSeen();
    super.dispose();
  }

  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription.cancel();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setIsActive();
    } else {
      setLastSeen();
    }
  }

  void offlineTime(String offTime) async {
    var st = {'offlineTime': offTime};
    await database!.reference().child("Users").child(widget.userId).update(st);
  }

  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('KumChat',
      style: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
      ));

  void _searchPressed() {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          autofocus: true,
          style: TextStyle(color: Colors.white),
          controller: _filter,
          decoration: new InputDecoration(
              hintText: 'Search ', hintStyle: TextStyle(color: Colors.white)),
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('KumChat',
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
            ));

        _filter.clear();
      }
    });
  }

  DataModel getModel() {
    _cachedModel ??= DataModel(widget.phone!);
    return _cachedModel!;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Tab>[
      Tab(icon: Icon(Icons.camera_alt)),
      Tab(
        icon: Icon(Icons.chat),
      ),
      Tab(
        icon: Icon(Icons.person_outline),
      ),
      Tab(icon: Icon(Icons.group)),
      Tab(icon: Icon(Icons.video_call)),
    ];

    return Utils.getNTPWrappedWidget(
      WillPopScope(
        onWillPop: () {
          offlineTime(formattedDate);
          return Future.value(true);
        },
        child: ScopedModel<DataModel>(
          model: new DataModel(widget.phone!),
          child: ScopedModelDescendant<DataModel>(
              builder: (context, child, _model) {
            _cachedModel = _model;
            return DefaultTabController(
                length: tabs.length,
                child: Scaffold(
                  key: _key,
                  appBar: AppBar(
                    backgroundColor: Theme.of(context).primaryColor,
                    leading: IconButton(
                      icon: Icon(Icons.menu),
                      iconSize: 30.0,
                      color: Colors.white,
                      onPressed: () {
                        _key.currentState!.openDrawer();
                      },
                    ),
                    title: Center(
                      child: _appBarTitle,
                    ),
                    elevation: 0.0,
                    actions: <Widget>[
                      IconButton(
                        icon: _searchIcon,
                        onPressed: _searchPressed,
                      ),
                      IconButton(
                        icon: Icon(Icons.settings),
                        onPressed: () {
                          ChatController.authenticate(_cachedModel!,
                              'Authentication needed to unlock the Settings',
                              state: Navigator.of(context),
                              shouldPop: false,
                              type: Utils.getAuthenticationType(
                                  biometricEnabled, _cachedModel!),
                              prefs: prefs!, onSuccess: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AppSettings.Settings(
                                          biometricEnabled: biometricEnabled,
                                          type: Utils.getAuthenticationType(
                                              biometricEnabled, _cachedModel!),
                                        )));
                          });
                        },
                      ),
                    ],
                    bottom: TabBar(controller: _tabController, tabs: tabs),
                  ),
                  drawer: _buildDrawer(),
                  body:
                      TabBarView(controller: _tabController, children: <Widget>[
                    CameraExampleHome(widget.cameras),
                    _chats(_model.userData, _model.currentUser!),
                    StatusScreen(),
                    // AudioPlayerWidget(
                    //   audioURL:
                    //       "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
                    //   isMe: false,
                    // ),
                    MultiChannel(),
                  ]),
                  floatingActionButton: showFab
                      ? FloatingActionButton(
                          backgroundColor: Theme.of(context).accentColor,
                          child: Icon(
                            Icons.message,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            Navigator.push(
                                context,
                                new MaterialPageRoute(
                                    builder: (context) => new Contacts(
                                          currentUserNo: widget.phone,
                                          model: _model,
                                          biometricEnabled: biometricEnabled,
                                          prefs: prefs,
                                        )));
                          })
                      : null,
                ));
          }),
        ),
      ),
    );
  }

  void setIsActive() async {
    if (widget.phone != null)
      await FirebaseFirestore.instance
          .collection(USERS)
          .doc(widget.phone)
          .set({LAST_SEEN: true}, SetOptions(merge: true));
  }

  void setLastSeen() async {
    if (widget.phone != null)
      await FirebaseFirestore.instance.collection(USERS).doc(widget.phone).set(
          {LAST_SEEN: DateTime.now().millisecondsSinceEpoch},
          SetOptions(merge: true));
  }

  // ignore: always_declare_return_types
  _buildDrawer() {
    return SafeArea(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Center(
                  child: Text(
                "Basic Information",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40.0,
                  fontWeight: FontWeight.bold,
                ),
              )),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            SizedBox(
              height: 80.0,
            ),
            ListTile(
              title: Text("Rate"),
              leading: Icon(Icons.stars),
              onTap: () => _rate(),
            ),
            Divider(),
            ListTile(
              title: Text("Share"),
              leading: Icon(Icons.share),
              onTap: () => Utils.invite(),
            ),
            Divider(),
            ListTile(
              title: Text("Developer"),
              leading: Icon(Icons.developer_mode),
              subtitle: Text("Kumah Andrews"),
            ),
            Divider(),
            ListTile(
              title: Text("App Information"),
              leading: Icon(Icons.info),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => AppInfo()));
              },
            ),
          ],
        ),
      ),
    );
  }

  _showImageDialog(BuildContext context, String image) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(
                        width: 10.0,
                      ),
                      IconButton(
                          color: Colors.white,
                          icon: Icon(Icons.share),
                          onPressed: () {})
                    ],
                  )
                ],
              ),
            ));
  }

  _rate() {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return RatingDialog(
            image: Image.asset('assets/kumchat2.png'),
            title: 'Enjoying using KumChat? Rate us!',
            submitButton: "SUBMIT",
            ratingColor: Colors.blue,
            enableComment: true,
            initialRating: 5,
            commentHint: "Tell us your comments",
            onSubmitted: (RatingDialogResponse) {
              AppReview.writeReview;
            },
            // alternativeButton: 'Send an email',
            // onAlternativePressed: () {
            //   launch('mailto:kumah.andrews@gmail.com?subject=Utils%20Feedback');
            //   Navigator.pop(context);
            // },
          );
        });
  }

  Stream<MessageData> getUnread(Map<String, dynamic> user) {
    String chatId = Utils.getChatId(widget.phone!, user[PHONE]);
    var controller = StreamController<MessageData>.broadcast();
    unreadSubscriptions.add(FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc[widget.phone] != null && doc[widget.phone] is int) {
        unreadSubscriptions.add(FirebaseFirestore.instance
            .collection(MESSAGES)
            .doc(chatId)
            .collection(chatId)
            .snapshots()
            .listen((snapshot) {
          controller.add(
              MessageData(snapshot: snapshot, lastSeen: doc[widget.phone]));
        }));
      }
    }));
    controllers.add(controller);
    return controller.stream;
  }

  String getWhen(date) {
    //var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
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

  getLastSeen(val) {
    if (val is int) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(val);
      String at = DateFormat.jm().format(date), when = getWhen(date);
      return 'last seen $when at $at';
    } else {
      return "online";
    }
  }

  Widget buildItem(BuildContext context, Map<String, dynamic> user) {
    NavigatorState state = Navigator.of(context);
    if (user[PHONE] as String == widget.phone) {
      return Container(width: 0, height: 0);
    } else {
      return StreamBuilder(
          stream: getUnread(user).asBroadcastStream(),
          builder: (context, AsyncSnapshot<MessageData> unreadData) {
            int unread =
                unreadData.hasData && unreadData.data!.snapshot!.docs.isNotEmpty
                    ? unreadData.data!.snapshot!.docs
                        .where((t) => t[TIMESTAMP] > unreadData.data!.lastSeen)
                        .length
                    : 0;
            return Theme(
                data: ThemeData(
                    splashColor: Colors.blue,
                    highlightColor: Colors.transparent),
                child: ListTile(
                  onLongPress: () {
                    ChatController.authenticate(_cachedModel!,
                        'Authentication needed to unlock the chat.',
                        state: state,
                        shouldPop: true,
                        type: Utils.getAuthenticationType(
                            biometricEnabled, _cachedModel!),
                        prefs: prefs!, onSuccess: () async {
                      await Future.delayed(Duration(seconds: 0));
                      unawaited(showDialog(
                          context: context,
                          builder: (context) {
                            return AliasForm(user, _cachedModel!);
                          }));
                    });
                  },
                  leading: Stack(
                    overflow: Overflow.visible,
                    children: <Widget>[
                      Utils.avatar(user),
                      Positioned(
                        top: 0.0,
                        right: 0.0,
                        child: Container(
                          child: unread != 0
                              ? Text(unread.toString(),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))
                              : Container(width: 0, height: 0),
                          padding: const EdgeInsets.all(7.0),
                          decoration: new BoxDecoration(
                            shape: BoxShape.circle,
                            color: user[LAST_SEEN] == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      )
                    ],
                  ),
                  title: Text(
                    Utils.getNickname(user),
                    style: TextStyle(color: Colors.black),
                  ),
                  subtitle: Text(getLastSeen(user[LAST_SEEN])),
                  onTap: () {
                    if (_cachedModel!.currentUser![LOCKED] != null &&
                        _cachedModel!.currentUser![LOCKED]
                            .contains(user[PHONE])) {
                      NavigatorState state = Navigator.of(context);
                      ChatController.authenticate(_cachedModel!,
                          'Authentication needed to unlock the chat.',
                          state: state,
                          shouldPop: false,
                          type: Utils.getAuthenticationType(
                              biometricEnabled, _cachedModel!),
                          prefs: prefs!, onSuccess: () {
                        state.pushReplacement(new MaterialPageRoute(
                            builder: (context) => new ChatScreen(
                                unread: unread,
                                model: _cachedModel,
                                currentUserNo: widget.phone,
                                peerNo: user[PHONE] as String)));
                      });
                    } else {
                      Navigator.push(
                          context,
                          new MaterialPageRoute(
                              builder: (context) => new ChatScreen(
                                  unread: unread,
                                  model: _cachedModel,
                                  currentUserNo: widget.phone,
                                  peerNo: user[PHONE] as String)));
                    }
                  },
                ));
          });
    }
  }

  _isHidden(phoneNo) {
    Map<String, dynamic> _currentUser = _cachedModel!.currentUser!;
    return _currentUser[HIDDEN] != null &&
        _currentUser[HIDDEN].contains(phoneNo);
  }

  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();

  List<Map<String, dynamic>> _users = [];

  _chats(Map<String, Map<String, dynamic>> _userData,
      Map<String, dynamic> currentUser) {
    _users = Map.from(_userData)
        .values
        .where((_user) => _user.keys.contains(CHAT_STATUS))
        .toList()
        .cast<Map<String, dynamic>>();
    Map<String, int> _lastSpokenAt = _cachedModel!.lastSpokenAt;
    List<Map<String, dynamic>> filtered = [];

    _users.sort((a, b) {
      int aTimestamp = _lastSpokenAt[a[PHONE]] ?? 0;
      int bTimestamp = _lastSpokenAt[b[PHONE]] ?? 0;
      return bTimestamp - aTimestamp;
    });

    if (!showHidden) {
      _users.removeWhere((_user) => _isHidden(_user[PHONE]));
    }
    return Stack(
      children: <Widget>[
        RefreshIndicator(
            onRefresh: () {
              if (showHidden == false && _userData.length != _users.length) {
                isAuthenticating = true;
                ChatController.authenticate(_cachedModel!,
                    'Authentication needed to show the hidden chats.',
                    shouldPop: true,
                    type: Utils.getAuthenticationType(
                        biometricEnabled, _cachedModel!),
                    state: Navigator.of(context),
                    prefs: prefs!, onSuccess: () {
                  isAuthenticating = false;
                  setState(() {
                    showHidden = true;
                  });
                });
              } else {
                if (showHidden != false)
                  setState(() {
                    showHidden = false;
                  });
                return Future.value(false);
              }
              return Future.value(false);
            },
            child: Container(
                child: _users.isNotEmpty
                    ? StreamBuilder(
                        stream: _userQuery.stream.asBroadcastStream(),
                        builder: (context, snapshot) {
                          if (_filter.text.isNotEmpty ||
                              snapshot.hasData && snapshot.data != null) {
                            filtered = this._users.where((user) {
                              return user[NICKNAME]
                                  .toLowerCase()
                                  .trim()
                                  .contains(new RegExp(r'' +
                                      _filter.text.toLowerCase().trim() +
                                      ''));
                            }).toList();
                            if (filtered.isNotEmpty)
                              return ListView.builder(
                                padding: EdgeInsets.all(10.0),
                                itemBuilder: (context, index) => buildItem(
                                    context, filtered.elementAt(index)),
                                itemCount: filtered.length,
                              );
                            else
                              return ListView(children: [
                                Padding(
                                    padding: EdgeInsets.only(
                                        top:
                                            MediaQuery.of(context).size.height /
                                                3.5),
                                    child: Center(
                                      child: Text('No search results.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.black,
                                          )),
                                    ))
                              ]);
                          }
                          return ListView.builder(
                            padding: EdgeInsets.all(10.0),
                            itemBuilder: (context, index) =>
                                buildItem(context, _users.elementAt(index)),
                            itemCount: _users.length,
                          );
                        })
                    : ListView(children: [
                        Padding(
                            padding: EdgeInsets.only(
                                top: MediaQuery.of(context).size.height / 3.5),
                            child: Center(
                              child: Padding(
                                  padding: EdgeInsets.all(30.0),
                                  child: Text(
                                      'Start conversing by pressing the button at bottom right!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                      ))),
                            ))
                      ]))),
      ],
    );
  }
}

class BeautifulAlertDialog extends StatelessWidget {
  final VoidCallback logout;
  final String image;
  BeautifulAlertDialog(this.logout, this.image);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(right: 16.0),
          height: 150,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(75),
                  bottomLeft: Radius.circular(75),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10))),
          child: Row(
            children: <Widget>[
              SizedBox(width: 20.0),
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.grey.shade200,
                child: PNetworkImage(
                  image,
                  width: 60,
                ),
              ),
              SizedBox(width: 20.0),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Attention!",
                      style: Theme.of(context).textTheme.title,
                    ),
                    SizedBox(height: 10.0),
                    Flexible(
                      child: Text("Do you want to continue to logout?"),
                    ),
                    SizedBox(height: 10.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ElevatedButton(
                            child: Text("No"),
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.red),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: ElevatedButton(
                            child: Text("Yes"),
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.green),
                            ),
                            onPressed: () {
                              logout;
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MessageData {
  int? lastSeen;
  QuerySnapshot? snapshot;
  MessageData({@required this.snapshot, @required this.lastSeen});
}
