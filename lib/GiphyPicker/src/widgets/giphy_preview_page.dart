import 'package:flutter/material.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:giphy_picker/giphy_picker.dart';

/// Presents a Giphy preview image.
class GiphyPreviewPage extends StatelessWidget {
  final GiphyGif? gif;
  final Widget? title;
  final ValueChanged<GiphyGif?>? onSelected;

  const GiphyPreviewPage(
      {@required this.gif, @required this.onSelected, this.title});

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.light(),
        child: Scaffold(
            appBar: AppBar(title: title, actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () {
                    onSelected!(gif);
                    Navigator.pop(context);
                  })
            ]),
            body: SafeArea(
                child: Center(child: GiphyImage.original(gif: gif)),
                bottom: false)));
  }
}
