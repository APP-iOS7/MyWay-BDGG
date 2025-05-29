// home_screen.dart

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:myway/screen/park_list_screen.dart'; // 경로 확인 및 수정
import 'package:provider/provider.dart';

import '/const/colors.dart';
import '/screen/mycourse_screen.dart';
import 'weather_screen.dart';
import '/provider/weather_provider.dart';
import '../result/activity_log_screen.dart';

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
    try {
      final ref = FirebaseStorage.instance.ref().child('walk_result');
      final result = await ref.listAll();
      final urls = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );
      if (mounted) {
        setState(() {
          imageUrls = urls;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                  const Text(
                    '마이웨이',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeatherScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          weatherProvider.weatherIconPath,
                          height: 30,
                        ),
                        const SizedBox(width: 5),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weatherProvider.weatherStatus,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: GREEN_SUCCESS_TEXT_50,
                              ),
                            ),
                            Text(
                              '${weatherProvider.temperature}°',
                              style: const TextStyle(
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
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, 'setting');
                    },
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: GRAYSCALE_LABEL_600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 0.0, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: user?.displayName ?? "사용자",
                      style: const TextStyle(
                        color: BLUE_SECONDARY_600,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      children: const <TextSpan>[
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
                          builder: (context) => const MycourseScreen(),
                        ),
                      );
                    },
                    child: const Text(
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
                  return const SizedBox(
                    height: 430,
                    child: Center(child: Text('에러가 발생했습니다.')),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 430,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    !snapshot.data!.exists) {
                  return const SizedBox(
                    height: 430,
                    child: Center(child: Text('저장된 기록이 없습니다.')),
                  );
                }
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data == null ||
                    data['TrackingResult'] == null ||
                    data['TrackingResult'] is! List) {
                  return const SizedBox(
                    height: 430,
                    child: Center(child: Text('기록 데이터 형식이 올바르지 않습니다.')),
                  );
                }
                final trackingResult = data['TrackingResult'] as List<dynamic>;
                if (trackingResult.isEmpty) {
                  return const SizedBox(
                    height: 430,
                    child: Center(child: Text('저장된 기록이 없습니다.')),
                  );
                }
                trackingResult.sort((a, b) {
                  try {
                    final aTime = DateTime.parse(a['종료시간']);
                    final bTime = DateTime.parse(b['종료시간']);
                    return bTime.compareTo(aTime);
                  } catch (e) {
                    return 0;
                  }
                });
                final limitedResults =
                    trackingResult.length > 5
                        ? trackingResult.sublist(0, 5)
                        : trackingResult;
                return SizedBox(
                  height: 480,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      scrollDirection: Axis.horizontal,
                      height: 460,
                      enableInfiniteScroll: limitedResults.length > 1,
                      padEnds: true,
                      viewportFraction: 0.8,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.1,
                      autoPlay: false,
                    ),
                    items:
                        limitedResults.map((result) {
                          if (result is! Map<String, dynamic>) {
                            return const SizedBox.shrink();
                          }
                          final imageUrl = result['이미지 Url']?.toString() ?? '';
                          return Builder(
                            builder: (BuildContext context) {
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: GRAYSCALE_LABEL_300,
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: Offset(1, 1),
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
                                              imageUrl,
                                              width: double.infinity,
                                              height: 262,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: double.infinity,
                                                    height: 262,
                                                    color: Colors.grey[200],
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                    ),
                                                  ),
                                            )
                                            : Container(
                                              width: double.infinity,
                                              height: 262,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                              ),
                                            ),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.all(10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${result['종료시간'] ?? '시간 정보 없음'}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${result['코스이름'] ?? '코스 이름 없음'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '${result['거리'] ?? '0.0'}',
                                                      style: const TextStyle(
                                                        fontSize: 26,
                                                      ),
                                                    ),
                                                    const Text(
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
                                                const Text(
                                                  '거리',
                                                  style: TextStyle(
                                                    color: GRAYSCALE_LABEL_500,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${result['소요시간'] ?? '00:00'}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        const Text(
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
                                                    const SizedBox(width: 20),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '${result['걸음수'] ?? '0'}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        const Text(
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
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const ParkListScreen(initialTabIndex: 1),
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
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 205, 203, 203),
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
                            const SizedBox(height: 10),
                            const Text(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const ParkListScreen(initialTabIndex: 0),
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
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 205, 203, 203),
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
                            const SizedBox(height: 10),
                            const Text(
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
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 205, 203, 203),
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
                            const SizedBox(height: 10),
                            const Text(
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
