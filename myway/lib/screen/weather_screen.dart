import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back),
        title: Text('금천구'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            SvgPicture.asset('assets/icons/sun2.svg', height: 300),
            Text(
              '18°',
              style: TextStyle(fontSize: 75, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              '맑음',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xfffbf4ec),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '오늘의 날씨는 맑고 기온은 18도입니다.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 210,
                    height: 114,
                    decoration: BoxDecoration(
                      color: Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 12,
                          child: Text("습도", style: TextStyle(fontSize: 16)),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 12,
                          child: Row(
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                size: 20,
                                color: Color(0xff93C5D8),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "보통",
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Color(0xff93C5D8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  width: 210,
                  height: 114,
                  decoration: BoxDecoration(
                    color: Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 12,
                        child: Text("강수확률", style: TextStyle(fontSize: 16)),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: Row(
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 20,
                              color: Color(0xff164F6D),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "높음",
                              style: TextStyle(
                                fontSize: 25,
                                color: Color(0xff164F6D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Container(
                    width: 210,
                    height: 114,
                    decoration: BoxDecoration(
                      color: Color(0xFFF9FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 12,
                          child: Text("미세먼지", style: TextStyle(fontSize: 16)),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 12,
                          child: Row(
                            children: [
                              Icon(
                                Icons.sentiment_dissatisfied,
                                size: 20,
                                color: Color(0xffFFb327),
                              ),
                              SizedBox(width: 5),
                              Text(
                                "나쁨",
                                style: TextStyle(
                                  fontSize: 25,
                                  color: Color(0xffFFb327),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Container(
                  width: 210,
                  height: 114,
                  decoration: BoxDecoration(
                    color: Color(0xFFF9FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 12,
                        child: Text("초미세먼지", style: TextStyle(fontSize: 16)),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 12,
                        child: Row(
                          children: [
                            Icon(
                              Icons.sentiment_dissatisfied_rounded,
                              size: 20,
                              color: Color(0xffF65B43),
                            ),
                            SizedBox(width: 5),
                            Text(
                              "매우 나쁨",
                              style: TextStyle(
                                fontSize: 25,
                                color: Color(0xffF65B43),
                              ),
                            ),
                          ],
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
