import 'dart:io';

import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:image_picker/image_picker.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/open_settings.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:permission_handler/permission_handler.dart';

class VideoPicker extends StatefulWidget {
  VideoPicker({Key? key, @required this.title, @required this.callback})
      : super(key: key);

  final String? title;
  final Function? callback;
  @override
  _VideoPickerState createState() => _VideoPickerState();
}

class _VideoPickerState extends State<VideoPicker> {
  File? _imageFile;

  bool isLoading = false;

  Future<void> _pickVideo(ImageSource source) async {
    File selected = await ImagePicker.pickVideo(source: source);
    setState(() {
      _imageFile = selected;
    });
  }

  Widget _buildImage() {
    if (_imageFile != null) {
      return new Image.file(_imageFile!);
    } else {
      return new Text('Take a video to send',
          style: new TextStyle(fontSize: 18.0, color: Colors.black));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(WillPopScope(
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: new AppBar(
            title: new Text(widget.title!),
            backgroundColor: Colors.blue,
            actions: _imageFile != null
                ? <Widget>[
                    IconButton(
                        icon: Icon(Icons.check, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });
                          widget.callback!(_imageFile).then((imageUrl) {
                            Navigator.pop(context, imageUrl);
                          });
                        }),
                    SizedBox(
                      width: 8.0,
                    )
                  ]
                : []),
        body: Stack(children: [
          new Column(children: [
            new Expanded(child: new Center(child: _buildImage())),
            _buildButtons()
          ]),
          Positioned(
            child: isLoading
                ? Container(
                    child: Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue)),
                    ),
                    color: Colors.blue.withOpacity(0.8),
                  )
                : Container(),
          )
        ]),
      ),
      onWillPop: () => Future.value(!isLoading),
    ));
  }

  Widget _buildButtons() {
    return new ConstrainedBox(
        constraints: BoxConstraints.expand(height: 60.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildActionButton(new Key('wait'), Icons.video_library, () {
              Utils.checkAndRequestPermission(Permission.storage).then((res) {
                if (res) {
                  _pickVideo(ImageSource.gallery);
                } else {
                  Utils.showRationale(
                      'Permission to access gallery needed to send photos to your friends.');
                  Navigator.pushReplacement(
                      context,
                      new MaterialPageRoute(
                          builder: (context) => OpenSettings()));
                }
              });
            }),
          ],
        ));
  }

  Widget _buildActionButton(Key key, IconData icon, Function()? onPressed) {
    return new Expanded(
      child: new ElevatedButton(
          key: key,
          child: Icon(icon, size: 30.0),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              Colors.blue.withOpacity(0.8),
            ),
            textStyle: MaterialStateProperty.all(
              TextStyle(color: Colors.white),
            ),
          ),
          onPressed: onPressed),
    );
  }
}
