import 'dart:core';
import 'dart:async';
import 'dart:io';
import 'package:async/async.dart' show StreamGroup;
import 'package:kumchat/models/const.dart';
import 'package:kumchat/models/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localstorage/localstorage.dart';

class DataModel extends Model {
  Map<String, Map<String, dynamic>> userData =
      new Map<String, Map<String, dynamic>>();

  Map<String, Future> _messageStatus = new Map<String, Future>();

  _getMessageKey(String peerNo, int timestamp) => '$peerNo$timestamp';

  getMessageStatus(String peerNo, int timestamp) {
    final key = _getMessageKey(peerNo, timestamp);
    return _messageStatus[key] ?? true;
  }

  bool _loaded = false;

  LocalStorage _storage = LocalStorage('model');

  addMessage(String peerNo, int timestamp, Future future) {
    final key = _getMessageKey(peerNo, timestamp);
    future.then((_) {
      _messageStatus.remove(key);
    });
    _messageStatus[key] = future;
  }

  addUser(DocumentSnapshot user) {
    userData[user.data()[PHONE]] = user.data();
    notifyListeners();
  }

  setWallpaper(String phone, File image) async {
    if (image != null) {
      final dir = await getDir();
      int now = DateTime.now().millisecondsSinceEpoch;
      String path = '${dir.path}/WALLPAPER-$phone-$now';
      await image.copy(path);
      userData[phone]![WALLPAPER] = path;
      updateItem(phone, {WALLPAPER: path});
      notifyListeners();
    }
  }

  removeWallpaper(String phone) {
    userData[phone]![WALLPAPER] = null;
    String path = userData[phone]![ALIAS_AVATAR];
    if (path != null) {
      File(path).delete();
      userData[phone]![WALLPAPER] = null;
    }
    updateItem(phone, {WALLPAPER: null});
    notifyListeners();
  }

  getDir() async {
    //final Directory extDir = new Directory('/storage/emulated/0/');
    //final String dirPath = '${extDir.path}Kumchat/Wallpapers';
    //await Directory(dirPath).create(recursive: true);
    return await getApplicationDocumentsDirectory();
  }

  updateItem(String key, Map<String, dynamic> value) {
    Map<String, dynamic> old = _storage.getItem(key) ?? Map<String, dynamic>();
    old.addAll(value);
    _storage.setItem(key, old);
  }

  setAlias(String aliasName, File image, String phone) async {
    userData[phone]![ALIAS_NAME] = aliasName;
    if (image != null) {
      final dir = await getDir();
      int now = DateTime.now().millisecondsSinceEpoch;
      String path = '${dir.path}/$phone-$now';
      await image.copy(path);
      userData[phone]![ALIAS_AVATAR] = path;
    }
    updateItem(phone, {
      ALIAS_NAME: userData[phone]![ALIAS_NAME],
      ALIAS_AVATAR: userData[phone]![ALIAS_AVATAR],
    });
    notifyListeners();
  }

  removeAlias(String phone) {
    userData[phone]![ALIAS_NAME] = null;
    String path = userData[phone]![ALIAS_AVATAR];
    if (path != null) {
      File(path).delete();
      userData[phone]![ALIAS_AVATAR] = null;
    }
    updateItem(phone, {ALIAS_NAME: null, ALIAS_AVATAR: null});
    notifyListeners();
  }

  bool get loaded => _loaded;

  Map<String, dynamic>? get currentUser => _currentUser;

  Map<String, dynamic>? _currentUser;

  Map<String, int> get lastSpokenAt => _lastSpokenAt;

  Map<String, int> _lastSpokenAt = {};

  getChatOrder(List<String> chatsWith, String currentUserNo) {
    List<Stream<QuerySnapshot>> messages = [];
    chatsWith.forEach((otherNo) {
      String chatId = Utils.getChatId(currentUserNo, otherNo);
      messages.add(FirebaseFirestore.instance
          .collection(MESSAGES)
          .doc(chatId)
          .collection(chatId)
          .snapshots());
    });
    StreamGroup.merge(messages).listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot message = snapshot.docs.last;
        _lastSpokenAt[message[FROM] == currentUserNo
            ? message[TO]
            : message[FROM]] = message[TIMESTAMP];
        notifyListeners();
      }
    });
  }

  DataModel(String currentUserNo) {
    FirebaseFirestore.instance
        .collection(USERS)
        .doc(currentUserNo)
        .snapshots()
        .listen((user) {
      _currentUser = user.data();
      notifyListeners();
    });
    _storage.ready.then((ready) {
      if (ready) {
        FirebaseFirestore.instance
            .collection(USERS)
            .doc(currentUserNo)
            .collection(CHATS_WITH)
            .doc(CHATS_WITH)
            .get()
            .then((_chatsWith) {
          if (_chatsWith.data != null) {
            List<Stream<DocumentSnapshot>> users = [];
            List<String> peers = [];
            try {
              _chatsWith.data().entries.forEach((_data) {
                peers.add(_data.key);
                users.add(FirebaseFirestore.instance
                    .collection(USERS)
                    .doc(_data.key)
                    .snapshots());
                if (userData[_data.key] != null) {
                  userData[_data.key]![CHAT_STATUS] = _chatsWith[_data.key];
                }
              });
            } catch (Exception) {}
            getChatOrder(peers, currentUserNo);
            notifyListeners();
            Map<String, Map<String, dynamic>> newData =
                Map<String, Map<String, dynamic>>();
            StreamGroup.merge(users).listen((user) {
              if (user.data != null) {
                newData[user[PHONE]] = user.data();
                newData[user[PHONE]]![CHAT_STATUS] = _chatsWith[user[PHONE]];
                Map<String, dynamic> _stored = _storage.getItem(user[PHONE]);
                if (_stored != null) {
                  newData[user[PHONE]]!.addAll(_stored);
                }
              }
              userData = Map.from(newData);
              notifyListeners();
            });
          }
          if (!_loaded) {
            _loaded = true;
            notifyListeners();
          }
        });
      }
    });
  }
}
