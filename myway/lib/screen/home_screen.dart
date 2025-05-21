import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/provider/user_provider.dart';
import 'package:myway/screen/mycourse_screen.dart';
import 'package:myway/screen/weather_screen.dart';
import 'package:provider/provider.dart';

import '../provider/weather_provider.dart';
import 'map/map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 80.0, left: 20, right: 20),
            child: Row(
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
                SizedBox(width: 20),
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
                    spacing: 2,
                    children: [
                      SvgPicture.asset(
                        weatherProvider.weatherIconPath,
                        height: 30,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weatherProvider.weatherStatus,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: GREEN_SUCCESS_TEXT_50,
                            ),
                          ),
                          Text(
                            '${weatherProvider.temperature}°',
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
                Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'setting');
                  },
                  icon: Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
          // username님의 코스
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 20, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        text: ' 님의 코스',
                        style: TextStyle(
                          color: GRAYSCALE_LABEL_800,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const MycourseScreen();
                        },
                      ),
                    );
                  },
                  child: Text(
                    '더보기 +',
                    style: TextStyle(
                      color: GRAYSCALE_LABEL_600,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
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
                      child: Column(
                        children: [
                          Container(
                            width: 114,
                            height: 114,
                            decoration: BoxDecoration(
                              color: Color(0xffe8f2f5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Text(
                            '추천 경로',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Container(
                            width: 114,
                            height: 114,
                            decoration: BoxDecoration(
                              color: Color(0xffeaf7eb),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Text(
                            '공원 찾기',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Column(
                        children: [
                          Container(
                            width: 114,
                            height: 114,
                            decoration: BoxDecoration(
                              color: Color(0xfffef3f3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Text(
                            '나의 기록',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'Pretendard',
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
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
