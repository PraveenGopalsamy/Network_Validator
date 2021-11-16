import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('notify_logo');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    if (payload != null) {
      debugPrint('payload: $payload');
    }
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connectivity Tester',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const MyHomePage(title: 'Connectivity Tester'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String _connectionMedium;
  late String title;
  late String body;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  Timer? _timer;
  late int _duration;
  late String _connectionStatus;
  late bool isCheckingStatus;
  late bool _disableTimerDuration;
  late TextEditingController _errorController;
  late TextEditingController _stabilityController;

  @override
  void initState() {
    initConnectivity();
    isCheckingStatus = true;
    _disableTimerDuration = false;
    _connectionMedium = 'None';
    _connectionStatus = '';
    _errorController = TextEditingController();
    _stabilityController = TextEditingController();
    _errorController.text = '3';
    _stabilityController.text = '3';
    body = '';
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    super.initState();
  }

  @override
  void dispose() {
    _cancelTimer();
    _connectivitySubscription.cancel();
    _errorController.dispose();
    _stabilityController.dispose();
    super.dispose();
  }

  void _invokeNotification() {
    onButtonPressed();
    onButtonPressed();
  }

  void _updateDuration() {
    if (_connectionMedium == 'None') {
      _duration = int.parse(_errorController.text);
    } else {
      _duration = int.parse(_stabilityController.text);
    }
  }

  void _startTimer() {
    _updateDuration();
    bool prevConnectionStatus = _connectionStatus == 'Online ! ✔️';
    _timer = Timer.periodic(
      Duration(seconds: _duration),
      (Timer timer) async {
        if (timer.tick % _duration == 0) {
          bool networkStatus = await fetchInternetStatus();
          if (networkStatus != prevConnectionStatus) {
            _invokeNotification();
            _cancelTimer();
            _startTimer();
          }
          prevConnectionStatus = networkStatus;
        }
      },
    );
  }

  void _cancelTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
  }

  Future<void> initConnectivity() async {
    ConnectivityResult result = ConnectivityResult.none;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<bool> fetchInternetStatus() async {
    var url =
        Uri.https('www.googleapis.com', '/books/v1/volumes', {'q': '{http}'});
    try {
      await http.get(url);
      title = '✔️ Hurray!!! Network Connected!';
      _connectionStatus = 'Online ! ✔️';
      isCheckingStatus = false;
      setState(() {});
      return true;
    } on SocketException {
      title = '❌ Oops!!! Network Disconnected!';
      _connectionStatus = 'Offline ! ❌';
      isCheckingStatus = false;
      setState(() {});
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Internet Connectivity...'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
                height: MediaQuery.of(context).size.height * 0.375,
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.asset(_connectionStatus == 'Online ! ✔️'
                        ? 'assets/online.jpg'
                        : 'assets/offline.jpg'))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(' Connection Medium : '),
                Text(_connectionMedium)
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(' Connection Status : '),
                isCheckingStatus
                    ? const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ))
                    : Text(_connectionStatus)
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(' Reconnect duration (in sec) :'),
                Tooltip(
                    message:
                        'Rechecks the internet connection with a given interval of time, when the internet has not connected.',
                    preferBelow: false,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(5),
                    showDuration: const Duration(seconds: 4),
                    triggerMode: TooltipTriggerMode.tap,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Icon(Icons.info, size: 18),
                    )),
                SizedBox(
                  width: 40,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    controller: _errorController,
                    enabled: !_disableTimerDuration,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      contentPadding: const EdgeInsets.all(5.0),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                      signed: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(' Connection Stability duration  (in sec) :'),
                Tooltip(
                    message:
                        'Rechecks the internet connection with a given interval of time, when the internet has been connected.',
                    preferBelow: false,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.all(5),
                    showDuration: const Duration(seconds: 4),
                    triggerMode: TooltipTriggerMode.tap,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: Icon(Icons.info, size: 18),
                    )),
                SizedBox(
                  width: 40,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    controller: _stabilityController,
                    enabled: !_disableTimerDuration,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0)),
                      contentPadding: const EdgeInsets.all(5.0),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                      signed: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
                onPressed: () {
                  if (!isCheckingStatus) {
                    isCheckingStatus = true;
                    setState(() {});
                    fetchInternetStatus();
                  }
                },
                icon: const Icon(Icons.signal_cellular_alt_rounded),
                label: const Text('Check Connection Status')),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        _disableTimerDuration = true;
                      });
                      _startTimer();
                    },
                    child: const Text('Begin Timer')),
                TextButton(
                    onPressed: () {
                      _cancelTimer();
                      setState(() {
                        _disableTimerDuration = false;
                      });
                    },
                    child: const Text('End Timer'))
              ],
            )
          ],
        ),
      ),
    );
  }

  void onButtonPressed() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your channel id', 'your channel name',
            channelDescription: 'your channel description',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
            enableVibration: false,
            ticker: 'ticker');
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    switch (result) {
      case ConnectivityResult.wifi:
        _duration = int.parse(_stabilityController.text);
        body = 'Status - Connected with Wifi network';
        _connectionMedium = 'WIFI Network';
        break;
      case ConnectivityResult.mobile:
        _duration = int.parse(_stabilityController.text);
        body = 'Status - Connected with Mobile network';
        _connectionMedium = 'Mobile Network';
        break;
      case ConnectivityResult.none:
        _duration = int.parse(_errorController.text);
        body = 'Status - Not connected with network';
        _connectionMedium = 'None';
        break;
    }
    await fetchInternetStatus();
    _invokeNotification();
  }
}
