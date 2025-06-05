import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myway/const/colors.dart';
import 'package:myway/model/park_course_info.dart';
import 'package:myway/model/step_model.dart';
import 'package:myway/provider/park_data_provider.dart';
import 'package:myway/provider/step_provider.dart';
import 'package:myway/screen/result/tracking_result_screen.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import '../../provider/map_provider.dart';

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
    final parkDataProvider = Provider.of<ParkDataProvider>(
      context,
      listen: false,
    );

    // 이미 로드된 데이터 사용 및 중복 제거
    setState(() {
      final originalList = parkDataProvider.nearbyRecommendedCourses2km;
      print('원본 리스트 길이: ${originalList.length}');

      // 공원명 기준으로 중복 제거 (각 공원의 중간 거리 코스만 선택)
      final uniqueCourses = <String, ParkCourseInfo>{};
      for (final course in originalList) {
        final parkName = course.parkName ?? 'unknown';

        // 같은 공원의 코스가 없거나, 현재 코스가 1.0km 코스인 경우 선택
        if (!uniqueCourses.containsKey(parkName) ||
            course.details.distance == 1.0) {
          uniqueCourses[parkName] = course;
        }
      }

      nearbyRecommendedCourses2km = uniqueCourses.values.toList();
      print('중복 제거 후 리스트 길이: ${nearbyRecommendedCourses2km.length}');

      // 디버깅: 각 아이템 출력
      for (int i = 0; i < nearbyRecommendedCourses2km.length; i++) {
        final course = nearbyRecommendedCourses2km[i];
        print('$i: 공원명=${course.parkName}, 거리=${course.details.distance}km');
      }

      isLoadingRecommendedCourses = false;
    });
  }

  Future<String?> imageUpload() async {
    try {
      // Storage업로드
      final fileName =
          'walk_result_map${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child('walk_result/$fileName');

      final uploadTask = await ref.putData(widget.courseImage);

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
    final mapProvider = Provider.of<MapProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
            stepProvider.resetTracking();
            mapProvider.resetState();
          },
          icon: Icon(Icons.close_rounded, color: GRAYSCALE_LABEL_950),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          '산책 완료',
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(top: 8),
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
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 15,
                              child: Image.memory(
                                widget.courseImage,
                                gaplessPlayback: true,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        const Text('이미지를 불러올 수 없습니다'),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(20),
                                  ],
                                  controller: stepProvider.courseName,
                                  cursorColor: ORANGE_PRIMARY_500,
                                  decoration: InputDecoration(
                                    labelText: '코스 이름',
                                    labelStyle: TextStyle(
                                      color: GRAYSCALE_LABEL_600,
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: GRAYSCALE_LABEL_400,
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
                                Text(
                                  stepProvider.formattedStopTime,
                                  style: TextStyle(
                                    color: GRAYSCALE_LABEL_800,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                // SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (isLoadingRecommendedCourses)
                                          SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: ORANGE_PRIMARY_500,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      ],
                                    ),
                                    _buildRecommendedCourseDropdown(),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildInfoColumn(
                                      '${widget.stepModel.distance}',
                                      '거리(km)',
                                    ),

                                    _buildInfoColumn(
                                      widget.stepModel.duration,
                                      '시간',
                                    ),
                                    _buildInfoColumn(
                                      '${widget.stepModel.steps}',
                                      '걸음수',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap:
                stepProvider.isCourseNameValid
                    ? () async {
                      User? currentUser = _auth.currentUser;
                      if (currentUser == null) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.error,
                          style: ToastificationStyle.flat,
                          alignment: Alignment.bottomCenter,
                          autoCloseDuration: Duration(seconds: 2),
                          title: Text('코스이름을 지정하기 위해선 로그인이 필요합니다.'),
                        );
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          'signIn',
                          (route) => false,
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black.withValues(alpha: 0.5),
                        builder: (context) {
                          return Dialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 40,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  CircularProgressIndicator(
                                    color: ORANGE_PRIMARY_500,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    '산책 데이터를 저장중입니다...',
                                    style: TextStyle(
                                      color: GRAYSCALE_LABEL_950,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      try {
                        final imageUrl = await imageUpload();

                        final result = stepProvider.createStepModel(
                          imageUrl: imageUrl ?? '',
                        );
                        // Firebase에 저장할 데이터 준비 (단순하게 StepModel에서 직접 가져오기)
                        Map<String, dynamic> resultData = result.toJson();
                        await _firestore
                            .collection('trackingResult')
                            .doc(currentUser.uid)
                            .set({
                              'TrackingResult': FieldValue.arrayUnion([
                                resultData,
                              ]),
                            }, SetOptions(merge: true));

                        print('산책결과가 FireStore에 저장되었습니다.');

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TrackingResultScreen(
                                    result: result,
                                    courseName: result.courseName,
                                    courseImage: widget.courseImage,
                                  ),
                            ),
                          );
                        }

                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          style: ToastificationStyle.flat,
                          autoCloseDuration: Duration(seconds: 2),
                          alignment: Alignment.bottomCenter,
                          title: Text('산책기록이 저장되었습니다.'),
                        );
                        courseNameController.text = '';
                      } catch (e) {
                        print('Firestore 저장 오류: $e');

                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }

                        toastification.show(
                          context: context,
                          type: ToastificationType.error,
                          style: ToastificationStyle.flat,
                          autoCloseDuration: Duration(seconds: 2),
                          alignment: Alignment.bottomCenter,
                          title: Text('산책기록이 저장 중 오류가 발생했습니다.'),
                        );
                      }
                    }
                    : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                height: 56,
                alignment: Alignment.center,
                width: double.infinity,
                decoration: BoxDecoration(
                  color:
                      stepProvider.isCourseNameValid
                          ? ORANGE_PRIMARY_500
                          : GRAYSCALE_LABEL_300,
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
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  // 추천 코스 드롭다운 위젯 (커스텀 IconButton + AlertDialog)
  Widget _buildRecommendedCourseDropdown() {
    if (isLoadingRecommendedCourses) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              '추천 코스 불러오는 중...',
              style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: ORANGE_PRIMARY_500,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      );
    }

    if (nearbyRecommendedCourses2km.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.location_off, size: 16, color: GRAYSCALE_LABEL_600),
            SizedBox(width: 8),
            Text(
              '반경 2km 이내 추천 코스가 없습니다',
              style: TextStyle(color: GRAYSCALE_LABEL_600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => _showParkSelectionDialog(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              selectedRecommendedCourse?.parkName ?? '반경 2km 이내 추천코스 선택',
              style: TextStyle(
                color:
                    selectedRecommendedCourse != null
                        ? GRAYSCALE_LABEL_900
                        : GRAYSCALE_LABEL_600,
                fontSize: selectedRecommendedCourse != null ? 16 : 14,
                fontWeight:
                    selectedRecommendedCourse != null
                        ? FontWeight.w600
                        : FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => _showParkSelectionDialog(),
            icon: Icon(Icons.keyboard_arrow_down, color: GRAYSCALE_LABEL_600),
            padding: EdgeInsets.only(left: 4),
            constraints: BoxConstraints(minWidth: 24, minHeight: 24),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // 공원 선택 다이얼로그
  void _showParkSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: BACKGROUND_COLOR,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '공원 선택',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GRAYSCALE_LABEL_950,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: GRAYSCALE_LABEL_600),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: nearbyRecommendedCourses2km.length,
                    separatorBuilder:
                        (context, index) =>
                            Divider(color: GRAYSCALE_LABEL_300, height: 1),
                    itemBuilder: (context, index) {
                      final course = nearbyRecommendedCourses2km[index];
                      final isSelected = selectedRecommendedCourse == course;

                      // 각 코스에 해당하는 공원 정보 가져오기
                      final parkDataProvider = Provider.of<ParkDataProvider>(
                        context,
                        listen: false,
                      );
                      final parkInfo = parkDataProvider.allFetchedParks
                          .firstWhere((park) => park.id == course.parkId);
                      final courseAddress =
                          parkInfo.address.isNotEmpty
                              ? parkInfo.address
                              : '주소 정보 없음';

                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              selectedRecommendedCourse = course;

                              // stepProvider에 공원명 설정
                              final stepProvider = Provider.of<StepProvider>(
                                context,
                                listen: false,
                              );
                              stepProvider.setParkName(course.parkName);
                              stepProvider.setParkId(course.parkId);
                            });
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            alignment: Alignment.centerLeft,
                            backgroundColor:
                                isSelected
                                    ? ORANGE_PRIMARY_500.withAlpha(1)
                                    : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.parkName ?? '공원 정보 없음',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? ORANGE_PRIMARY_500
                                              : GRAYSCALE_LABEL_900,
                                    ),
                                  ),
                                  if (course.title.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        courseAddress,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: GRAYSCALE_LABEL_900,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: ORANGE_PRIMARY_500,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: GRAYSCALE_LABEL_950,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: GRAYSCALE_LABEL_500, fontSize: 16)),
      ],
    );
  }
}
