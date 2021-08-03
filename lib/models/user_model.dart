// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_database/firebase_database.dart';
import 'package:kumchat/models/const.dart';

class UserM {
  String? key;
  String id;
  String phone;
  String countryCode;
  String authenticationType;
  String answer;
  String passCode;
  String question;
  String username;
  String imageUrl;
  String status;
  String search;
  String typing;
  String offlineTime;

  UserM(
      this.id,
      this.phone,
      this.countryCode,
      this.authenticationType,
      this.answer,
      this.passCode,
      this.question,
      this.username,
      this.imageUrl,
      this.status,
      this.search,
      this.typing,
      this.offlineTime);

  UserM.fromSnapshot(DataSnapshot snapshot)
      : key = snapshot.key,
        id = snapshot.value["id"],
        phone = snapshot.value["phoneNo"],
        countryCode = snapshot.value[COUNTRY_CODE],
        authenticationType = snapshot.value[AUTHENTICATION_TYPE],
        answer = snapshot.value[ANSWER],
        passCode = snapshot.value[PASSCODE],
        question = snapshot.value[QUESTION],
        username = snapshot.value["username"],
        imageUrl = snapshot.value["imageURL"],
        status = snapshot.value["status"],
        search = snapshot.value["search"],
        typing = snapshot.value["typing"],
        offlineTime = snapshot.value["offlineTime"];

  toJson(String userid, String phone, String countryCode, String authType,
      String name) {
    return {
      "id": userid,
      "phoneNo": phone,
      COUNTRY_CODE: countryCode,
      AUTHENTICATION_TYPE: authType,
      ANSWER: "",
      PASSCODE: "",
      QUESTION: "",
      "username": name,
      "imageURL":
          "https://firebasestorage.googleapis.com/v0/b/f-kumchat.appspot.com/o/kumchat2.png?alt=media&token=507a3cb6-0621-488a-8597-28502a9feedc",
      "status": "online",
      "search": name.toLowerCase(),
      "typing": "no",
      "offlineTime": "null"
    };
  }
}
