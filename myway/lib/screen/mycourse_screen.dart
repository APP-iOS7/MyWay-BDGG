import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myway/const/colors.dart';

class MycourseScreen extends StatefulWidget {
  const MycourseScreen({super.key});

  @override
  State<MycourseScreen> createState() => _MycourseScreenState();
}

class _MycourseScreenState extends State<MycourseScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '나의 코스',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Divider(height: 1, thickness: 1, color: GRAYSCALE_LABEL_300),
        ),
      ),
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

          return Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
              ),
              itemCount: trackingResult.length,
              itemBuilder: (context, index) {
                final result = trackingResult[index] as Map<String, dynamic>;
                final imageUrl = result['이미지 Url']?.toString() ?? '';
                return Card(
                  color: Colors.white,
                  child: Column(
                    children: [
                      imageUrl.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              result['이미지 Url'],
                              width: double.infinity,
                              height: 98,
                              fit: BoxFit.cover,
                            ),
                          )
                          : SizedBox(
                            width: double.infinity,
                            height: 98,
                            child: Icon(Icons.image_not_supported),
                          ),
                      SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${result['코스이름']}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '${result['거리']} km',
                                  style: TextStyle(
                                    color: GRAYSCALE_LABEL_500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '${result['소요시간']}',
                                  style: TextStyle(
                                    color: GRAYSCALE_LABEL_500,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
