import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final Telephony telephony = Telephony.instance;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String lastTransaction = "";

  @override
  void initState() {
    super.initState();
    _listenSms();
  }

  void _listenSms() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final body = message.body ?? "";

        if (body.contains("credited") || body.contains("debited")) {
          String type = body.contains("credited") ? "Credited" : "Debited";
          String? amount = _extractAmount(body);

          String transaction = "$type: $amount";
          setState(() {
            lastTransaction = transaction;
          });

          _showNotification(transaction);
        }
      },
      listenInBackground: false,
    );
  }

  String? _extractAmount(String body) {
    // Simple regex to extract amount like 500, ₹500, Rs.500 etc.
    final regex = RegExp(r'(\₹|Rs\.?\s?)(\d+(\.\d{1,2})?)');
    final match = regex.firstMatch(body);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  Future<void> _showNotification(String transaction) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'transaction_channel',
      'Transactions',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New Transaction',
      transaction,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Expense Tracker")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Last Transaction Detected:"),
              Text(lastTransaction, style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (lastTransaction.isNotEmpty) {
                    _askUserCategory(lastTransaction);
                  }
                },
                child: Text("Add Transaction"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _askUserCategory(String transaction) async {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Category"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "e.g., Food, Travel"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String category = controller.text;
                // ✅ Save transaction + category in DB (sqflite/hive)
                print("Saved: $transaction as $category");
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
