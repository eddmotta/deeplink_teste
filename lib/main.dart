import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  String _initialLink;
  String _latestLink = 'Unknown';
  Uri _latestUri;

  StreamSubscription _sub;

  @override
  initState() {
    super.initState();
    initPlatformStateForStringUniLinks();
  }

  @override
  void dispose() {
    if (_sub != null) _sub.cancel();
    super.dispose();
  }

  /// An implementation using a [String] link
  Future<void> initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    _sub = getLinksStream().listen((String link) {
      if (!mounted) return;
      setState(() {
        _latestLink = link ?? 'Unknown';
        _latestUri = null;
        try {
          if (link != null) _latestUri = Uri.parse(link);
        } on FormatException {}
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
        _latestUri = null;
      });
    });

    // Attach a second listener to the stream
    getLinksStream().listen((String link) {
      print('got link: $link');
    }, onError: (err) {
      print('got err: $err');
    });

    // Get the latest link
    String initialLink;
    Uri initialUri;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      initialLink = await getInitialLink();
      print('initial link: $initialLink');
      if (initialLink != null) initialUri = Uri.parse(initialLink);
    } on PlatformException {
      initialLink = 'Failed to get initial link.';
      initialUri = null;
    } on FormatException {
      initialLink = 'Failed to parse the initial link as Uri.';
      initialUri = null;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
    setState(() {
      _latestLink = initialLink;
      _latestUri = initialUri;
    });
  }


  @override
  Widget build(BuildContext context) {
    final queryParams = _latestUri?.queryParametersAll?.entries?.toList();

    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app'),
        ),
        body: new ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            new ListTile(
              title: const Text('Initial Link'),
              subtitle: new Text('$_initialLink'),
            ),
            new ListTile(
              title: const Text('Link'),
              subtitle: new Text('$_latestLink'),
            ),
            new ListTile(
              title: const Text('Uri Path'),
              subtitle: new Text('${_latestUri?.path}'),
            ),
            new ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Query params'),
              children: queryParams?.map((item) {
                return new ListTile(
                  title: new Text('${item.key}'),
                  trailing: new Text('${item.value?.join(', ')}'),
                );
              })?.toList() ??
                  <Widget>[
                    new ListTile(
                      dense: true,
                      title: const Text('null'),
                    ),
                  ],
            ),
            new Divider(),
            RaisedButton(child: Text("oi"),onPressed: (){

            },)
          ],
        ),
      ),
    );
  }
}
