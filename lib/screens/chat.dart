import 'dart:async';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/widgets.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:giphy_picker/giphy_picker.dart';
import 'package:kumchat/Pickers/videoPicker.dart';
import 'package:kumchat/Pickers/AudioPicker.dart';
import 'package:kumchat/Pickers/filesPicker.dart';
import 'package:kumchat/message.dart';
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/photo_view.dart';
import 'package:kumchat/profile_view.dart';
import 'package:collection/collection.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:intl/intl.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cached_network_image/cached_network_image.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:kumchat/models/DataModel.dart';
import 'package:kumchat/seen_provider.dart';
import 'package:kumchat/seen_state.dart';
import 'package:kumchat/services/chat_controller.dart';
import 'package:kumchat/utils/VideoPlayerWidget.dart';
// ignore: unused_import
import 'package:kumchat/utils/audioPlayer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kumchat/Pickers/image_picker.dart';
import 'package:kumchat/bubble.dart';
import 'package:kumchat/E2EE/e2ee.dart' as e2ee;
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:scoped_model/scoped_model.dart';
import 'package:kumchat/services/save.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:video_thumbnail/video_thumbnail.dart';

class ChatScreen extends StatefulWidget {
  final String? peerNo, currentUserNo;
  final DataModel? model;
  final int? unread;
  ChatScreen(
      {Key? key,
      @required this.currentUserNo,
      @required this.peerNo,
      @required this.model,
      @required this.unread});

  @override
  State createState() =>
      new _ChatScreenState(currentUserNo: currentUserNo!, peerNo: peerNo!);
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  String? peerAvatar, peerNo, currentUserNo, privateKey, sharedSecret;
  bool? locked, hidden;
  Map<String, dynamic>? peer, currentUser;
  int? chatStatus, unread;

  _ChatScreenState({@required this.peerNo, @required this.currentUserNo});

  double getRadianFromDegree(double degree) {
    double unitRadian = 57.295779513;
    return degree / unitRadian;
  }

  AnimationController? animationController;
  Animation? degOneTranslationAnimation,
      degTwoTranslationAnimation,
      degThreeTranslationAnimation,
      rotationAnimation;

  String? chatId;
  SharedPreferences? prefs;

  bool? showEmojiKeyboard;
  bool? typing = false;

  File? imageFile;
  File? file;
  bool? isLoading;
  String? imageUrl;
  SeenState? seenState;
  List<Message>? messages = [];

  int? uploadTimestamp;

  StreamSubscription? seenSubscription, msgSubscription;

