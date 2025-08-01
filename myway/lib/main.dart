import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myway/bottomTabBar/bottom_tab_bar.dart';
import 'package:myway/bottomTabBar/custom_bottom_tab_bar.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/firebase_options.dart';
import 'package:myway/provider/profile_provider.dart';
import 'package:myway/screen/notice/notice_list_screen.dart';
import 'package:myway/screen/notice/notice_screen.dart';
import 'package:myway/screen/setting/privacy_policy_screen.dart';
import 'package:myway/screen/setting/setting_screen.dart';
import 'package:myway/screen/setting/terms_of_service_screen.dart';
import 'package:myway/screen/home/park_recommend_screen.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'provider/activity_log_provider.dart';
import 'provider/map_provider.dart';
import 'provider/step_provider.dart';
import 'provider/user_provider.dart';
import 'provider/weather_provider.dart';
import 'provider/park_data_provider.dart';

import 'screen/setting/find_password_screen.dart';
import 'screen/home/home_screen.dart';
import 'screen/login/signup_screen.dart';
import 'screen/map/map_screen.dart';
import 'screen/setting/nickname_change_screen.dart';
import 'screen/setting/change_password_screen.dart';
import 'screen/login/signIn_screen.dart';
import 'screen/setting/customer_center_screen.dart';
import 'temp/park_data_provider_test.dart';
import 'temp/test_drawer.dart';
import 'temp/test_map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 방향 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
        ChangeNotifierProvider(create: (context) => ParkDataProvider()),
        ChangeNotifierProvider(create: (context) => ParkDataProviderTest()),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
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
          'parkList': (context) => const ParkRecommendScreen(),
          'policy': (context) => const PrivacyPolicyScreen(),
          'terms': (context) => const TermsOfServiceScreen(),
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
        print('AuthWrapper - ConnectionState: ${snapshot.connectionState}');
        print('AuthWrapper - HasData: ${snapshot.hasData}');
        print('AuthWrapper - HasError: ${snapshot.hasError}');
        if (snapshot.hasData) {
          print('AuthWrapper - Current User: ${snapshot.data?.uid}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: ORANGE_PRIMARY_500),
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text('에러가 발생하였습니다.'));
        } else if (snapshot.hasData) {
          // return const BottomTabBar();
          return const CustomBottomTabBar();
        } else {
          return const SigninScreen();
        }
      },
    );
  }
}
