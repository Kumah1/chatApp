import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:kumchat/pages/uploader.dart';

class ImageCapture extends StatefulWidget {
  final String? userId;
  ImageCapture({Key? key, this.userId}) : super(key: key);
  createState() => _ImageCaptureState();
}

class _ImageCaptureState extends State<ImageCapture> {
  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    File selected = await ImagePicker.pickImage(source: source);
    setState(() {
      _imageFile = selected;
    });
  }

  void _clear() {
    setState(() => _imageFile = null);
  }

  Future<void> _cropImage() async {
    File? cropped = await ImageCropper.cropImage(sourcePath: _imageFile!.path);
    setState(() {
      _imageFile = cropped ?? _imageFile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: () => _pickImage(ImageSource.camera)),
            SizedBox(
              width: 200.0,
            ),
            IconButton(
                icon: Icon(Icons.photo_library),
                onPressed: () => _pickImage(ImageSource.gallery))
          ],
        ),
      ),
      body: ListView(
        children: _imageFile != null
            ? <Widget>[
                Image.file(_imageFile!),
                Row(
                  children: <Widget>[
                    ElevatedButton(
                        onPressed: _cropImage, child: Icon(Icons.crop)),
                    ElevatedButton(
                        onPressed: _clear, child: Icon(Icons.refresh)),
                  ],
                ),
                Uploader(
                  file: _imageFile!,
                  userId: widget.userId!,
                )
              ]
            : <Widget>[],
      ),
    );
  }
}