  TextEditingController textEditingController = new TextEditingController();
  final ScrollController realtime = new ScrollController();
  final ScrollController saved = new ScrollController();
  DataModel? _cachedModel;

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    degOneTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(animationController!);
    degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.4), weight: 55.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.4, end: 1.0), weight: 45.0),
    ]).animate(animationController!);
    degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.75), weight: 35.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.75, end: 1.0), weight: 65.0),
    ]).animate(animationController!);
    rotationAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(parent: animationController!, curve: Curves.easeOut));
    super.initState();
    animationController!.addListener(() {
      setState(() {});
    });
    Utils.internetLookUp();
    _cachedModel = widget.model;
    updateLocalUserData(_cachedModel);
    readLocal();
    seenState = new SeenState(false);
    WidgetsBinding.instance!.addObserver(this);
    chatId = '';
    unread = widget.unread;
    isLoading = false;
    imageUrl = '';
    showEmojiKeyboard = false;
    if (textEditingController.text.isEmpty) {
      textEditingController = new TextEditingController();
    }
    setIsActive();
  }

  updateLocalUserData(model) {
    peer = model.userData[peerNo];
    currentUser = _cachedModel!.currentUser;
    if (currentUser != null && peer != null) {
      hidden =
          currentUser![HIDDEN] != null && currentUser![HIDDEN].contains(peerNo);
      locked =
          currentUser![LOCKED] != null && currentUser![LOCKED].contains(peerNo);
      chatStatus = peer![CHAT_STATUS];
      peerAvatar = peer![PHOTO_URL];
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    setLastSeen();
    msgSubscription?.cancel();
    seenSubscription?.cancel();
  }

  void setLastSeen() async {
    if (chatStatus != ChatStatus.blocked.index) {
      if (chatId != null) {
        await FirebaseFirestore.instance.collection(MESSAGES).doc(chatId).set(
            {'$currentUserNo': DateTime.now().millisecondsSinceEpoch},
            SetOptions(merge: true));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setIsActive();
    else
      setLastSeen();
  }

  void setIsActive() async {
    await FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .set({'$currentUserNo': true}, SetOptions(merge: true));
  }

  dynamic lastSeen;

  FlutterSecureStorage storage = new FlutterSecureStorage();
  encrypt.Encrypter? cryptor;
  final iv = encrypt.IV.fromLength(8);

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    try {
      privateKey = await storage.read(key: PRIVATE_KEY);
      sharedSecret = (await e2ee.X25519().calculateSharedSecret(
              e2ee.Key.fromBase64(privateKey!, false),
              e2ee.Key.fromBase64(peer![PUBLIC_KEY], true)))
          .toBase64();
      final key = encrypt.Key.fromBase64(sharedSecret!);
      cryptor = new encrypt.Encrypter(encrypt.Salsa20(key));
    } catch (e) {
      sharedSecret = null;
    }
    try {
      seenState!.value = prefs!.getInt(getLastSeenKey());
    } catch (e) {
      seenState!.value = false;
    }
    chatId = Utils.getChatId(currentUserNo!, peerNo!);
    textEditingController.addListener(() {
      if (textEditingController.text.isNotEmpty && typing == false) {
        lastSeen = peerNo;
        print(lastSeen);
        FirebaseFirestore.instance
            .collection(USERS)
            .doc(currentUserNo)
            .set({LAST_SEEN: peerNo}, SetOptions(merge: true));
        typing = true;
      }
      if (textEditingController.text.isEmpty && typing == true) {
        lastSeen = true;
        FirebaseFirestore.instance
            .collection(USERS)
            .doc(currentUserNo)
            .set({LAST_SEEN: true}, SetOptions(merge: true));
        typing = false;
      }
    });
    setIsActive();
    seenSubscription = FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .snapshots()
        .listen((doc) {
      if (doc != null && mounted) {
        seenState!.value = doc[peerNo] ?? false;
        if (seenState!.value is int) {
          prefs!.setInt(getLastSeenKey(), seenState!.value);
        }
      }
    });
    loadMessagesAndListen();
  }

  String getLastSeenKey() {
    return "$peerNo-$LAST_SEEN";
  }

  getImage(File image) {
    if (image != null) {
      setState(() {
        imageFile = image;
      });
    }
    return uploadFile(imageFile!);
  }

  getVideo(File video) {
    if (video != null) {
      setState(() {
        file = video;
      });
    }
    return uploadFile(file!);
  }

  getAudio(File audio) {
    if (audio != null) {
      setState(() {
        file = audio;
      });
    }
    return uploadFile(file!);
  }

  getContact(File contact) {
    if (contact != null) {
      setState(() {
        file = contact;
      });
    }
    return uploadFile(file!);
  }

  getFiles(File file) {
    if (file != null) {
      setState(() {
        file = file;
      });
    }
    return uploadFile(file);
  }

  getWallpaper(File image) {
    if (image != null) {
      _cachedModel!.setWallpaper(peerNo!, image);
    }
    return Future.value(false);
  }

  getImageFileName(id, timestamp) {
    return "$id-$timestamp";
  }

  Future uploadFile(File file) async {
    uploadTimestamp = DateTime.now().millisecondsSinceEpoch;
    String fileName = getImageFileName(currentUserNo, '$uploadTimestamp');
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploading = reference.putFile(file);
    return uploading.future.then((value) => value.downloadUrl);
  }

  void onSendMessage(String content, MessageType type, int timestamp) async {
    if (content.trim() != '') {
      content = content.trim();
      if (chatStatus == null) ChatController.request(currentUserNo, peerNo);
      textEditingController.clear();
      Future messaging = FirebaseFirestore.instance
          .collection(MESSAGES)
          .doc(chatId)
          .collection(chatId)
          .doc('$timestamp')
          .set({
        FROM: currentUserNo,
        TO: peerNo,
        TIMESTAMP: timestamp,
        CONTENT: content,
        TYPE: type.index
      });
      _cachedModel!.addMessage(peerNo!, timestamp, messaging);
      var tempDoc = {
        TIMESTAMP: timestamp,
        TYPE: type.index,
        CONTENT: content,
        FROM: currentUserNo,
      };
      setState(() {
        messages = List.from(messages!)
          ..add(Message(
            buildTempMessage(type, content, timestamp, messaging),
            onTap: type == MessageType.image
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewWrapper(
                        tag: timestamp.toString(),
                        imageProvider: CachedNetworkImageProvider(content),
                      ),
                    ))
                : () {},
            onDismiss: () {},
            onLongPress: () {
              contextMenu(tempDoc);
            },
            from: currentUserNo!,
            timestamp: timestamp,
          ));
      });

      unawaited(realtime.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut));
    }
  }

  delete(int ts) {
    setState(() {
      messages!.removeWhere((msg) => msg.timestamp == ts);
      messages = List.from(messages!);
    });
  }

  contextMenu(Map<String, dynamic> doc, {bool saved = false}) {
    List<Widget> tiles = [];

    if (doc[TYPE] == MessageType.text.index) {
      tiles.add(ListTile(
          dense: true,
          leading: Icon(Icons.content_copy),
          title: Text(
            'Copy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: doc[CONTENT]));
            Navigator.pop(context);
            Utils.toast('Copied!');
          }));
    }

    showDialog(
        context: context,
        builder: (context) {
          return Theme(
              data: ThemeData.light(), child: SimpleDialog(children: tiles));
        });
  }

  Widget getTextMessage(bool isMe, Map<String, dynamic> doc, bool saved) {
    return Text(
      doc[CONTENT],
      style:
          TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 16.0),
    );
  }

  Widget getTempTextMessage(String message) {
    return Text(
      message,
      style: TextStyle(color: Colors.white, fontSize: 16.0),
    );
  }

  Widget getAudioMessage(bool isMe, Map<String, dynamic> doc,
      {bool saved = false}) {
    return Container(
        // child: AudioPlayerWidget(
        //   isMe: isMe,
        //   peer: doc,
        //   audioURL: doc[CONTENT],
        // ),
        );
  }

  Widget getVideoMessage(Map<String, dynamic> doc, {bool saved = false}) {
    return Container(
      height: 200,
      width: 200,
      child: GenThumbnailImage(
          thumbnailRequest: ThumbnailRequest(
              video: doc[CONTENT],
              thumbnailPath: '/storage/emulated/0/Kumchat/Thumbnails',
              imageFormat: ImageFormat.JPEG,
              maxHeight: 200,
              maxWidth: 200,
              timeMs: 1,
              quality: 10)),
    );
  }

  Widget getImageMessage(Map<String, dynamic> doc, {bool saved = false}) {
    return Container(
      child: saved
          ? Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                    image: Save.getImageFromBase64(doc[CONTENT]).image,
                    fit: BoxFit.cover),
              ),
              width: 200.0,
              height: 200.0,
            )
          : CachedNetworkImage(
              placeholder: (context, url) => Container(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                width: 200.0,
                height: 200.0,
                padding: EdgeInsets.all(80.0),
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                ),
              ),
              errorWidget: (context, str, error) => Material(
                child: Image.asset(
                  'assets/img_not_available.jpeg',
                  width: 200.0,
                  height: 200.0,
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(8.0),
                ),
                clipBehavior: Clip.hardEdge,
              ),
              imageUrl: doc[CONTENT],
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
    );
  }

  Widget getTempImageMessage({String? url}) {
    return imageFile != null
        ? Container(
            child: Image.file(
              imageFile!,
              width: 200.0,
              height: 200.0,
              fit: BoxFit.cover,
            ),
          )
        : getImageMessage({CONTENT: url});
  }

  Widget buildMessage(Map<String, dynamic> doc,
      {bool saved = false, List<Message>? savedMsgs}) {
    final bool isMe = doc[FROM] == currentUserNo;
    bool isContinuing;
    if (savedMsgs == null)
      isContinuing =
          messages!.isNotEmpty ? messages!.last.from == doc[FROM] : false;
    else {
      isContinuing =
          savedMsgs.isNotEmpty ? savedMsgs.last.from == doc[FROM] : false;
    }
    return SeenProvider(
        timestamp: doc[TIMESTAMP].toString(),
        data: seenState!,
        child: Bubble(
            child: doc[TYPE] == MessageType.text.index
                ? getTextMessage(isMe, doc, saved)
                : doc[TYPE] == MessageType.image.index
                    ? getImageMessage(doc, saved: saved)
                    : doc[TYPE] == MessageType.video.index
                        ? getVideoMessage(doc, saved: saved)
                        : getAudioMessage(isMe, doc, saved: saved),
            isMe: isMe,
            timestamp: doc[TIMESTAMP],
            delivered: _cachedModel!.getMessageStatus(peerNo!, doc[TIMESTAMP]),
            isContinuing: isContinuing));
  }

  Widget buildTempMessage(MessageType type, content, timestamp, delivered) {
    final bool isMe = true;
    return SeenProvider(
        timestamp: timestamp.toString(),
        data: seenState!,
        child: Bubble(
          child: type == MessageType.text
              ? getTempTextMessage(content)
              : getTempImageMessage(url: content),
          isMe: isMe,
          timestamp: timestamp,
          delivered: delivered,
          isContinuing:
              messages!.isNotEmpty && messages!.last.from == currentUserNo,
        ));
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading!
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput() {
    if (chatStatus == ChatStatus.requested.index) {
      return AlertDialog(
        backgroundColor: Colors.black12,
        elevation: 10.0,
        title: Text(
          'Accept ${peer![NICKNAME]}\'s invitation?',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          TextButton(
              child: Text('Reject'),
              onPressed: () {
                ChatController.block(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.blocked.index;
                });
              }),
          TextButton(
              child: Text('Accept'),
              onPressed: () {
                ChatController.accept(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.accepted.index;
                });
              })
        ],
      );
    }
    return Stack(children: <Widget>[
      Row(children: <Widget>[
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            height: 48.0,
            decoration: ShapeDecoration(
              shape: StadiumBorder(),
              color: Colors.blue[300],
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
                    height: 35.0,
                    width: 35.0,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
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
                        size: 30.0,
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
                      controller: textEditingController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      autofocus: false,
                      autocorrect: true,
                      enableSuggestions: true,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(14.0),
                        border: InputBorder.none,
                        hintText: 'Type message here...',
                        hintStyle: TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600),
                      ),
                    )),

                Transform(
                  transform: Matrix4.rotationZ(
                      getRadianFromDegree(rotationAnimation!.value)),
                  alignment: Alignment.center,
                  child: AttachmentButton(
                    color: Colors.blue[500]!,
                    width: 45,
                    height: 45,
                    icon: Icon(Icons.attachment, color: Colors.white),
                    onClick: () {
                      _showModalBottomSheet(context);
                      if (animationController!.isCompleted) {
                        animationController!.reverse();
                      } else {
                        animationController!.forward();
                      }
                    },
                  ),
                )

                //),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 10,
        ),
        GestureDetector(
          onTap: chatStatus != ChatStatus.blocked.index
              ? textEditingController.text.isNotEmpty
                  ? () => onSendMessage(textEditingController.text,
                      MessageType.text, DateTime.now().millisecondsSinceEpoch)
                  : () => voiceMessage()
              : null,
          onLongPress: null,
          onLongPressEnd: null,
          onPanUpdate: (details) {},
          child: Container(
              height: 45.0,
              width: 45.0,
              decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(60.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 1,
                      blurRadius: 1,
                    )
                  ]),
              child: textEditingController.text.isNotEmpty
                  ? Center(
                      child: Icon(
                        Icons.send,
                        size: 20.0,
                        color: Colors.white,
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.mic,
                        size: 20.0,
                        color: Colors.white,
                      ),
                    )),
        ),
      ]),
    ]);
  }

  bool empty = true;

  loadMessagesAndListen() async {
    await FirebaseFirestore.instance
        .collection(MESSAGES)
        .doc(chatId)
        .collection(chatId)
        .orderBy(TIMESTAMP)
        .get()
        .then((docs) {
      if (docs.docs.isNotEmpty) empty = false;
      docs.docs.forEach((doc) {
        Map<String, dynamic> _doc = Map.from(doc.data());
        int ts = _doc[TIMESTAMP];
        messages!.add(Message(buildMessage(_doc),
            onDismiss: () {},
            onTap: _doc[TYPE] == MessageType.image.index
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewWrapper(
                        tag: ts.toString(),
                        imageProvider:
                            CachedNetworkImageProvider(_doc[CONTENT]),
                      ),
                    ))
                : () {}, onLongPress: () {
          contextMenu(_doc);
        }, from: _doc[FROM], timestamp: ts));
      });
      if (mounted) {
        setState(() {
          messages = List.from(messages!);
        });
      }
      msgSubscription = FirebaseFirestore.instance
          .collection(MESSAGES)
          .doc(chatId)
          .collection(chatId)
          .where(FROM, isEqualTo: peerNo)
          .snapshots()
          .listen((query) {
        if (empty == true || query.docs.length != query.docChanges.length) {
          query.docChanges.where((doc) {
            return doc.oldIndex <= doc.newIndex;
          }).forEach((change) {
            Map<String, dynamic> _doc = Map.from(change.doc.data());
            int ts = _doc[TIMESTAMP];
            messages!.add(Message(buildMessage(_doc), onLongPress: () {
              contextMenu(_doc);
            },
                onTap: _doc[TYPE] == MessageType.image.index
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoViewWrapper(
                            tag: ts.toString(),
                            imageProvider:
                                CachedNetworkImageProvider(_doc[CONTENT]),
                          ),
                        ))
                    : () {},
                from: _doc[FROM],
                timestamp: ts,
                onDismiss: () {}));
          });
          if (mounted) {
            setState(() {
              messages = List.from(messages!);
            });
          }
        }
      });
    });
  }

  List<Widget> getGroupedMessages() {
    List<Widget> _groupedMessages = [];
    int count = 0;
    groupBy<Message, String>(messages!, (msg) {
      return getWhen(DateTime.fromMillisecondsSinceEpoch(msg.timestamp!));
    }).forEach((when, _actualMessages) {
      _groupedMessages.add(Center(
          child: Chip(
        label: Text(when),
      )));
      _actualMessages.forEach((msg) {
        count++;
        if (unread != 0 && (messages!.length - count) == unread! - 1) {
          _groupedMessages.add(Center(
              child: Chip(
            label: Text('$unread unread messages'),
          )));
          unread = 0; // reset
        }
        _groupedMessages.add(msg.child!);
      });
    });
    return _groupedMessages.reversed.toList();
  }

  Widget buildMessages() {
    if (chatStatus == ChatStatus.blocked.index) {
      return AlertDialog(
        backgroundColor: Colors.black12,
        elevation: 10.0,
        title: Text(
          'Unblock ${peer![NICKNAME]}?',
          style: TextStyle(color: Colors.white),
        ),
        actions: <Widget>[
          TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              }),
          TextButton(
              child: Text('Unblock'),
              onPressed: () {
                ChatController.accept(currentUserNo, peerNo);
                setState(() {
                  chatStatus = ChatStatus.accepted.index;
                });
              })
        ],
      );
    }
    return Flexible(
        child: chatId == '' || messages!.isEmpty || sharedSecret == null
            ? ListView(
                children: <Widget>[
                  Padding(
                      padding: EdgeInsets.only(top: 200.0),
                      child: Text(
                          sharedSecret == null
                              ? 'Setting things up.'
                              : 'Say Hi!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 18))),
                ],
                controller: realtime,
              )
            : ListView(
                padding: EdgeInsets.all(0.0),
                children: getGroupedMessages(),
                controller: realtime,
                reverse: true,
              ));
  }

  getWhen(date) {
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

  getPeerStatus(val) {
    if (val is bool && val == true) {
      return 'online';
    } else if (val is int) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(val);
      String at = DateFormat.jm().format(date), when = getWhen(date);
      return 'last seen $when at $at';
    } else if (val is String) {
      if (val == currentUserNo) return 'typing…';
      return 'online';
    }
    return 'loading…';
  }

  bool isBlocked() {
    return chatStatus == ChatStatus.blocked.index;
  }

  Widget buildSticker() {
    return EmojiPicker(
      config: Config(
        columns: 7,
        buttonMode: ButtonMode.MATERIAL,
        bgColor: Theme.of(context).accentColor,
      ),
      onEmojiSelected: (category, emoji) {
        textEditingController.text = textEditingController.text + emoji.emoji;
      },
    );
  }

  _showModalBottomSheet(context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      transitionDuration: Duration(milliseconds: 200),
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            children: <Widget>[
              Container(
                  height: 200,
                  child: Card(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          AttachmentButton(
                            color: Colors.deepPurple,
                            width: 50,
                            height: 50,
                            icon: Icon(Icons.insert_drive_file,
                                color: Colors.white),
                            onClick: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FilesPicker(
                                            title: 'Pick a file',
                                            callback: getFiles,
                                          ))).then((url) {
                                if (url != null) {
                                  onSendMessage(
                                      url, MessageType.files, uploadTimestamp!);
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 40.0,
                          ),
                          AttachmentButton(
                            color: Colors.purpleAccent,
                            width: 50,
                            height: 50,
                            icon:
                                Icon(Icons.video_library, color: Colors.white),
                            onClick: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => VideoPicker(
                                            title: 'Pick a video',
                                            callback: getVideo,
                                          ))).then((url) {
                                if (url != null) {
                                  onSendMessage(
                                      url, MessageType.video, uploadTimestamp!);
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 40.0,
                          ),
                          AttachmentButton(
                            color: Colors.purple,
                            width: 50,
                            height: 50,
                            icon: Icon(Icons.image, color: Colors.white),
                            onClick: chatStatus == ChatStatus.blocked.index
                                ? () {}
                                : () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                HybridImagePicker(
                                                  title: 'Pick an image',
                                                  callback: getImage,
                                                ))).then((url) {
                                      if (url != null) {
                                        onSendMessage(url, MessageType.image,
                                            uploadTimestamp!);
                                      }
                                    });
                                  },
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 30.0,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          AttachmentButton(
                            color: Colors.amber[900]!,
                            width: 50,
                            height: 50,
                            icon: Icon(Icons.headset, color: Colors.white),
                            onClick: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AudioPicker(
                                            title: 'Pick a audio',
                                            callback: getAudio,
                                          ))).then((url) {
                                if (url != null) {
                                  onSendMessage(
                                      url, MessageType.audio, uploadTimestamp!);
                                }
                              });
                            },
                          ),
                          SizedBox(
                            width: 40.0,
                          ),
                          AttachmentButton(
                            color: Colors.green,
                            width: 50,
                            height: 50,
                            icon: Icon(Icons.gif, color: Colors.white),
                            onClick: () async {
                              Navigator.pop(context);
                              animationController!.reverse();
                              final gif = await GiphyPicker.pickGif(
                                  context: context,
                                  apiKey: 'PkjPKUvd84HUEd2GGStxDxW8za02HBti');
                              onSendMessage(
                                  gif.images.original.url,
                                  MessageType.image,
                                  DateTime.now().millisecondsSinceEpoch);
                            },
                          ),
                          SizedBox(
                            width: 40.0,
                          ),
                          AttachmentButton(
                            color: Colors.blue[500]!,
                            width: 50,
                            height: 50,
                            icon: Icon(Icons.person, color: Colors.white),
                            onClick: () {
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AudioPicker(
                                            title: 'Pick a contact',
                                            callback: getContact,
                                          ))).then((url) {
                                if (url != null) {
                                  onSendMessage(url, MessageType.contact,
                                      uploadTimestamp!);
                                }
                              });
                            },
                          ),
                        ],
                      )
                    ],
                  ))),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ).drive(Tween<Offset>(
            begin: Offset(1, 1.2),
            end: Offset.zero,
          )),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(WillPopScope(
        onWillPop: () async {
          setLastSeen();
          if (lastSeen == peerNo)
            await FirebaseFirestore.instance
                .collection(USERS)
                .doc(currentUserNo)
                .set({LAST_SEEN: true}, SetOptions(merge: true));

          if (showEmojiKeyboard!) {
            setState(() {
              showEmojiKeyboard = false;
            });
          } else {
            Navigator.pop(context);
          }

          return Future.value(false);
        },
        child: ScopedModel<DataModel>(
            model: _cachedModel,
            child: ScopedModelDescendant<DataModel>(
                builder: (context, child, _model) {
              _cachedModel = _model;
              updateLocalUserData(_model);
              return peer != null
                  ? Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top),
                      child: Scaffold(
                          key: _scaffold,
                          backgroundColor: Colors.white,
                          appBar: PreferredSize(
                            preferredSize: Size.fromHeight(40.0),
                            child: Material(
                              child: ListTile(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                            opaque: false,
                                            pageBuilder: (context, a1, a2) =>
                                                ProfileView(peer!)));
                                  },
                                  dense: true,
                                  leading: Utils.avatar(peer!),
                                  title: Text(
                                    Utils.getNickname(peer!),
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Theme(
                                      data: ThemeData.light(),
                                      child: PopupMenuButton(
                                        onSelected: (val) {
                                          switch (val) {
                                            case 'hide':
                                              ChatController.hideChat(
                                                  currentUserNo, peerNo);
                                              break;
                                            case 'unhide':
                                              ChatController.unhideChat(
                                                  currentUserNo, peerNo);
                                              break;
                                            case 'lock':
                                              ChatController.lockChat(
                                                  currentUserNo, peerNo);
                                              break;
                                            case 'unlock':
                                              ChatController.unlockChat(
                                                  currentUserNo, peerNo);
                                              break;
                                            case 'block':
                                              ChatController.block(
                                                  currentUserNo, peerNo);
                                              break;
                                            case 'unblock':
                                              ChatController.accept(
                                                  currentUserNo, peerNo);
                                              Utils.toast('Unblocked.');
                                              break;
                                            case 'tutorial':
                                              Utils.toast(
                                                  'Drag your friend\'s message from left to right to end conversations up until that message.');
                                              Future.delayed(
                                                      Duration(seconds: 2))
                                                  .then((_) {
                                                Utils.toast(
                                                    'Swipe left on the screen to view saved messages.');
                                              });
                                              break;
                                            case 'remove_wallpaper':
                                              _cachedModel!
                                                  .removeWallpaper(peerNo!);
                                              Utils.toast('Wallpaper removed.');
                                              break;
                                            case 'set_wallpaper':
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          HybridImagePicker(
                                                            title:
                                                                'Pick an image',
                                                            callback:
                                                                getWallpaper,
                                                          )));
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) =>
                                            <PopupMenuItem<String>>[
                                          PopupMenuItem<String>(
                                            value: hidden! ? 'unhide' : 'hide',
                                            child: Text(
                                              '${hidden! ? 'Unhide' : 'Hide'} Chat',
                                            ),
                                          ),
                                          PopupMenuItem<String>(
                                            value: locked! ? 'unlock' : 'lock',
                                            child: Text(
                                                '${locked! ? 'Unlock' : 'Lock'} Chat'),
                                          ),
                                          PopupMenuItem<String>(
                                            value: isBlocked()
                                                ? 'unblock'
                                                : 'block',
                                            child: Text(
                                                '${isBlocked() ? 'Unblock' : 'Block'} Chat'),
                                          ),
                                          PopupMenuItem<String>(
                                              value: 'set_wallpaper',
                                              child: Text('Set Wallpaper')),
                                          peer![WALLPAPER] != null
                                              ? PopupMenuItem<String>(
                                                  value: 'remove_wallpaper',
                                                  child:
                                                      Text('Remove Wallpaper'))
                                              : PopupMenuItem<String>(
                                                  child: null,
                                                ),
                                          PopupMenuItem<String>(
                                            child: Text('Show Tutorial'),
                                            value: 'tutorial',
                                          )
                                        ].where((o) => o != null).toList(),
                                      )),
                                  subtitle: chatId!.isNotEmpty
                                      ? Text(
                                          getPeerStatus(peer![LAST_SEEN]),
                                          style: TextStyle(color: Colors.white),
                                        )
                                      : Text('loading…',
                                          style:
                                              TextStyle(color: Colors.white))),
                              elevation: 4,
                              color: Colors.blue,
                            ),
                          ),
                          body: GestureDetector(
                            onTap: () => FocusScope.of(context).unfocus(),
                            child: Stack(
                              children: <Widget>[
                                new Container(
                                  decoration: new BoxDecoration(
                                    image: new DecorationImage(
                                        image: peer![WALLPAPER] == null
                                            ? AssetImage("assets/bg.jpg")
                                            : Image.file(File(peer![WALLPAPER]))
                                                .image,
                                        fit: BoxFit.cover),
                                  ),
                                ),
                                PageView(
                                  children: <Widget>[
                                    Column(
                                      children: [
                                        // List of messages
                                        buildMessages(),
                                        // Input content
                                        isBlocked()
                                            ? Container()
                                            : buildInput(),
                                        MediaQuery.of(context)
                                                        .viewInsets
                                                        .bottom <
                                                    24 &&
                                                showEmojiKeyboard!
                                            ? buildSticker()
                                            : Container(),
                                      ],
                                    ),
                                  ],
                                ),

                                // Loading
                                buildLoading()
                              ],
                            ),
                          )))
                  : Container();
            }))));
  }

  voiceMessage() {}
  deleteVoice() {}
  sendVoice() {}
}

class AttachmentButton extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  final Icon? icon;
  final VoidCallback? onClick;
  final String? subtitle;
  final double? elevation;

  const AttachmentButton(
      {Key? key,
      this.width,
      this.height,
      this.color,
      this.icon,
      @required this.onClick,
      this.subtitle,
      this.elevation})
      : assert(onClick != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          width: width,
          height: height,
          child: IconButton(
            icon: icon!,
            enableFeedback: true,
            onPressed: onClick,
            tooltip: subtitle != null ? subtitle : null,
          ),
        ),
      ],
    );
  }
}
