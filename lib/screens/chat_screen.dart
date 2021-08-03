import 'dart:async';
//import 'dart:html';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/models/user_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/models/message_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String? currentUserNo;
  final String? peerNo;
  final DataModel? model;
  final UserM? user;
  final int? unread;
  final String? userId;
  final String? profileUrl;
  ChatScreen(
      {Key? key,
      @required this.userId,
      @required this.peerNo,
      @required this.unread,
      @required this.model,
      this.profileUrl,
      @required this.user,
      @required this.currentUserNo})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool? showEmojiKeyboard;
  final TextEditingController msgController = new TextEditingController();
  final GlobalKey<FormFieldState> formKey = GlobalKey<FormFieldState>();

  static DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

  humanReadableTime() => DateFormat('h:mm a').format(now);

  FirebaseDatabase? _database;
  DatabaseReference? reference;

  StreamSubscription<Event>? _onTodoAddedSubscription;
  StreamSubscription<Event>? _onTodoChangedSubscription;
  StreamSubscription<Event>? AddedSubscription;
  StreamSubscription<Event>? ChangedSubscription;

  List<MessageModel>? items;
  MessageModel? message;
  Query? _todoQuery;
  String? sender, receiver, time, imageView, type, text, chatBubbleTime;
  bool? unread;
  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('ic_launcher1');
    var ios = new IOSInitializationSettings();
    var settings = new InitializationSettings(android: android, iOS: ios);
    flutterLocalNotificationsPlugin!
        .initialize(settings, onSelectNotification: onSelectNotification);
    items = [];
    _database = FirebaseDatabase.instance;
    reference = _database!.reference();
    _todoQuery = _database!.reference().child("Chats");
    _onTodoAddedSubscription = _todoQuery!.onChildAdded.listen(onEntryAdded);
    _onTodoChangedSubscription =
        _todoQuery!.onChildChanged.listen(onEntryChanged);
    _database!.setPersistenceEnabled(true);
    _database!.setPersistenceCacheSizeBytes(10000000);
    _database!.reference().keepSynced(true);
    _database!.goOnline();
    _database!.purgeOutstandingWrites();
    reference!.keepSynced(true);
    WidgetsBinding.instance!.addObserver(this);
    showEmojiKeyboard = false;
  }

  Future onSelectNotification(String payload) {
    debugPrint('payload: $payload');
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text('Notification'),
              content: Text('$payload'),
            ));
  }

  showNotification() async {
    var android = AndroidNotificationDetails(
        'channelId', 'channelName', 'channelDescription');
    var ios = IOSNotificationDetails();
    var platform = NotificationDetails(android: android, iOS: ios);
    await flutterLocalNotificationsPlugin!
        .show(0, 'New message is out', 'new: details ', platform);
  }

  @override
  void dispose() {
    status("offline");
    offlineTime(formattedDate);
    _onTodoAddedSubscription!.cancel();
    _onTodoChangedSubscription!.cancel();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  Future<DataSnapshot> getDatabaseSnap() async {
    var _newref = reference!.child("Chats");
    await _newref.keepSynced(true);
    return await _newref.once();
  }

  onEntryChanged(Event event) {
    var oldEntry = items!.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    MessageModel chat = MessageModel.fromSnapshot(event.snapshot);
    if (chat.receiver == widget.userId && chat.sender == widget.user!.id ||
        chat.receiver == widget.user!.id && chat.sender == widget.userId) {
      setState(() {
        items![items!.indexOf(oldEntry)] =
            MessageModel.fromSnapshot(event.snapshot);
        //_onHiveMessageDataChanged(MessageModel.fromSnapshot(event.snapshot));
      });
    }

    /*reference = _database.reference().child('Chats');
    if(chat.receiver == (widget.userId) && chat.sender == (widget.user.id)){
      var st ={'isSeen': true};

    }*/
  }

  //void isSeen (bool t) async{
  //   await _database.reference().child("Chats").update(st);
  //}

  onEntryAdded(Event event) {
    MessageModel chat = MessageModel.fromSnapshot(event.snapshot);
    if (chat.receiver == widget.userId && chat.sender == widget.user!.id ||
        chat.receiver == widget.user!.id && chat.sender == widget.userId) {
      setState(() {
        items!.add(chat);
        //_existingHiveData(chat);
      });
    }
  }

  addNewTodo(String msg) {
    if (msg.length > 0) {
      MessageModel message = new MessageModel(widget.userId!, widget.user!.id,
          msg.toString(), 'text', formattedDate, 'default', false);
      _database!.reference().child("Chats").push().set(message.toJson());
      typingStatus("no");
      status("online");
      _database!.reference().keepSynced(true);
    }
  }

  updateTodo(MessageModel message) {
    //Toggle completed
    if (message != null) {
      _database!
          .reference()
          .child("Chats")
          .child(message.key)
          .set(message.toJson());
    }
  }

  deleteTodo(String msgId, int index) {
    _database!.reference().child("Chats").child(msgId).remove().then((_) {
      print("Delete $msgId successful");
      setState(() {
        items!.removeAt(index);
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      status("online");
    } else if (state == AppLifecycleState.inactive) {
      status("offline");
      typingStatus("no");
      offlineTime(formattedDate);
    } else if (state == AppLifecycleState.paused) {
      status("offline");
      typingStatus("no");
      offlineTime(formattedDate);
    }
  }

  textListener() {
    if (msgController.text.length != 0 && msgController.text.isNotEmpty) {
      typingStatus("typing");
    } else {
      typingStatus("no");
    }
  }

  void offlineTime(String offTime) async {
    var st = {'offlineTime': offTime};
    await _database!.reference().child("Users").child(widget.userId).update(st);
  }

  void status(String status) async {
    var st = {'status': status};
    await _database!.reference().child("Users").child(widget.userId).update(st);
  }

  void typingStatus(String typing) async {
    var st = {'typing': typing};
    await _database!.reference().child("Users").child(widget.userId).update(st);
  }

  buildMessage(String message, bool isMe) {
    chatBubbleTime = time!.substring(11, 16);

    var triangle = CustomPaint(
      painter: Triangle(isMe),
    );

    var seenTick = Icon(
      !unread! ? Icons.done : Icons.done_all,
      color: !unread! ? Colors.grey : Colors.blue,
    );

    var messagebody = DecoratedBox(
      decoration: BoxDecoration(
        color: isMe ? Colors.blue[200] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Text(text!),
            Text(chatBubbleTime!),
          ],
        ),
      ),
    );

    Widget message;

    if (isMe) {
      message = Stack(
        children: <Widget>[
          messagebody,
          Positioned(right: 0, top: 10, child: triangle),
          Positioned(
            child: seenTick,
            right: 0,
            bottom: 0,
          ),
        ],
      );
    } else {
      message = Stack(
        children: <Widget>[
          Positioned(left: 0, top: 10, child: triangle),
          messagebody,
        ],
      );
    }
    if (isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(8.0),
            child: message,
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(8.0),
            child: message,
          ),
        ],
      );
    }
  }

  buildMessageComposer() {
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          height: 48.0,
          decoration: ShapeDecoration(
            shape: StadiumBorder(),
            color: Colors.blue[50],
          ),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    showEmojiKeyboard = !showEmojiKeyboard!;
                  });
                },
                child: Container(
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 1,
                          blurRadius: 1,
                        )
                      ]),
                  child: Center(
                    child: Icon(
                      Icons.face,
                      size: 20.0,
                      color: showEmojiKeyboard!
                          ? Colors.blue[500]
                          : Colors.black12,
                    ),
                  ),
                ),
              ),
              Flexible(
                  fit: FlexFit.tight,
                  child: TextFormField(
                    key: formKey,
                    controller: msgController,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.text,
                    autofocus: false,
                    autocorrect: true,
                    enableSuggestions: true,
                    onChanged: (value) {
                      textListener();
                    },
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(14.0),
                      border: InputBorder.none,
                      hintText: 'Type message here...',
                      hintStyle: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600),
                      suffixIcon: GestureDetector(
                        onTap: null,
                        child: Icon(
                          Icons.mic,
                          size: 28.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    onSaved: (val) => message!.text = val!,
                    validator: (val) => val == "" ? val : null,
                  )),
              GestureDetector(
                onTap: () {
                  addNewTodo(msgController.text.toString());
                  msgController.text = "";
                },
                child: Container(
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(60.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          spreadRadius: 1,
                          blurRadius: 1,
                        )
                      ]),
                  child: Center(
                    child: Icon(
                      Icons.send,
                      size: 20.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var userQuery = FirebaseDatabase.instance
        .reference()
        .child("Users")
        .child(widget.user!.id);

    return WillPopScope(
      onWillPop: onBackPress,
      child: StreamBuilder<Event>(
          stream: userQuery.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              DataSnapshot snap = snapshot.data!.snapshot;
              List<UserM> cUser = [];

              cUser.add(UserM.fromSnapshot(snap));
              //_onHiveDataChanged(User.fromSnapshot(snap));
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("assets/bg.jpg"),
                          fit: BoxFit.cover)),
                  child: Scaffold(
                    // key: _scaffoldKey,
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      title: Row(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 0, bottom: 0, right: 8.0),
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100.0),
                                image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        widget.user!.imageUrl),
                                    fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              Text(
                                widget.user!.username,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 28.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                cUser[0].status == 'online' &&
                                        cUser[0].typing == "no"
                                    ? cUser[0].status
                                    : cUser[0].typing != "no"
                                        ? cUser[0].typing + '....'
                                        : 'Last seen' +
                                            ' ● ' +
                                            cUser[0].offlineTime,
                                textScaleFactor: 0.6,
                              ),
                            ],
                          ),
                        ],
                      ),
                      elevation: 0.0,
                      actions: <Widget>[
                        IconButton(
                          icon: Icon(Icons.more_horiz),
                          iconSize: 30.0,
                          color: Colors.white,
                          onPressed: () {
                            showNotification();
                          },
                        ),
                      ],
                    ),
                    body: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                              child: Container(
                            decoration: BoxDecoration(
                              //color: Colors.white,
                              //gradient: FlutterGradients.happyFisher(),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                topRight: Radius.circular(30.0),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30.0),
                                topRight: Radius.circular(30.0),
                              ),
                              child: ListView.builder(
                                reverse: false,
                                padding: EdgeInsets.only(top: 15.0),
                                itemCount: items!.length,
                                itemBuilder: (BuildContext context, int index) {
                                  receiver = items![index].receiver;
                                  time = items![index].time;
                                  unread = items![index].unread;
                                  imageView = items![index].imageView;
                                  type = items![index].type;

                                  sender = items![index].sender;
                                  text = items![index].text;
                                  final bool isMe = sender == widget.userId;

                                  //return text != null ? buildMessage(text, isMe) : Container();
                                  return buildMessage(text!, isMe);
                                },
                              ),
                            ),
                          )),
                          buildMessageComposer(),
                          MediaQuery.of(context).viewInsets.bottom < 24 &&
                                  showEmojiKeyboard!
                              ? buildSticker()
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Scaffold(
                  backgroundColor: Theme.of(context).primaryColor,
                  appBar: AppBar(
                    title: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 0, bottom: 0, right: 8.0),
                          child: Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              image: DecorationImage(
                                  image: CachedNetworkImageProvider(
                                      widget.user!.imageUrl),
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            Text(
                              widget.user!.username,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.user!.status == 'online' &&
                                      widget.user!.typing == "no"
                                  ? widget.user!.status
                                  : widget.user!.typing != "no"
                                      ? widget.user!.typing + '....'
                                      : 'Last seen' +
                                          ' ● ' +
                                          widget.user!.offlineTime,
                              textScaleFactor: 0.6,
                            ),
                          ],
                        ),
                      ],
                    ),
                    elevation: 0.0,
                    actions: <Widget>[
                      IconButton(
                        icon: Icon(Icons.more_horiz),
                        iconSize: 30.0,
                        color: Colors.white,
                        onPressed: () {
                          showNotification();
                        },
                      ),
                    ],
                  ),
                  body: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30.0),
                                  topRight: Radius.circular(30.0),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30.0),
                                  topRight: Radius.circular(30.0),
                                ),
                                child: ListView.builder(
                                  reverse: false,
                                  padding: EdgeInsets.only(top: 15.0),
                                  itemCount: items!.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    receiver = items![index].receiver;
                                    time = items![index].time;
                                    unread = items![index].unread;
                                    imageView = items![index].imageView;
                                    type = items![index].type;

                                    sender = items![index].sender;
                                    text = items![index].text;
                                    final bool isMe = sender == widget.userId;

                                    //return text != null ? buildMessage(text, isMe) : Container();
                                    return buildMessage(text!, isMe);
                                  },
                                ),
                              )),
                        ),
                        buildMessageComposer(),
                        MediaQuery.of(context).viewInsets.bottom < 24 &&
                                showEmojiKeyboard!
                            ? buildSticker()
                            : Container(),
                      ],
                    ),
                  ),
                ),
              );
            }
          }),
    );
  }

  Future<bool> onBackPress() {
    if (showEmojiKeyboard!) {
      setState(() {
        showEmojiKeyboard = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  Widget buildSticker() {
    return EmojiPicker(
      config: Config(
        columns: 7,
        buttonMode: ButtonMode.MATERIAL,
        bgColor: Theme.of(context).accentColor,
      ),
      onEmojiSelected: (category, emoji) {
        msgController.text = msgController.text + emoji.emoji;
      },
    );
  }
}

class Triangle extends CustomPainter {
  Triangle(this.isMe);
  final isMe;
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = (isMe ? Colors.blue[200] : Colors.blue[50])!;

    var path = Path();
    path.lineTo(-10, -10);
    path.lineTo(10, -10);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
