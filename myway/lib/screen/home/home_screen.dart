import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import '../../provider/user_provider.dart';
import '../../provider/park_data_provider.dart';
import '/const/colors.dart';
import 'weather_screen.dart';
import '/provider/weather_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> imageUrls = [];
  bool isLoading = true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    context.read<UserProvider>().loadNickname();
    fetchImages();
    _initializeParkData();
  }

  Future<void> _initializeParkData() async {
    try {
      final parkProvider = context.read<ParkDataProvider>();

      print('홈스크린 CSV 초기화 시작');
      print('현재 공원 데이터 개수: ${parkProvider.allParks.length}');
      print('CSV 로드 상태: ${parkProvider.csvLoaded}');

      // BottomTabBar에서 이미 로드했을 수 있으므로 상태만 확인
      if (parkProvider.allParks.isNotEmpty) {
        print('CSV 데이터가 이미 로드되어 있음: ${parkProvider.allParks.length}개');
      } else {
        print('CSV 데이터가 아직 로드되지 않음 - BottomTabBar에서 처리 예정');
      }
    } catch (e) {
      print('홈스크린 CSV 로드 실패: $e');
      // 에러가 발생해도 앱은 계속 실행
    }
  }

  Future<void> fetchImages() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final userProvider = context.watch<UserProvider>();
    final nickname =
        userProvider.nickname ?? userProvider.currentUser?.displayName ?? '사용자';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nickname,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Transform.translate(
                    offset: Offset(0, 10),
                    child: GestureDetector(
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
                  ),
                ],
              ),
            ),
            // username님의 코스
            Padding(
              padding: const EdgeInsets.only(
                top: 0.0,
                left: 40,
                right: 40,
                bottom: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '나의 산책 코스',
                    style: TextStyle(color: BLACK, fontSize: 17),
                  ),
                ],
              ),
            ),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  _firestore
                      .collection('trackingResult')
                      .doc(_auth.currentUser?.uid)
                      .snapshots()
                      .distinct(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 430,
                    child: Center(child: Text('에러가 발생했습니다.')),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 430,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ORANGE_PRIMARY_500,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return SizedBox(
                    height: 430,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '저장된 기록이 없습니다.',
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_800,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '산책을 시작해서 나만의 코스를 만들어보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // TrackingResult 배열 가져오기
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final trackingData = data['TrackingResult'];

                final trackingResult =
                    (trackingData != null && trackingData is List)
                        ? List<Map<String, dynamic>>.from(trackingData)
                        : <Map<String, dynamic>>[];

                if (trackingResult.isEmpty) {
                  return SizedBox(
                    height: 430,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_walk),
                          const SizedBox(height: 10),
                          const SizedBox(
                            width: double.infinity,
                            child: Text(
                              '저장된 기록이 없습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: GRAYSCALE_LABEL_800,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const Text(
                            '산책을 시작해서 나만의 코스를 만들어보세요!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: GRAYSCALE_LABEL_600,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // 종료시간을 기준으로 최신순 정렬
                trackingResult.sort((a, b) {
                  final aTime = DateTime.parse(a['종료시간']);
                  final bTime = DateTime.parse(b['종료시간']);
                  return bTime.compareTo(aTime);
                });

                // 필드내에서 5개로 제한
                final limitedResults =
                    trackingResult.length > 5
                        ? trackingResult.sublist(0, 5)
                        : trackingResult;

                return SizedBox(
                  height: 500,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      scrollDirection: Axis.horizontal,
                      height: 480,
                      enableInfiniteScroll: trackingResult.length == 3,
                      padEnds: true,
                      viewportFraction: 0.8, // 화면에 보이는 아이템의 비율
                      enlargeCenterPage: true, // 가운데 아이템 확대
                      enlargeFactor: 0.1,
                      autoPlay: false,
                    ),
                    items:
                        limitedResults.map((result) {
                          return Builder(
                            builder: (BuildContext context) {
                              final imageUrl =
                                  result['이미지 Url']?.toString() ?? '';
                              return Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                margin: EdgeInsets.symmetric(horizontal: 10),
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
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
                                                result['이미지 Url'],
                                                width: double.infinity,
                                                height: 285,
                                                fit: BoxFit.cover,
                                              )
                                              : Container(
                                                width: double.infinity,
                                                height: 290,
                                                color: GRAYSCALE_LABEL_200,
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
                                                    '${result['코스이름']}',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${result['종료시간']}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color:
                                                          GRAYSCALE_LABEL_700,
                                                    ),
                                                  ),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    result['공원명'] ?? '공원 미지정',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                                            '${result['거리']}',
                                                            style: TextStyle(
                                                              fontSize: 23,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  GRAYSCALE_LABEL_900,
                                                            ),
                                                          ),
                                                          Text(
                                                            '거리(km)',
                                                            style: TextStyle(
                                                              color:
                                                                  GRAYSCALE_LABEL_500,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(width: 20),
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
                                                                  fontSize: 23,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      GRAYSCALE_LABEL_900,
                                                                ),
                                                              ),
                                                              Text(
                                                                '시간',
                                                                style: TextStyle(
                                                                  color:
                                                                      GRAYSCALE_LABEL_500,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
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
                                                                  fontSize: 23,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      GRAYSCALE_LABEL_900,
                                                                ),
                                                              ),
                                                              Text(
                                                                '걸음수',
                                                                style: TextStyle(
                                                                  color:
                                                                      GRAYSCALE_LABEL_500,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
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
                                ),
                              );
                            },
                          );
                        }).toList(),
                  ),
                );
              },
            ),
            Spacer(),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 45,
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
                        backgroundColor: ORANGE_PRIMARY_500,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
