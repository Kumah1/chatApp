import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

AppInfoState? pageState;

class AppInfo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    pageState = AppInfoState();
    return pageState!;
  }
}

class AppInfoState extends State<AppInfo> {
  String appName = "";
  String appID = "";
  String version = "";
  String buidNumber = "";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAppInfo();
  }

  void getAppInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      appName = packageInfo.appName;
      appID = packageInfo.packageName;
      version = packageInfo.version;
      buidNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("App Information"),
      ),
      body: ListView(
        children: <Widget>[
          Card(
            child: ListTile(
              title: Text("App Name"),
              subtitle: Text(appName),
            ),
          ),
          Card(
            child: ListTile(
              title: Text("Package Name (App ID)"),
              subtitle: Text(appID),
            ),
          ),
          Card(
            child: ListTile(
              title: Text("Version"),
              subtitle: Text(version),
            ),
          ),
          Card(
            child: ListTile(
              title: Text("Build Number"),
              subtitle: Text(buidNumber),
            ),
          ),
        ],
      ),
    );
  }
}
