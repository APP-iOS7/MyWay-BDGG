import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/result/tracking_result_screen.dart';
import 'package:provider/provider.dart';

import '../../provider/map_provider.dart';

class CourseNameScreen extends StatefulWidget {
  final Uint8List courseImage;
  const CourseNameScreen({super.key, required this.courseImage});

  @override
  State<CourseNameScreen> createState() => _CourseNameScreenState();
}

class _CourseNameScreenState extends State<CourseNameScreen> {
  final TextEditingController courseNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final repaintBoundary = GlobalKey();
  late Uint8List imageBytes;

  @override
  void initState() {
    super.initState();
  }

  Future<String?> imageUpload() async {
    try {
      final boundary =
          repaintBoundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Storage업로드
      final fileName =
          'walk_result_map${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('walk_result/$fileName');

      final uploadTask = await ref.putData(pngBytes);

      // 업로드 완료 후 URL 얻기
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('업로드 및 저장 실패: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepProvider = Provider.of<StepProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          '산책 완료',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: Column(
            children: [
              RepaintBoundary(
                key: repaintBoundary,
                child: Image.memory(
                  widget.courseImage,
                  gaplessPlayback: true,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('이미지를 불러올 수 없습니다'),
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    stepProvider.formattedStopTime,
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  SizedBox(width: 20),
                  Text(
                    '중앙공원',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '제목',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: stepProvider.courseName,
                    cursorColor: ORANGE_PRIMARY_500,
                    decoration: InputDecoration(
                      labelText: '코스 이름을 설정해주세요',
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: GRAYSCALE_LABEL_400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: GRAYSCALE_LABEL_400),
                      ),
                    ),
                  ),
                  SizedBox(height: 150),
                  GestureDetector(
                    onTap:
                        stepProvider.isCourseNameValid
                            ? () async {
                              // 현재 인증된 사용자 확인
                              User? currentUser = _auth.currentUser;
                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '코스이름을 지정하기 위해선 로그인이 필요합니다.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  'signIn',
                                  (route) => false,
                                );
                                return;
                              }

                              // 이미지 업로드는 비동기로 처리
                              imageUpload().then((imageUrl) async {
                                final result = stepProvider.createStepModel(
                                  imageUrl: imageUrl ?? '',
                                );

                                try {
                                  await _firestore
                                      .collection('trackingResult')
                                      .doc(currentUser.uid)
                                      .set({
                                        'TrackingResult': FieldValue.arrayUnion(
                                          [result.toJson()],
                                        ),
                                      }, SetOptions(merge: true));
                                  print('산책결과가 FireStore에 저장되었습니다.');
                                } catch (firestoreError) {
                                  print('Firestore 저장 오류: $firestoreError');
                                }
                              });

                              // 먼저 다음 페이지로 이동
                              final result = stepProvider.createStepModel(
                                imageUrl: '',
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TrackingResultScreen(
                                        result: result,
                                        courseName: result.courseName,
                                      ),
                                ),
                              );
                            }
                            : null,
                    child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            stepProvider.isCourseNameValid
                                ? ORANGE_PRIMARY_500
                                : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '다음',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
