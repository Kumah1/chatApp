import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kumchat/models/utils.dart';

class FilesPicker extends StatefulWidget {
  FilesPicker({Key? key, @required this.title, @required this.callback})
      : super(key: key);

  final String? title;
  final Function? callback;
  @override
  _FilesPickerState createState() => new _FilesPickerState();
}

class _FilesPickerState extends State<FilesPicker> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _fileName;
  String? _path;
  Map<String, String>? _paths;
  String? _extension;
  bool _loadingPath = false;
  bool _multiPick = true;
  FileType _pickingType = FileType.custom;
  File? file;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _extension = "ttf, doc, pdf, docx, apk, zip, exe, txt, xlsx";
  }

  void _openFileExplorer() async {
    setState(() => _loadingPath = true);
    try {
      if (_multiPick) {
        _path = null;
        file = await FilePicker.getFile();
        _paths = await FilePicker.getMultiFilePath(
            type: _pickingType,
            allowedExtensions: (_extension?.isNotEmpty ?? false)
                ? _extension?.replaceAll(' ', '').split(',')
                : null);
      } else {
        _paths = null;
        file = await FilePicker.getFile();
        _path = await FilePicker.getFilePath(
            type: _pickingType,
            allowedExtensions: (_extension?.isNotEmpty ?? false)
                ? _extension?.replaceAll(' ', '').split(',')
                : null);
      }
    } on PlatformException catch (e) {
      print("Unsupported operation" + e.toString());
    }
    if (!mounted) return;
    setState(() {
      _loadingPath = false;
      _fileName = _path != null
          ? _path!.split('/').last
          : _paths != null
              ? _paths!.keys.toString()
              : '...';
    });
  }

  void _clearCachedFiles() {
    FilePicker.clearTemporaryFiles().then((result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result ? Colors.green : Colors.red,
          content: Text((result
              ? 'Temporary files removed with success.'
              : 'Failed to clean temporary files')),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(WillPopScope(
      child: new MaterialApp(
        home: new Scaffold(
          key: _scaffoldKey,
          appBar: new AppBar(
            title: Text(widget.title!),
            actions: <Widget>[
              IconButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                  });
                  widget.callback!(file).then((imageUrl) {
                    Navigator.pop(context, imageUrl);
                  });
                },
                icon: Icon(Icons.check_circle),
              )
            ],
          ),
          body: new Center(
              child: new Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: new SingleChildScrollView(
              child: Stack(
                children: <Widget>[
                  new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Padding(
                        padding: const EdgeInsets.only(top: 50.0, bottom: 20.0),
                        child: Column(
                          children: <Widget>[
                            new ElevatedButton(
                              onPressed: () => _openFileExplorer(),
                              child: new Text("Picker audio file to send"),
                            ),
                            new ElevatedButton(
                              onPressed: () => _clearCachedFiles(),
                              child: new Text("Clear temporary files"),
                            ),
                          ],
                        ),
                      ),
                      new Builder(
                        builder: (BuildContext context) => _loadingPath
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: const CircularProgressIndicator())
                            : _path != null || _paths != null
                                ? new Container(
                                    padding:
                                        const EdgeInsets.only(bottom: 30.0),
                                    height: MediaQuery.of(context).size.height *
                                        0.50,
                                    child: new Scrollbar(
                                        child: new ListView.separated(
                                      itemCount:
                                          _paths != null && _paths!.isNotEmpty
                                              ? _paths!.length
                                              : 1,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        final bool isMultiPath =
                                            _paths != null &&
                                                _paths!.isNotEmpty;
                                        final String name = 'File $index: ' +
                                            (isMultiPath
                                                ? _paths!.keys.toList()[index]
                                                : _fileName ?? '...');
                                        final path = isMultiPath
                                            ? _paths!.values
                                                .toList()[index]
                                                .toString()
                                            : _path;

                                        return new ListTile(
                                          title: new Text(
                                            name,
                                          ),
                                          subtitle: new Text(path!),
                                        );
                                      },
                                      separatorBuilder:
                                          (BuildContext context, int index) =>
                                              new Divider(),
                                    )),
                                  )
                                : new Container(),
                      ),
                    ],
                  ),
                  Positioned(
                    child: isLoading
                        ? Container(
                            child: Center(
                              child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue)),
                            ),
                            color: Colors.blue.withOpacity(0.8),
                          )
                        : Container(),
                  )
                ],
              ),
            ),
          )),
        ),
      ),
      onWillPop: () => Future.value(!isLoading),
    ));
  }
}
