import 'dart:io' as File;

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_database/firebase_database.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Uploader extends StatefulWidget {
  final File.File? file;
  final String? userId;
  Uploader({Key? key, this.file, this.userId}) : super(key: key);
  createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  StorageUploadTask? _uploadTask;
  Uri? imageUri;

  void _startUpload() async {
    String filePath = 'images/${DateTime.now()}.png';

    setState(() {
      _uploadTask = _storage.ref().child(filePath).putFile(widget.file);
      // as StorageDataUploadTask?;
    });
    var dowurl = await _uploadTask!.future.then((value) => value.downloadUrl);
    String mUri = dowurl.toString();
    var st = {'imageURL': mUri};
    _database.reference().child("Users").child(widget.userId).update(st);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      TextButton.icon(
          onPressed: _startUpload,
          icon: Icon(Icons.cloud_upload),
          label: Text('Upload to Firebase'))
    ]);
  }
}
