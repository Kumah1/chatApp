import 'package:firebase_database/firebase_database.dart';

class MessageModel {
  String? key;
  String sender;
  String receiver;
  String time;
  String text;
  bool unread;
  String imageView;
  String type;

  MessageModel(this.sender, this.receiver, this.text, this.type, this.time,
      this.imageView, this.unread);

  MessageModel.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        sender = snapshot.value["sender"],
        receiver = snapshot.value["receiver"],
        imageView = snapshot.value["imageURL"],
        text = snapshot.value["message"],
        unread = snapshot.value["isSeen"],
        time = snapshot.value["time"],
        type = snapshot.value["type"];

  toJson() {
    return {
      "sender": sender,
      "receiver": receiver,
      "imageURL": imageView,
      "message": text,
      "isSeen": unread,
      "time": time,
      "type": type
    };
  }
}
