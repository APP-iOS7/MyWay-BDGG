import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:myway/firebase_options.dart';
import 'package:myway/screen/recommended_course_screen.dart';
import 'package:provider/provider.dart';

import 'screen/notice_screen.dart';
import 'provider/map_provider.dart';
import 'provider/step_provider.dart';
import 'provider/user_provider.dart';
import 'screen/find_password_screen.dart';
import 'screen/health_screen.dart';
import 'screen/home_screen.dart';
import 'screen/login/signup_screen.dart';
import 'screen/map/map_screen.dart';
import 'screen/nickname_change_screen.dart';
import 'screen/weather_screen.dart';
import 'provider/weather_provider.dart';
import 'provider/step_provider.dart';
import 'provider/map_provider.dart';
import 'screen/change_password_screen.dart';
import 'screen/login/signIn_screen.dart';
import 'screen/customer_center_screen.dart';
import 'screen/setting_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(
          create: (context) => WeatherProvider()..loadWeather(),
          child: WeatherScreen(),
        ),
        ChangeNotifierProvider(create: (context) => StepProvider()),
        ChangeNotifierProvider(create: (context) => MapProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(fontFamily: 'Freesentation'),
      // home: const AuthWrapper(),
      home: AuthWrapper(),
      initialRoute: 'home',
      routes: {
        'recommendCourse': (context) => const RecommendedCourseScreen(),
        'signUp': (context) => const SignUpScreen(),
        'signIn': (context) => const SigninScreen(),
        'home': (context) => const HomeScreen(),
        'map': (context) => const MapScreen(),
        'findPassword': (context) => const FindPasswordScreen(),
        'setting': (context) => const SettingScreen(),
        'map': (context) => const MapScreen(),
        'changeNickname': (context) => const NicknameChangeScreen(),
        'changePassword': (context) => const ChangePasswordScreen(),
        'customerCenter': (context) => const CustomerCenterScreen(),
      },
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
          return const HomeScreen(); // 로그인된 경우
        } else {
          return const SigninScreen(); // 로그인되지 않은 경우
        }
      },
    );
  }
}
