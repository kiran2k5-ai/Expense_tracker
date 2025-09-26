import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Your existing screens
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/monthly_report_screen.dart';

final Telephony telephony = Telephony.instance;
final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);

  await notifications.initialize(initSettings);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String lastTransaction = "";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenSms();
  }

  void _requestPermissions() async {
    bool? granted = await telephony.requestPhoneAndSmsPermissions;
    if (granted == false) {
      print("⚠️ SMS Permission not granted");
    }
  }

  void _listenSms() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) {
        final body = message.body ?? "";

        if (body.toLowerCase().contains("credited") ||
            body.toLowerCase().contains("debited")) {
          String type =
              body.toLowerCase().contains("credited") ? "Credited" : "Debited";
          String? amount = _extractAmount(body);

          String transaction = "$type ${amount ?? ""}";
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
    final regex =
        RegExp(r'(\₹|rs\.?\s?)(\d+(\.\d{1,2})?)', caseSensitive: false);
    final match = regex.firstMatch(body);
    return match?.group(0);
  }

  Future<void> _showNotification(String transaction) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'txn_channel',
      'Transactions',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await notifications.show(
      0,
      'New Transaction',
      transaction,
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Manager',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/add': (context) => const AddExpenseScreen(),
        '/main': (context) => const MainScaffold(), // ✅ include this too
        '/monthly-report': (context) => const MonthlyReportScreen(),
      },
    );
  }
}
