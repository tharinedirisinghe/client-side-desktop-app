import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.grey[800],
        appBarTheme: const AppBarTheme(
          color: Colors.grey,
          toolbarTextStyle:
              TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          displayMedium: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w500, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late IOWebSocketChannel channel;
  String assignmentName = "Sample Assignment 01";
  String studentIndex = 'Sample Index';
  String studentName = 'Sample Name';
  String remainingTime = 'Sample Time Left : hours:minutes:seconds';
  List<String> announcements = [
    "Sample Announcement 1",
    "Sample Announcement 2",
    "Sample Announcement 3",
    "Sample Announcement 4"
  ];

  @override
  void initState() {
    super.initState();
    checkPCName();
  }

  Future<void> setPCName(String pcName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    print(
        'Saving PC name to: $path/pc_name.txt'); // Add this line to print the path
    final file = File('${directory.path}/pc_name.txt');
    await file.writeAsString(pcName);
  }

  Future<String?> getPCName() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pc_name.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      print("Error reading PC name: $e");
    }
    return null;
  }

  Future<void> checkPCName() async {
    String? pcName = await getPCName();
    if (pcName == null) {
      // Ask user to set PC name during installation
      await showPCNameDialog();
    } else {
      connectToWebSocket(pcName);
    }
  }

  Future<void> showPCNameDialog() async {
    String? pcName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter PC Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'PC Name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );

    if (pcName != null && pcName.isNotEmpty) {
      await setPCName(pcName);
      connectToWebSocket(pcName);
    }
  }

  void connectToWebSocket(String pcName) {
    channel =
        IOWebSocketChannel.connect('ws://d688-212-104-231-218.ngrok-free.app');

    // Send PC name to backend
    channel.sink.add(pcName);

    // Listen for messages from the WebSocket
    channel.stream.listen((message) {
      var data = message.split(',');
      if (data[0] == 'activate') {
        String studentIndex = data[1];
        String examId = data[2];
        confirmReceipt();
        fetchExamDetails(examId);
        fetchStudentDetails(studentIndex);
      } else if (data[0] == 'deactivate') {
        resetToSampleData();
        // You can add a confirmation log here if needed
        print('Received deactivate message');
        // Send confirmation message to backend
        channel.sink.add('deactivate_received');
      } else if (data[0] == 'timer') {
        updateTimer(data[1]); // data[1] is the timer value in seconds
        print('Received timer');
        channel.sink.add('timer_received');
      }
    });
  }

  String formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void updateTimer(String seconds) {
    int timerInSeconds = int.parse(seconds);
    setState(() {
      remainingTime = 'Time Left : ${formatTime(timerInSeconds)}';
    });
  }

  void resetToSampleData() {
    setState(() {
      assignmentName = "Sample Assignment 01";
      studentIndex = 'Sample Index';
      studentName = 'Sample Name';
      remainingTime = 'Sample Time Left : hours:minutes:seconds';
      announcements = [
        "Sample Announcement 1",
        "Sample Announcement 2",
        "Sample Announcement 3",
        "Sample Announcement 4"
      ];
    });
  }

  void confirmReceipt() {
    print(
        'Received activate message'); // This will print to the console as a confirmation

    channel.sink
        .add('activate_received'); // Send confirmation message to backend
  }

  void fetchExamDetails(String examId) async {
    final url =
        'https://d688-212-104-231-218.ngrok-free.app/api/v1/exams/$examId';
    final headers = {
      'Authorization': 'Bearer "ngrok-skip-browser-warning": "69420"',
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        // Adjusted to update state variables
        setState(() {
          assignmentName = jsonData['module'];
          announcements = jsonData['instructions'] != null
              ? jsonData['instructions'].split(',').toList()
              : [];
        });

        print('Exam details fetched successfully: $jsonData');
      } else {
        print(
            'Failed to load exam details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to load exam details: $error');
    }
  }

  Future<void> fetchStudentDetails(String studentId) async {
    final url =
        'https://d688-212-104-231-218.ngrok-free.app/api/v1/students/$studentId';
    final headers = {
      'Authorization': 'Bearer "ngrok-skip-browser-warning": "69420"',
      'Content-Type': 'application/json',
    };

    try {
      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);

        // Adjusted to update state variables
        setState(() {
          studentIndex = jsonData['stu_id'];
          studentName = jsonData['name'];
        });
        print('Student details fetched successfully: $jsonData');
      } else {
        print(
            'Failed to load student details. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Failed to load student details: $error');
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 100,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/itfac-logo.png",
              height: 80,
            ),
            const SizedBox(width: 20),
            Text(
              assignmentName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Container(
            width: 300,
            color: Colors.grey[300], // Light grey
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[700], // Dark grey
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Announcements",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (var announcement in announcements)
                  ListTile(
                    leading: const Icon(Icons.brightness_1,
                        size: 10), // Bullet point icon
                    title: Text(announcement),
                  )
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Light grey
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      studentIndex,
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Light grey
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      studentName,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300], // Light grey
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      remainingTime,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
