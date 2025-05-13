import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/provider/user_provider.dart';
import 'package:myway/screen/weather_screen.dart';
import 'package:provider/provider.dart';

import 'map/map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 70),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '마이웨이',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return WeatherScreen();
                        },
                      ),
                    );
                  },
                  child: Row(
                    spacing: 10,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/weather_sunny.svg',
                        height: 40,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '좋음',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: GREEN_SUCCESS_TEXT_50,
                            ),
                          ),
                          Text(
                            '18.3',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: BLACK,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 임시 로그아웃 버튼
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return IconButton(
                      onPressed: () {
                        userProvider.signOut();
                        Navigator.pushReplacementNamed(context, 'signIn');
                      },
                      icon: Icon(Icons.output_rounded),
                    );
                  },
                ),
              ],
            ),
            // username님의 코스
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  Text.rich(
                    TextSpan(
                      text: user?.displayName,
                      style: TextStyle(
                        color: GRAYSCALE_LABEL_700,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: '님의 코스',
                          style: TextStyle(
                            color: GRAYSCALE_LABEL_600,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [Card(color: Colors.black, child: Text(''))],
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const MapScreen();
                            },
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shadowColor: Colors.transparent,
                        backgroundColor: ORANGE_PRIMARY_600,
                        foregroundColor: WHITE,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '산책 시작',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: WHITE,
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 114,
                        height: 114,
                        decoration: BoxDecoration(
                          color: Color(0xffe8f2f5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 114,
                        height: 114,
                        decoration: BoxDecoration(
                          color: Color(0xffeaf7eb),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: 114,
                        height: 114,
                        decoration: BoxDecoration(
                          color: Color(0xfffef3f3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '추천 경로',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '공원 찾기',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          '나의 기록',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
