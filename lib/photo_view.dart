import 'package:flutter/material.dart';
import 'package:kumchat/models/utils.dart';
import 'package:kumchat/open_settings.dart';
import 'package:photo_view/photo_view.dart';
import 'package:kumchat/services/save.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:permission_handler/permission_handler.dart';

class PhotoViewWrapper extends StatelessWidget {
  const PhotoViewWrapper(
      {this.imageProvider,
      this.loadingChild,
      this.backgroundDecoration,
      this.minScale,
      this.maxScale,
      @required this.tag});

  final String? tag;
  final ImageProvider? imageProvider;
  final Widget? loadingChild;
  final BoxDecoration? backgroundDecoration;
  final dynamic minScale;
  final dynamic maxScale;

  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Utils.checkAndRequestPermission(Permission.storage).then((res) {
              if (res) {
                Save.saveToDisk(imageProvider!, tag!);
                Utils.toast('Saved!');
              } else {
                Utils.showRationale(
                    'Permission to access storage needed to save photos to your phone.');
                Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => OpenSettings()));
              }
            });
          },
          child: Icon(Icons.file_download),
        ),
        body: Container(
            constraints: BoxConstraints.expand(
              height: MediaQuery.of(context).size.height,
            ),
            child: PhotoView(
              imageProvider: imageProvider,
              backgroundDecoration: backgroundDecoration!,
              minScale: minScale,
              maxScale: maxScale,
              //heroTag: tag,
            ))));
  }
}
