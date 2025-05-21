import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '/const/colors.dart';
import '/screen/mycourse_screen.dart';
import '/screen/weather_screen.dart';
import '/provider/weather_provider.dart';
import 'result/activity_log_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  List<String> imageUrls = [];
  bool isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  Future<void> fetchImages() async {
    final ref = FirebaseStorage.instance.ref().child('walk_result');
    final result = await ref.listAll();

    final urls = await Future.wait(
      result.items.map((item) => item.getDownloadURL()),
    );

    setState(() {
      imageUrls = urls;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final weatherProvider = Provider.of<WeatherProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
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
                      spacing: 5,
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
                    icon: Icon(
                      Icons.settings_outlined,
                      color: GRAYSCALE_LABEL_600,
                    ),
                  ),
                ],
              ),
            ),
            // username님의 코스
            Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: user?.displayName,
                      style: TextStyle(
                        color: BLUE_SECONDARY_600,
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
                        color: GRAYSCALE_LABEL_900,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore
                      .collection('trackingResult')
                      .doc(_auth.currentUser?.uid)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러가 발생했습니다.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(child: Text('저장된 기록이 없습니다.'));
                }

                // TrackingResult 배열 가져오기
                final data = snapshot.data!.data() as Map<String, dynamic>;
                final trackingResult = data['TrackingResult'] as List<dynamic>;

                // 종료시간을 기준으로 최신순 정렬
                trackingResult.sort((a, b) {
                  final aTime = DateTime.parse(a['종료시간']);
                  final bTime = DateTime.parse(b['종료시간']);
                  return bTime.compareTo(aTime); // 내림차순 정렬 (최신순)
                });

                return SizedBox(
                  height: 490,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      scrollDirection: Axis.horizontal,
                      height: 450,
                      enableInfiniteScroll: true,
                      padEnds: true,
                      viewportFraction: 0.8, // 화면에 보이는 아이템의 비율
                      enlargeCenterPage: true, // 가운데 아이템 확대
                      enlargeFactor: 0.2,
                      autoPlay: false,
                      // onPageChanged: (index, reason) {
                      //   setState(() {
                      //     _currentIndex = index;
                      //   });
                      // },
                    ),
                    items:
                        trackingResult.map((result) {
                          return Builder(
                            builder: (BuildContext context) {
                              final imageUrl =
                                  result['이미지 Url']?.toString() ?? '';
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromARGB(
                                          255,
                                          211,
                                          209,
                                          209,
                                        ),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        imageUrl.isNotEmpty
                                            ? Image.network(
                                              result['이미지 Url'],
                                              width: double.infinity,
                                              height: 262,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              width: double.infinity,
                                              height: 282,
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.image_not_supported,
                                              ),
                                            ),
                                        SizedBox(
                                          width: double.infinity,
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${result['종료시간']}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${result['코스이름']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${result['거리']}',
                                                      style: TextStyle(
                                                        fontSize: 26,
                                                      ),
                                                    ),
                                                    Text(
                                                      'km',
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  '거리',
                                                  style: TextStyle(
                                                    color: GRAYSCALE_LABEL_500,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${result['소요시간']}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        Text(
                                                          '시간',
                                                          style: TextStyle(
                                                            color:
                                                                GRAYSCALE_LABEL_500,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(width: 20),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${result['걸음수']}',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                        Text(
                                                          '걸음수',
                                                          style: TextStyle(
                                                            color:
                                                                GRAYSCALE_LABEL_500,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                  ),
                );
              },
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, 'map');
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
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
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
                                color: GRAYSCALE_LABEL_50,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      205,
                                      203,
                                      203,
                                    ),
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: SvgPicture.asset(
                                  'assets/images/location.svg',
                                  width: 10,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '추천 경로',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
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
                                color: GRAYSCALE_LABEL_50,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      205,
                                      203,
                                      203,
                                    ),
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: SvgPicture.asset(
                                  'assets/images/mdi_tree.svg',
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '공원 찾기',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
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
                              builder: (context) => ActivityLogScreen(),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 114,
                              height: 114,
                              decoration: BoxDecoration(
                                color: GRAYSCALE_LABEL_50,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      205,
                                      203,
                                      203,
                                    ),
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: SvgPicture.asset(
                                  'assets/images/walk.svg',
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '나의 기록',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
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
          ],
        ),
      ),
    );
  }
}
