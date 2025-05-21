import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/theme/colors.dart';

class TrackingHistoryScreen extends StatefulWidget {
  const TrackingHistoryScreen({super.key});

  @override
  State<TrackingHistoryScreen> createState() => _TrackingHistoryScreenState();
}

class _TrackingHistoryScreenState extends State<TrackingHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
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
            height: 1000,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 500,
                  scrollDirection: Axis.horizontal,
                  enableInfiniteScroll: true,
                  padEnds: true,
                  viewportFraction: 0.8, // 화면에 보이는 아이템의 비율
                  enlargeCenterPage: true, // 가운데 아이템 확대
                  enlargeFactor: 0.2,
                  autoPlay: false,
                ),
                items:
                    trackingResult.map((result) {
                      return Builder(
                        builder: (BuildContext context) {
                          final imageUrl = result['이미지 Url']?.toString() ?? '';
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    imageUrl.isNotEmpty
                                        ? Image.network(
                                          result['이미지 Url'],
                                          width: double.infinity,
                                          height: 282,
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
                                        padding: const EdgeInsets.all(20),
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
                                                    fontSize: 32,
                                                  ),
                                                ),
                                                Text(
                                                  'km',
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
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
                                                      CrossAxisAlignment.start,
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
                                                      CrossAxisAlignment.start,
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
            ),
          );
        },
      ),
    );
  }
}
