import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myway/firebase_options.dart';
import 'package:myway/screen/notice/notice_list_screen.dart';
import 'package:myway/screen/notice/notice_screen.dart';
import 'package:myway/screen/home/park_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'provider/activity_log_provider.dart';
import 'provider/map_provider.dart';
import 'provider/step_provider.dart';
import 'provider/user_provider.dart';
import 'provider/weather_provider.dart';
import 'provider/park_data_provider.dart'; // ParkDataProvider 임포트

import 'screen/setting/find_password_screen.dart';
import 'screen/home/home_screen.dart';
import 'screen/login/signup_screen.dart';
import 'screen/map/map_screen.dart';
import 'screen/setting/nickname_change_screen.dart';
import 'screen/setting/change_password_screen.dart';
import 'screen/login/signIn_screen.dart';
import 'screen/setting/customer_center_screen.dart';
import 'screen/setting/setting_screen.dart';
import 'temp/test_drawer.dart';
import 'temp/test_map.dart';

Future<void> main() async {
  print('initial commit for dev_2');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(
          create: (context) => WeatherProvider()..loadWeather(),
        ),
        ChangeNotifierProvider(create: (context) => StepProvider()),
        ChangeNotifierProvider(create: (context) => MapProvider()),
        ChangeNotifierProvider(create: (context) => ActivityLogProvider()),
        ChangeNotifierProvider(
          create: (context) => ParkDataProvider(),
        ), // ParkDataProvider 추가
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(fontFamily: 'Freesentation'),
        // home: const AuthWrapper(),
        home: AuthWrapper(),
        // initialRoute: 'home',
        routes: {
          'signUp': (context) => const SignUpScreen(),
          'signIn': (context) => const SigninScreen(),
          'home': (context) => const HomeScreen(),
          'map': (context) => const MapScreen(),
          'findPassword': (context) => const FindPasswordScreen(),
          'setting': (context) => const SettingScreen(),
          'changeNickname': (context) => const NicknameChangeScreen(),
          'changePassword': (context) => const ChangePasswordScreen(),
          'customerCenter': (context) => const CustomerCenterScreen(),
          'test': (context) => const TestMapScreen(),
          'testMap': (context) => const MapInputScreen(),
          'noticeList': (context) => const NoticeListScreen(),
          'notice': (context) => const NoticeScreen(),
          'parkList': (context) => const ParkListScreen(initialTabIndex: 0),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('에러가 발생하였습니다.'));
        } else if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const SigninScreen();
        }
      },
    );
  }
}
