import 'package:flutter/material.dart';
import 'package:kumchat/models/utils.dart';
import 'package:permission_handler/permission_handler.dart'
    as PermissionHandler;

class OpenSettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Utils.getNTPWrappedWidget(Material(
        color: Colors.grey,
        child: Center(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: ElevatedButton(
                    onPressed: () {
                      PermissionHandler.openAppSettings();
                    },
                    child: Text('Open App Settings'))))));
  }
}
