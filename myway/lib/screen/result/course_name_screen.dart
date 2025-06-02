import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/provider/park_data_provider.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/result/tracking_result_screen.dart';
import 'package:provider/provider.dart';

class CourseNameScreen extends StatefulWidget {
  final StepModel stepModel;
  final Uint8List courseImage;
  const CourseNameScreen({
    super.key,
    required this.courseImage,
    required this.stepModel,
  });

  @override
  State<CourseNameScreen> createState() => _CourseNameScreenState();
}

class _CourseNameScreenState extends State<CourseNameScreen> {
  final TextEditingController courseNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final repaintBoundary = GlobalKey();
  late Uint8List imageBytes;

  // 추천 코스 관련 변수
  ParkCourseInfo? selectedRecommendedCourse;
  List<ParkCourseInfo> nearbyRecommendedCourses2km = [];
  bool isLoadingRecommendedCourses = true;

  @override
  void initState() {
    super.initState();

    // 컴포넌트가 초기화될 때 ParkDataProvider의 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parkDataProvider = Provider.of<ParkDataProvider>(
        context,
        listen: false,
      );
      parkDataProvider.fetchAllDataIfNeeded().then((_) {
        if (mounted) {
          setState(() {
            nearbyRecommendedCourses2km =
                parkDataProvider.nearbyRecommendedCourses2km;
            isLoadingRecommendedCourses = false;
          });
        }
      });
    });
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
        leading: IconButton(
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
            stepProvider.resetTracking();
          },
          icon: Icon(Icons.close_rounded, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
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
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.only(bottom: 25),
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
                child: Column(
                  children: [
                    RepaintBoundary(
                      key: repaintBoundary,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.memory(
                          widget.courseImage,
                          gaplessPlayback: true,
                          width: double.infinity,
                          height: 364,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => const Text('이미지를 불러올 수 없습니다'),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '제목',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                stepProvider.formattedStopTime,
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: stepProvider.courseName,
                            cursorColor: ORANGE_PRIMARY_500,
                            decoration: InputDecoration(
                              labelText: '코스 이름을 설정해주세요',
                              labelStyle: TextStyle(color: Colors.grey),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: ORANGE_PRIMARY_500,
                                ),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: ORANGE_PRIMARY_500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          // 추천 코스 드롭다운 섹션
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '추천 코스 연결',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  isLoadingRecommendedCourses
                                      ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: ORANGE_PRIMARY_500,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : SizedBox.shrink(),
                                ],
                              ),
                              _buildRecommendedCourseDropdown(),
                            ],
                          ),

                          // SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.stepModel.distance,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'km',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '거리',
                                style: TextStyle(
                                  color: GRAYSCALE_LABEL_500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.stepModel.duration,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '시간',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.stepModel.steps}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '걸음수',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_500,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
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

                            // Firebase에 저장할 데이터 준비 (단순하게 StepModel에서 직접 가져오기)
                            Map<String, dynamic> resultData = result.toJson();

                            try {
                              await _firestore
                                  .collection('trackingResult')
                                  .doc(currentUser.uid)
                                  .set({
                                    'TrackingResult': FieldValue.arrayUnion([
                                      resultData,
                                    ]),
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
                            : GRAYSCALE_LABEL_200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '저장 및 공유',
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
        ),
      ),
    );
  }

  // 추천 코스 드롭다운 위젯
  Widget _buildRecommendedCourseDropdown() {
    if (isLoadingRecommendedCourses) {
      return Row(
        children: [
          Text(
            '추천 코스 불러오는 중...',
            style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
          ),
          Icon(Icons.arrow_drop_down, color: GRAYSCALE_LABEL_400),
        ],
      );
    }

    if (nearbyRecommendedCourses2km.isEmpty) {
      return Row(
        children: [
          Icon(Icons.location_off, size: 16, color: GRAYSCALE_LABEL_600),
          SizedBox(width: 8),
          Text(
            '반경 2km 이내 추천 코스가 없습니다',
            style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
          ),
        ],
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<ParkCourseInfo>(
        value: selectedRecommendedCourse,
        dropdownColor: BACKGROUND_COLOR,
        isExpanded: true,
        icon: SizedBox.shrink(),
        hint: Text(
          '반경 2km 이내 추천코스 선택',
          style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
        ),
        selectedItemBuilder: (BuildContext context) {
          return nearbyRecommendedCourses2km.map<Widget>((
            ParkCourseInfo course,
          ) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  course.parkName ?? '공원 정보 없음',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: GRAYSCALE_LABEL_700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(Icons.arrow_drop_down, color: ORANGE_PRIMARY_500),
              ],
            );
          }).toList();
        },
        items:
            nearbyRecommendedCourses2km.map((ParkCourseInfo course) {
              return DropdownMenuItem<ParkCourseInfo>(
                value: course,
                child: Text(
                  course.parkName ?? '공원 정보 없음',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: GRAYSCALE_LABEL_700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
        onChanged: (ParkCourseInfo? newValue) {
          setState(() {
            selectedRecommendedCourse = newValue;

            // stepProvider에 공원명 설정
            final stepProvider = Provider.of<StepProvider>(
              context,
              listen: false,
            );
            stepProvider.setParkName(newValue?.parkName);

            // 코스 이름이 비어있으면 선택한 추천 코스 이름으로 자동설정
            if (newValue != null &&
                (stepProvider.courseName.text.isEmpty ||
                    stepProvider.courseName.text == '나의 코스')) {
              stepProvider.courseName.text = newValue.title;
            }
          });
        },
      ),
    );
  }
}
